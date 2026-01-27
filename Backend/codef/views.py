import logging
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.decorators import permission_classes, authentication_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from drf_spectacular.utils import extend_schema, OpenApiParameter
from drf_spectacular.openapi import OpenApiExample
from .service import CodefAPIService
from cards.models import Card
from users.models import UserCard
from expense.models import Expense
from category.models import Category
import datetime

logger = logging.getLogger(__name__)


def extract_bearer_token(request):
    """
    Authorization 헤더에서 Bearer 토큰을 추출 (공백 처리 및 중복 Bearer 제거)
    
    Returns:
        str: 추출된 토큰 (없으면 None)
    """
    auth_header = request.META.get('HTTP_AUTHORIZATION', '').strip()
    if not auth_header:
        return None

    # 대소문자 구분 없이 'bearer '로 시작하는지 확인
    if auth_header.lower().startswith('bearer '):
        token = auth_header[7:].strip()
        # 혹시 'Bearer Bearer ...' 처럼 중복된 경우 한 번 더 제거 (Swagger 등의 설정 이슈 대비)
        if token.lower().startswith('bearer '):
            token = token[7:].strip()
        return token
        
    return None


class GetCodefTokenView(APIView):
    """Codef API 토큰 발급 뷰"""
    
    authentication_classes = []
    permission_classes = [AllowAny]
    
    @extend_schema(
        operation_id="get_codef_token",
        summary="Codef API 토큰 발급",
        description="Codef API의 클라이언트 credentials를 사용하여 액세스 토큰을 발급받습니다.",
        responses={
            200: OpenApiExample(
                '토큰 발급 성공',
                value={
                    "success": True,
                    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
                    "token_type": "Bearer",
                    "message": "토큰이 발급되었습니다."
                }
            ),
            500: OpenApiExample(
                '서버 에러',
                value={
                    "success": False,
                    "error_message": "서버 오류가 발생했습니다."
                }
            ),
        },
        tags=["Codef API"]
    )
    def post(self, request):
        try:
            logger.info("Requesting Codef API access token")
            
            # 1. CodefAPIService에서 토큰 발급
            codef_service = CodefAPIService()
            access_token = codef_service.get_access_token()
            
            if access_token:
                logger.info("Successfully obtained Codef API access token")
                return Response(
                    {
                        "success": True,
                        "access_token": access_token,
                        "token_type": "Bearer",
                        "message": "토큰이 발급되었습니다."
                    },
                    status=status.HTTP_200_OK
                )
            else:
                logger.error("Failed to obtain Codef API access token")
                return Response(
                    {
                        "success": False,
                        "error_message": "Codef API 토큰 발급에 실패했습니다."
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        except Exception as e:
            logger.error(f"Unexpected error in get_codef_token endpoint: {str(e)}")
            return Response(
                {
                    "success": False,
                    "error_message": f"서버 오류가 발생했습니다: {str(e)}"
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CreateConnectedIdView(APIView):
    """Connected ID 발급 뷰 (간편인증 지원)"""

    authentication_classes = []
    permission_classes = [AllowAny]

    @extend_schema(
        operation_id="create_connected_id",
        summary="Connected ID 발급",
        description="카드사 계정 정보 혹은 간편인증 정보로 connected ID를 발급받습니다.",
        request={
            "application/json": {
                "type": "object",
                "properties": {
                    "organization": {"type": "string", "example": "0304", "description": "카드사 코드"},
                    "login_type": {"type": "string", "example": "1", "description": "1:ID/PW, 5:간편인증"},
                    "card_id": {"type": "string", "description": "카드사 회원 ID (login_type=1)"},
                    "password": {"type": "string", "description": "카드사 회원 비밀번호 (login_type=1)"},
                    "user_name": {"type": "string", "description": "실명 (login_type=5)"},
                    "phone_no": {"type": "string", "description": "휴대폰번호 (login_type=5)"},
                    "identity": {"type": "string", "description": "생년월일7자리 (login_type=5)"},
                    "telecom": {"type": "string", "description": "통신사코드 0~5 (login_type=5)"},
                    "two_way_info": {"type": "object", "description": "2차 인증 데이터 (재요청 시)"}
                },
                "required": ["organization"],
            }
        },
        responses={
            201: OpenApiExample(
                '발급 성공',
                value={"success": True, "connected_id": "CONN_ID_..."}
            ),
            202: OpenApiExample(
                '2차 인증 필요',
                value={"success": False, "is_2fa": True, "message": "앱 인증 필요", "two_way_info": {...}}
            )
        },
        tags=["Codef API"]
    )
    def post(self, request):
        try:
            # 1. Authorization 헤더에서 토큰 추출
            access_token = extract_bearer_token(request)
            
            if not access_token:
                logger.warning("Missing Authorization header in create_connected_id request")
                return Response(
                    {"success": False, "error_message": "Authorization 헤더에 Bearer 토큰이 필요합니다."},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # 2. 요청 데이터 수신
            organization = request.data.get('organization', '').strip()
            login_type = request.data.get('login_type', '1')
            
            # ID/PW용
            card_id = request.data.get('card_id', '').strip()
            password = request.data.get('password', '').strip()
            
            # 간편인증용
            user_name = request.data.get('user_name', '').strip()
            phone_no = request.data.get('phone_no', '').strip()
            identity = request.data.get('identity', '').strip()
            telecom = request.data.get('telecom', '').strip()
            
            # 2차 인증 데이터
            two_way_info = request.data.get('two_way_info')

            # 간편인증 데이터 (loginTypeLevel)
            # 프론트엔드에서 loginTypeLevel을 보내준 경우 two_way_info 내부에 저장하여 service로 전달하거나
            # service에서 처리하도록 수정. 여기서는 request.data에 있는 값을 dict에 담아 two_way_info 처럼 전달
            
            # loginTypeLevel을 별도로 받았다면 two_way_info가 없을 때(1차 요청 시) 이를 담아서 보냄
            login_type_level = request.data.get('loginTypeLevel')
            if login_type == '5' and not two_way_info and login_type_level:
                two_way_info = {'loginTypeLevel': login_type_level}
            
            # 필수값 검증
            if not organization:
                return Response(
                    {"success": False, "error_message": "organization은 필수 입력값입니다."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # ID/PW 방식인데 ID/PW가 없는 경우
            if login_type == '1' and (not card_id or not password):
                 return Response(
                    {"success": False, "error_message": "ID/PW 로그인 방식에는 card_id와 password가 필요합니다."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # 간편인증 방식인데 필수 정보가 없는 경우 (1차 요청 시)
            if login_type == '5' and not two_way_info and (not user_name or not phone_no or not identity or not telecom):
                 return Response(
                    {"success": False, "error_message": "간편인증에는 이름, 휴대폰번호, 주민번호, 통신사 정보가 필요합니다."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # 3. Codef API 호출
            codef_service = CodefAPIService()
            
            result = codef_service.create_connected_id(
                organization=organization,
                card_id=card_id,
                password=password,
                login_type=login_type,
                user_name=user_name,
                phone_no=phone_no,
                identity=identity,
                telecom=telecom,
                two_way_info=two_way_info
            )
            
            # 4. 결과 반환
            if result['success']:
                logger.info(f"Successfully created connected ID: {result['connected_id']}")
                return Response(
                    {
                        "success": True,
                        "connected_id": result['connected_id'],
                        "message": "Connected ID가 발급되었습니다."
                    },
                    status=status.HTTP_201_CREATED
                )
            elif result.get('is_2fa'):
                # 2차 인증 필요
                return Response(result, status=status.HTTP_202_ACCEPTED)
            else:
                logger.error(f"Failed to create connected ID: {result['error_message']}")
                return Response(
                    {
                        "success": False,
                        "error_message": result['error_message']
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        except Exception as e:
            logger.error(f"Unexpected error in create_connected_id endpoint: {str(e)}")
            return Response(
                {
                    "success": False,
                    "error_message": f"서버 오류가 발생했습니다: {str(e)}"
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class GetCardListView(APIView):
    """보유 카드 목록 조회 뷰"""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        operation_id="get_card_list",
        summary="보유 카드 목록 조회",
        description="Connected ID를 사용하여 보유한 카드 목록을 조회합니다. 사용자 인증 토큰은 Authorization 헤더에, Codef 토큰은 X-Codef-Token 헤더에 포함해야 합니다.",
        parameters=[
            OpenApiParameter(
                name='X-Codef-Token',
                description='Codef API Access Token',
                required=True,
                location=OpenApiParameter.HEADER,
                type=str
            )
        ],
        request={
            "application/json": {
                "type": "object",
                "properties": {
                    "organization": {"type": "string", "example": "0304", "description": "기관 코드 (예: 0304)"},
                    "connected_id": {"type": "string", "example": "88a0e8...", "description": "Connected ID"},
                    "birth_date": {"type": "string", "example": "19900101", "description": "생년월일 (선택)"},
                    "card_no": {"type": "string", "example": "1234567890123456", "description": "카드 번호 (선택)"},
                    "card_password": {"type": "string", "example": "1234", "description": "카드 비밀번호 (선택)"},
                    "inquiry_type": {"type": "string", "example": "0", "description": "조회 구분 (0: 전체, 1: 유효카드)"},
                },
                "required": ["organization", "connected_id"],
            }
        },
        responses={
            200: OpenApiExample(
                '조회 성공',
                value={
                    "success": True,
                    "data": [
                        {
                            "resCardNo": "536148******1234",
                            "resCardName": "KB국민 굿데이카드",
                            "resCardType": "신용",
                            "resVaildPeriod": "202512",
                            "resTrafficYn": "1"
                        }
                    ]
                }
            ),
            400: OpenApiExample(
                '잘못된 요청',
                value={
                    "success": False,
                    "error_message": "입력값 오류 또는 API 호출 실패"
                }
            ),
            401: OpenApiExample(
                '인증 실패',
                value={
                    "success": False,
                    "error_message": "Authorization 헤더에 Bearer 토큰이 필요합니다."
                }
            ),
             500: OpenApiExample(
                '서버 에러',
                value={
                    "success": False,
                    "error_message": "서버 오류가 발생했습니다."
                }
            ),
        },
        tags=["Codef API"]
    )
    def post(self, request):
        try:
             # 1. 헤더에서 Codef 토큰 추출 (X-Codef-Token)
            access_token = request.headers.get('X-Codef-Token')
            
            if not access_token:
                logger.warning("Missing X-Codef-Token header in get_card_list request")
                return Response(
                    {
                        "success": False,
                        "error_message": "X-Codef-Token 헤더에 Codef API 토큰이 필요합니다."
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            # 2. 요청 데이터 검증
            organization = request.data.get('organization', '').strip()
            connected_id = request.data.get('connected_id', '').strip()
            birth_date = request.data.get('birth_date', '').strip()
            card_no = request.data.get('card_no', '').strip()
            card_password = request.data.get('card_password', '').strip()
            inquiry_type = request.data.get('inquiry_type', '0').strip()
            
            # 필수값 검증
            if not organization or not connected_id:
                return Response(
                    {
                        "success": False,
                        "error_message": "organization, connected_id는 필수 입력값입니다."
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            # 3. Codef API 호출
            codef_service = CodefAPIService()
            codef_service.access_token = access_token
            
            result = codef_service.get_card_list(
                organization=organization,
                connected_id=connected_id,
                birth_date=birth_date,
                card_no=card_no,
                card_password=card_password,
                inquiry_type=inquiry_type
            )
            
            # 4. 결과 반환
            if result['success']:
                try:
                    # 데이터베이스에 카드 정보 저장/업데이트
                    card_data = result.get('data')
                    if isinstance(card_data, dict):
                        card_data = [card_data]
                    elif not isinstance(card_data, list):
                        card_data = []

                    # 기관 코드 매핑
                    org_map = {
                        '0301': '삼성카드', '0302': '신한카드', '0303': '현대카드', '0304': 'KB국민카드',
                        '0305': '롯데카드', '0306': '신한카드', '0311': 'NH농협카드', '0313': '하나카드',
                        '0317': '우리카드', '0320': 'BC카드'
                    }
                    company_name = org_map.get(organization, organization)

                    for item in card_data:
                        res_card_name = item.get('resCardName')
                        res_image_link = item.get('resImageLink')
                        res_card_no = item.get('resCardNo')

                        if res_card_name:
                            # 1. Card 모델 (전체 카드 카탈로그) 업데이트/생성
                            card, created = Card.objects.update_or_create(
                                card_name=res_card_name,
                                company=company_name,
                                defaults={
                                    'card_image_url': res_image_link
                                }
                            )

                            # 2. UserCard 모델 (사용자 소유 카드) 업데이트/생성
                            if request.user.is_authenticated:
                                UserCard.objects.update_or_create(
                                    user=request.user,
                                    card=card,
                                    defaults={
                                        'card_number': res_card_no
                                    }
                                )
                except Exception as db_e:
                    logger.error(f"Failed to save card data to DB: {str(db_e)}")

                return Response(
                    {
                        "success": True,
                        "data": result['data']
                    },
                    status=status.HTTP_200_OK
                )
            else:
                 return Response(
                    {
                        "success": False,
                        "error_message": result['error_message']
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

        except Exception as e:
            logger.error(f"Unexpected error in get_card_list endpoint: {str(e)}")
            return Response(
                {
                    "success": False,
                    "error_message": f"서버 오류가 발생했습니다: {str(e)}"
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class GetBillingListView(APIView):
    """보유 카드 청구 내역 조회 및 Expense 저장 뷰"""

    permission_classes = [IsAuthenticated]

    @extend_schema(
        operation_id="get_billing_list",
        summary="보유 카드 청구 내역 조회 및 저장",
        description="Connected ID를 사용하여 카드 청구 내역을 조회하고 Expense 테이블에 저장합니다.",
        parameters=[
            OpenApiParameter(
                name='X-Codef-Token',
                description='Codef API Access Token',
                required=True,
                location=OpenApiParameter.HEADER,
                type=str
            )
        ],
        request={
            "application/json": {
                "type": "object",
                "properties": {
                    "organization": {"type": "string", "example": "0304", "description": "기관 코드 (예: 0304)"},
                    "connected_id": {"type": "string", "example": "88a0e8...", "description": "Connected ID"},
                    "birth_date": {"type": "string", "example": "19900101", "description": "생년월일 (선택)"},
                    "card_no": {"type": "string", "example": "1234567890123456", "description": "카드 번호 (선택)"},
                    "card_password": {"type": "string", "example": "1234", "description": "카드 비밀번호 (선택)"},
                    "inquiry_type": {"type": "string", "example": "0", "description": "조회 구분 (0: 전체, 1: 유효카드)"},
                },
                "required": ["organization", "connected_id"],
            }
        },
        responses={200: OpenApiExample('성공', value={"success": True, "saved_count": 5})},
        tags=["Codef API"]
    )
    def post(self, request):
        try:
            # 1. 헤더에서 Codef 토큰 추출
            access_token = request.headers.get('X-Codef-Token')
            if not access_token:
                logger.warning("Missing X-Codef-Token header in get_billing_list request")
                return Response(
                    {
                        "success": False,
                        "error_message": "X-Codef-Token 헤더에 Codef API 토큰이 필요합니다."
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            # 2. 요청 데이터 검증
            organization = request.data.get('organization', '').strip()
            connected_id = request.data.get('connected_id', '').strip()
            birth_date = request.data.get('birth_date', '').strip()
            card_no = request.data.get('card_no', '').strip()
            card_password = request.data.get('card_password', '').strip()
            inquiry_type = request.data.get('inquiry_type', '0').strip()

            if not organization or not connected_id:
                return Response(
                    {
                        "success": False,
                        "error_message": "organization, connected_id는 필수 입력값입니다."
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )

            # 3. Codef API 호출
            codef_service = CodefAPIService()
            codef_service.access_token = access_token
            
            result = codef_service.get_billing_list(
                organization=organization,
                connected_id=connected_id,
                birth_date=birth_date,
                card_no=card_no,
                card_password=card_password,
                inquiry_type=inquiry_type
            )

            if not result['success']:
                return Response(result, status=status.HTTP_400_BAD_REQUEST)

            # 4. 데이터 파싱 및 Expense 저장
            api_data = result.get('data', {})
            # api_data가 dict일 수도, list일 수도 있음. 문서는 dict (단건) 또는 list.
            # 하지만 청구 내역'목록'은 보통 UserAccount 당 하나씩 오고, 그 안에 'resChargeHistoryList'가 있음.
            # 지금 예시는 단일 객체 안에 'resChargeHistoryList'가 있는 형태.
            
            billing_items = []
            if isinstance(api_data, dict):
                billing_items = [api_data]
            elif isinstance(api_data, list):
                billing_items = api_data
            
            saved_count = 0
            
            # 기본 카테고리 (없으면 생성)
            default_category, _ = Category.objects.get_or_create(category_name="기타")

            for bill in billing_items:
                history_list = bill.get('resChargeHistoryList', [])
                if not history_list or not isinstance(history_list, list):
                    continue

                for history in history_list:
                    res_used_date = history.get('resUsedDate')
                    if not res_used_date: continue
                    
                    # 날짜 파싱 (YYYYMMDD -> Date)
                    try:
                        spent_at = datetime.datetime.strptime(res_used_date, "%Y%m%d")
                        # Timezone aware로 변환 (settings.USE_TZ=True 가정)
                        spent_at = spent_at.replace(tzinfo=datetime.timezone.utc)
                    except ValueError:
                        continue

                    res_used_card = history.get('resUsedCard', '') # 카드명 or 번호뒷자리
                    
                    # UserCard 찾기
                    user_card = None
                    # ... (UserCard 찾기 로직 생략)
                    if res_used_card:
                        # 1. 이름으로 찾기 (icontains로 완화)
                        user_card = UserCard.objects.filter(
                            user=request.user, 
                            card__card_name__icontains=res_used_card
                        ).first()
                        
                        # 2. 번호 뒷자리로 찾기 (숫자인 경우)
                        if not user_card and res_used_card.isdigit():
                            user_card = UserCard.objects.filter(
                                user=request.user, 
                                card_number__endswith=res_used_card
                            ).first()
                    
                    # 카드 매칭 실패 시 처리 개선
                    if not user_card:
                         # 1. 유저 보유 카드가 단 1개
                         user_cards = UserCard.objects.filter(user=request.user)
                         if user_cards.count() == 1:
                             user_card = user_cards.first()
                         else:
                             # 2. 매칭 실패 시 스킵
                             logger.warning(f"Billing List: Card '{res_used_card}' not found for user {request.user.email}. Skipping.")
                             continue

                    # 금액 파싱 (콤마 제거)
                    def parse_amount(val):
                        if isinstance(val, int): return val
                        if isinstance(val, str):
                            val = val.replace(',', '').strip()
                            return int(val) if val else 0
                        return 0

                    amount = parse_amount(history.get('resUsedAmount'))

                    # Expense 생성/업데이트
                    # 청구 내역에는 승인번호가 없을 수 있으므로 (날짜 + 가맹점명 + 금액) 조합으로 식별
                    # resApprovalNo가 있는지 확인
                    res_approval_no = history.get('resApprovalNo', '')

                    defaults = {
                        'category': default_category,
                        'user_card': user_card,
                        'status': 'PAID',
                        'benefit_received': 0,
                        # 추가 필드
                        'payment_type': history.get('resPaymentType'),
                        'installment_month': parse_amount(history.get('resInstallmentMonth')),
                        'round_no': history.get('resRoundNo'),
                        'payment_principal': parse_amount(history.get('resPaymentPrincipal')),
                        'fee': parse_amount(history.get('resFee')),
                        'payment_amt': parse_amount(history.get('resPaymentAmt')),
                        'after_payment_balance': parse_amount(history.get('resAfterPaymentBalance')),
                        'earn_point': parse_amount(history.get('resEarnPoint')),
                        'approval_number': res_approval_no,
                        'spent_at': spent_at,
                        'amount': amount,
                        'merchant_name': history.get('resMemberStoreName', 'Unknown'),
                    }

                    if res_approval_no:
                        # 승인번호가 있으면 확실하게 중복 제거/업데이트
                        Expense.objects.update_or_create(
                            user=request.user,
                            approval_number=res_approval_no,
                            defaults=defaults
                        )
                    else:
                        # 승인번호가 없으면 (날짜 + 가맹점명 + 금액) 조합으로 식별
                        Expense.objects.get_or_create(
                            user=request.user,
                            spent_at=spent_at,
                            merchant_name=history.get('resMemberStoreName', 'Unknown'),
                            amount=amount,
                            defaults=defaults
                        )
                    saved_count += 1

            return Response({
                "success": True, 
                "message": "청구 내역 조회 및 저장이 완료되었습니다.",
                "saved_count": saved_count,
                "data": api_data
            }, status=200)

        except Exception as e:
            logger.error(f"Error in get_billing_list: {str(e)}")
            return Response({"success": False, "error_message": str(e)}, status=500)

class GetApprovalListView(APIView):
    """카드 승인 내역 조회 및 Expense 저장"""
    
    permission_classes = [IsAuthenticated]

    @extend_schema(
         operation_id="get_approval_list",
         summary="카드 승인 내역 조회 및 저장",
         description="Connected ID를 사용하여 카드 승인 내역을 조회하고 Expense 테이블에 저장합니다. (실시간성 데이터)",
         parameters=[
            OpenApiParameter(
                name='X-Codef-Token',
                description='Codef API Access Token',
                required=True,
                location=OpenApiParameter.HEADER,
                type=str
            )
         ],
         request={
             "application/json": {
                 "type": "object",
                 "properties": {
                    "organization": {"type": "string", "example": "0304"},
                    "connected_id": {"type": "string", "example": "88a0e8..."},
                    "start_date": {"type": "string", "example": "20240101"},
                    "end_date": {"type": "string", "example": "20240131"},
                    "card_no": {"type": "string"},
                    "card_password": {"type": "string"},
                     "birth_date": {"type": "string", "example": "19900101"},
                 },
                 "required": ["organization", "connected_id", "start_date", "end_date"]
             }
         },
         responses={200: OpenApiExample('성공', value={"success": True, "saved_count": 5})},
         tags=["Codef API"]
    )
    def post(self, request):
        try:
            access_token = request.headers.get('X-Codef-Token')
            if not access_token:
                return Response(
                     {"success": False, "error_message": "X-Codef-Token required"},
                     status=status.HTTP_400_BAD_REQUEST
                )

            data = request.data
            organization = data.get('organization')
            connected_id = data.get('connected_id') # 필수
            start_date = data.get('start_date') # 필수 YYYYMMDD
            end_date = data.get('end_date') # 필수 YYYYMMDD
            inquiry_type = data.get('inquiry_type', '0')

            if not all([organization, connected_id, start_date, end_date]):
                return Response(
                    {"success": False, "error_message": "organization, connected_id, start_date, end_date required."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Codef Service
            codef_service = CodefAPIService()
            codef_service.access_token = access_token
            result = codef_service.get_approval_list(
                organization, connected_id, start_date, end_date,
                card_no=data.get('card_no', ''),
                card_password=data.get('card_password', ''),
                birth_date=data.get('birth_date', ''),
                inquiry_type=inquiry_type
            )

            if not result['success']:
                 return Response(result, status=status.HTTP_400_BAD_REQUEST)

             # Parsing & Saving
            api_data = result.get('data', [])
            approval_list = []
            if isinstance(api_data, dict):
                 approval_list = [api_data]
            elif isinstance(api_data, list):
                 approval_list = api_data

            default_category, _ = Category.objects.get_or_create(category_name="기타")
            saved_count = 0

            for item in approval_list:
                # Codef structure: list of accounts, each has 'resApprovalList'
                res_approval_list = item.get('resApprovalList', [])
                if not isinstance(res_approval_list, list): continue
                
                for approval in res_approval_list:
                    # Parse fields
                    res_used_date = approval.get('resUsedDate')
                    res_used_time = approval.get('resUsedTime', '000000')
                    res_approval_no = approval.get('resApprovalNo') # Unique key
                    
                    if not res_used_date: continue
                    
                    # Store Name handling
                    merchant_name = approval.get('resMemberStoreName', 'Unknown')
                    
                    try:
                        dt_str = res_used_date + res_used_time
                        spent_at = datetime.datetime.strptime(dt_str, "%Y%m%d%H%M%S")
                        spent_at = spent_at.replace(tzinfo=datetime.timezone.utc)
                    except:
                        continue

                    # 금액 파싱 (콤마 제거)
                    def parse_amount(val):
                        if isinstance(val, int): return val
                        if isinstance(val, str):
                            val = val.replace(',', '').strip()
                            return int(val) if val else 0
                        return 0

                    amount = parse_amount(approval.get('resUsedAmount'))
                    
                    # UserCard 찾기 Logic
                    res_card_name = approval.get('resCardName', '') 
                    user_card = None

                    if res_card_name:
                         user_card = UserCard.objects.filter(
                            user=request.user, 
                            card__card_name__icontains=res_card_name
                        ).first()
                    
                    # 카드 매칭 실패 시 로직 개선
                    if not user_card:
                         # 1. 유저 보유 카드가 단 1개라면 그 카드로 가정
                         user_cards = UserCard.objects.filter(user=request.user)
                         if user_cards.count() == 1:
                             user_card = user_cards.first()
                         else:
                             # 2. 여러 개인데 매칭 안되면 스킵 (안전 제일)
                             # 로깅만 남김
                             logger.warning(f"Skipping transaction {res_approval_no}: No matching card for '{res_card_name}'")
                             continue 

                    # Save Expense
                    # 승인번호(unique)를 기준으로 update_or_create 수행
                    
                    expense_defaults = {
                        'category': default_category,
                        'user_card': user_card,
                        'status': 'PAID',
                        'spent_at': spent_at,
                        'amount': amount,
                        'merchant_name': merchant_name,
                        'approval_number': res_approval_no
                    }
                    
                    if res_approval_no:
                        # 승인번호가 있으면 확실하게 중복 제거 가능
                        obj, created = Expense.objects.update_or_create(
                            user=request.user,
                            approval_number=res_approval_no,
                            defaults=expense_defaults
                        )
                    else:
                        # 승인번호가 없으면(드문 경우), 기존 방식(날짜+금액+가맹점)으로 중복 체크
                        obj, created = Expense.objects.get_or_create(
                            user=request.user,
                            spent_at=spent_at,
                            amount=amount,
                            merchant_name=merchant_name,
                            defaults=expense_defaults
                        )
                    
                    if created:
                        saved_count += 1

            return Response({
                "success": True, 
                "message": f"Saved {saved_count} transactions.",
                "data": result.get('data')
            })

        except Exception as e:
            logger.error(f"Error in approval list: {e}")
            return Response({"success": False, "error_message": str(e)}, status=500)
