from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from drf_spectacular.utils import extend_schema, OpenApiExample
from .models import User, UserCard
from cards.models import Card

class SignUpView(APIView): # 회원가입 뷰
    @extend_schema(
        summary="회원가입",
        description="테스트를 위해 비밀번호를 암호화하지 않고 저장합니다.",
        request={
            "application/json": {
                "type": "object",
                "properties": {
                    "phone": {"type": "string", "example": "01012345678"},
                    "password": {"type": "string", "example": "password123"},
                    "name": {"type": "string", "example": "테스터"},
                    "email": {"type": "string", "example": "test@example.com"},
                    "birth_date": {"type": "string", "example": "19900101", "description": "생년월일 (YYYYMMDD)"},
                },
                "required": ["phone", "password", "name", "birth_date"],
            }
        },
        responses={201: OpenApiExample('회원가입 성공', value={"message": "회원가입 성공", "user_id": 1})},
        tags=['User']
    )
    def post(self, request):
        phone = request.data.get('phone')
        password = request.data.get('password')
        name = request.data.get('name')
        email = request.data.get('email')
        birth_date = request.data.get('birth_date', '').strip()

        if not phone or not password or not name or not birth_date:
            return Response({'error': '모든 정보를 채워주세요. (phone, password, name, birth_date 필수)'}, status=status.HTTP_400_BAD_REQUEST)

        if len(birth_date) != 8 or not birth_date.isdigit():
            return Response({'error': '생년월일은 YYYYMMDD 형식이어야 합니다. (예: 19900101)'}, status=status.HTTP_400_BAD_REQUEST)
        
        if User.objects.filter(phone=phone).exists():
            return Response({'error': '이미 존재하는 전화번호입니다.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # [테스트용] 평문 저장
        user = User.objects.create( # 유저 생성
            phone=phone,
            password=password, # 암호화 없이 그대로 저장
            name=name,
            email=email,
            birth_date=birth_date
        )

        """
        # [배포용] 암호화 저장 코드
        user = User.objects.create_user(
            phone=phone,
            password=password,
            name=name,
            email=email
        )
        """

        # [테스트 기능] 신규 사용자에게 인기 카드 3개 자동 등록
        try:
            popular_cards = Card.objects.filter(card_image_url__isnull=False).exclude(card_image_url='')[:3]
            for card in popular_cards:
                UserCard.objects.create(
                    user=user,
                    card=card,
                    card_number=f"****{str(card.card_id).zfill(4)}"  # 더미 카드 번호
                )
        except Exception as e:
            pass  # 카드 등록 실패해도 회원가입은 진행

        # 회원가입 후 자동 로그인 (JWT 토큰 발급)
        refresh = RefreshToken.for_user(user)
        return Response({
            "message": "회원가입 성공",
            "result": {
                "user_id": user.user_id,
                "name": user.name,
                "token": {
                    "access": str(refresh.access_token),
                    "refresh": str(refresh)
                }
            }
        }, status=status.HTTP_201_CREATED)

class LoginView(APIView): # 로그인 뷰
    @extend_schema(
        summary="로그인",
        description="평문 비밀번호로 인증을 진행합니다.",
        request={ #로그인시 필요한 필드
            "application/json": {
                "type": "object",
                "properties": {
                    "phone": {"type": "string", "example": "01012345678"},
                    "password": {"type": "string", "example": "password123"},
                },
            }
        },
        responses={200: OpenApiExample('로그인 성공', value={"token": {"access": "...", "refresh": "..."}})},
        tags=['User']
    )
    def post(self, request): #POST /users/login
        phone = request.data.get('phone')
        password = request.data.get('password')

        if not phone or not password: #전화번호, 비번 누락시
            return Response({'error': '전화번호와 비밀번호를 입력해주세요.'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(phone=phone) #전화번호로 유저 조회
        except User.DoesNotExist:
            return Response({'error': '존재하지 않는 전화번호입니다.'}, status=status.HTTP_404_NOT_FOUND)
        
        # [테스트용] 평문 비교
        if user.password != password:
            return Response({'error': '비밀번호가 일치하지 않습니다.'}, status=status.HTTP_401_UNAUTHORIZED)

        """
        # [배포용] 암호화 비밀번호 검증 코드
        if not user.check_password(password):
            return Response({'error': '비밀번호가 일치하지 않습니다.'}, status=status.HTTP_401_UNAUTHORIZED)
        """
        
        refresh = RefreshToken.for_user(user) # JWT 토큰 생성
        return Response({
            'message': '로그인 성공',
            'user_id': str(user.user_id),
            'name': user.name,
            'token': {
                'access': str(refresh.access_token),
                'refresh': str(refresh)
            }
        }, status=status.HTTP_200_OK)


class UserProfileView(APIView):
    """유저 정보 조회 (토큰 기반)"""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary="유저 정보 조회",
        description="JWT 토큰 기반으로 로그인한 유저의 모든 정보를 반환합니다.",
        responses={
            200: OpenApiExample(
                '조회 성공',
                value={
                    "user_id": 1,
                    "phone": "01012345678",
                    "name": "테스터",
                    "email": "test@example.com",
                    "birth_date": "19900101",
                    "age_group": "30대",
                    "gender": False,
                    "created_at": "2026-01-27T12:00:00Z",
                    "cards": []
                }
            )
        },
        tags=['User']
    )
    def get(self, request):
        user = request.user

        # 유저 보유 카드 목록
        user_cards = UserCard.objects.filter(user=user).select_related('card')
        cards_data = [
            {
                "user_card_id": uc.user_card_id,
                "card_id": uc.card.card_id,
                "card_name": uc.card.card_name,
                "company": uc.card.company,
                "card_image_url": uc.card.card_image_url,
                "card_number": uc.card_number,
                "registered_at": uc.registered_at,
            }
            for uc in user_cards
        ]

        return Response({
            "user_id": user.user_id,
            "phone": user.phone,
            "name": user.name,
            "email": user.email,
            "birth_date": user.birth_date,
            "age_group": user.age_group,
            "gender": user.gender,
            "created_at": user.created_at,
            "cards": cards_data,
        }, status=status.HTTP_200_OK)
