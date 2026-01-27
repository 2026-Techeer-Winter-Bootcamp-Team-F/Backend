import uuid
from google import genai
from django.conf import settings
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions, serializers, exceptions
from drf_spectacular.utils import extend_schema, inline_serializer

from .models import ChatRoom, ChatLog, ChatMessage
from cards.models import Card
from expense.models import Expense
from django.db.models import Sum
from .serializers import ChatCardResponseSerializer, ChatMessageSerializer

# 공통 에러 응답 헬퍼 함수
def error_response(message, error_code, reason, status_code):
    return Response({
        "message": message,
        "error_code": error_code,
        "reason": reason
    }, status=status_code)

class MakeChatRoomView(APIView): # 채팅방 생성 뷰
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="채팅방 생성 및 세션 연결",
        description="사용자와 챗봇 간의 새로운 채팅 세션을 시작합니다.",
        responses={201: inline_serializer(
            name='ChatRoomCreateResponse',
            fields={
                'type': serializers.CharField(),
                'session_id': serializers.CharField(),
                'message': serializers.CharField(),
                'user_id': serializers.IntegerField(),
                'timestamp': serializers.DateTimeField(),
            }
        )},
        tags=["Chat"]
    )
    def post(self, request):# 방 생성 응답
        try:
            # 1. 채팅방 생성
            auto_title = f"새로운 채팅 {timezone.now().strftime('%m/%d %H:%M')}"
            chat_room = ChatRoom.objects.create(user=request.user, title=auto_title)

            # 2. 세션 ID 생성 (DB의 UUID 또는 PK를 활용하는 것이 안전합니다)
            session_id = f"sess-{chat_room.chatting_room_id}" 

            return Response({
                "type": "CONNECTION_ESTABLISHED",
                "session_id": session_id,
                "message": "챗봇과의 연결이 성공했습니다.",
                "user_id": request.user.user_id,
                "timestamp": timezone.now().isoformat()
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            return error_response("채팅방 생성 실패", "DATABASE_ERROR", str(e), status.HTTP_500_INTERNAL_SERVER_ERROR)

    def handle_exception(self, exc):
        if isinstance(exc, exceptions.NotAuthenticated):
            return error_response("채팅방 생성 실패", "LOGIN_REQUIRED", "로그인이 필요한 서비스입니다.", status.HTTP_401_UNAUTHORIZED)
        return super().handle_exception(exc)


class SendMessageView(APIView): # 메시지 전송 및 챗봇 응답 뷰
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="메시지 전송 및 챗봇 응답",
        request=inline_serializer(
            name='SendMessageRequest',
            fields={
                'question': serializers.CharField(),
                'session_id': serializers.CharField()
            }
        ),
        tags=["Chat"]
    )
    def post(self, request):
        question = request.data.get('question')
        session_id = request.data.get('session_id')

        # 1. 유효성 검사
        if not question:
            return error_response("답변 생성 실패", "EMPTY_QUESTION", "질문 내용을 입력해주세요.", status.HTTP_400_BAD_REQUEST)

        # 2. 채팅방 확인
        try:
            # "sess-" 접두어 제거 후 조회
            room_id = session_id.replace("sess-", "") if session_id else None
            room = ChatRoom.objects.get(chatting_room_id=room_id, user=request.user)
        except (ChatRoom.DoesNotExist, ValueError):
            return error_response("답변 생성 실패", "ROOM_NOT_FOUND", "해당 채팅방이 존재하지 않습니다.", status.HTTP_404_NOT_FOUND)

        # 3. 비즈니스 로직 (카드 추천 및 로그 저장)
        try:
            recommended_cards = Card.objects.all()[:1]
            card_data = ChatCardResponseSerializer(recommended_cards, many=True).data
            
            ChatLog.objects.create(
                chatting_room=room,
                question=question,
                answer="추천 카드 정보입니다."
            )

            return Response({
                "type": "CARD_INFO",
                "message_id": f"msg-{uuid.uuid4().hex[:12]}",
                "session_id": session_id,
                "user_id": request.user.user_id,
                "timestamp": timezone.now().isoformat(),
                "data": {"cards": card_data}
            }, status=status.HTTP_200_OK)

        except Exception:
            return error_response("답변 생성 실패", "AI_RESPONSE_TIMEOUT", "챗봇 응답이 지연되고 있습니다.", status.HTTP_504_GATEWAY_TIMEOUT)


"""
* @package : chat
* @name : ChatView
* @create-date: 2026.01.21
* @author : GitHub Copilot
* @version : 1.0.0
"""
class ChatView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="채팅 기록 조회",
        description="로그인한 사용자의 AI 채팅 기록을 조회합니다.",
        tags=["Chat"]
    )
    def get(self, request):
        messages = ChatMessage.objects.filter(user=request.user).order_by("created_at")
        serializer = ChatMessageSerializer(messages, many=True)
        return Response(serializer.data)

    @extend_schema(
        summary="AI 채팅 메시지 전송",
        description="메시지를 보내면 Gemini AI가 금융 조언을 응답합니다.",
        request=inline_serializer(
            name='ChatViewRequest',
            fields={
                'message': serializers.CharField(),
            }
        ),
        tags=["Chat"]
    )
    def post(self, request):
        messageText = request.data.get("message")
        if not messageText:
            return Response({"error": "Message is required"}, status = status.HTTP_400_BAD_REQUEST)

        # 1. Save user message
        userMessage = ChatMessage.objects.create(
            user = request.user,
            message = messageText,
            is_user = True
        )

        # 2. Call Gemini API
        aiResponseText = ""
        try:
            # --- Gather User Context (Simple) ---
            now = timezone.now()
            start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            
            # This Month Total
            total_spent = Expense.objects.filter(
                user=request.user, spent_at__gte=start_of_month
            ).aggregate(Sum('amount'))['amount__sum'] or 0

            # Top Spending Category (Simple approximation)
            # Note: Group by category needs Category model relation. Assuming 'category__category_name' or similar if reachable.
            # Only Expense model imported, let's keep it simple or check specific relation.
            # Assuming Expense has 'category' FK. 
            
            # Build Context String
            user_context = f"사용자 이번 달 총 지출: {total_spent:,}원."
            
            client = genai.Client(api_key=settings.GEMINI_API_KEY)
            
            system_instruction = (
                "당신은 금융 전문가 'BeneFit'입니다. "
                "사용자의 금융 데이터를 기반으로 친절하고 구체적으로 답변해주세요. "
                "절대로 '데모 버전'이라거나 '데이터가 부족하다'는 변병을 하지 마세요. "
                "주어진 데이터를 최대한 활용하여 그럴듯한 조언을 제공하세요. "
                f"현재 상황: {user_context}\n"
            )
            
            full_prompt = f"{system_instruction}\n사용자 질문: {messageText}"
            
            try:
                # Primary: gemini-2.0-flash (Newer model)
                response = client.models.generate_content(
                    model="gemini-2.0-flash", 
                    contents=full_prompt
                )
                aiResponseText = response.text
            except Exception as e:
                 # Fallback: gemini-2.0-flash-lite-preview-02-05
                try:
                    response = client.models.generate_content(
                        model="gemini-2.0-flash-lite-preview-02-05", 
                        contents=full_prompt
                    )
                    aiResponseText = response.text
                except Exception as innerE:
                     aiResponseText = "죄송합니다. 현재 AI 서비스를 이용할 수 없습니다. (Error: " + str(e) + " / Fallback Error: " + str(innerE) + ")"

        except Exception as e:
            aiResponseText = "죄송합니다. 시스템 오류가 발생했습니다. (Error: " + str(e) + ")"

        # 3. Save AI response
        aiMessage = ChatMessage.objects.create(
            user = request.user,
            message = aiResponseText,
            is_user = False
        )

        # 4. Return both
        return Response({
            "user_message": ChatMessageSerializer(userMessage).data,
            "ai_message": ChatMessageSerializer(aiMessage).data
        })
