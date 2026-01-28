from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.utils import timezone
from datetime import timedelta, date
from .models import CardBenefit, Card  # [설명] 본인 앱(cards)의 모델
from users.models import UserCard  # [설명] users 앱의 User 모델
from expense.models import Expense  # [설명] expense 앱의 Expense 모델
from django.db.models import Avg, Sum  # [설명] 집계 함수 import
from .serializers import CardSerializer, RecommendedCardSerializer, UserCardListSerializer, CardRecommendationsResponseSerializer
from drf_spectacular.utils import extend_schema, OpenApiParameter  # [추가] drf-spectacular 스웨거 설정을 위해 import
from category.models import Category
from decimal import Decimal
# 사용자가 보유한 모든 카드 조회, 카드 등록, 카드 추천, 카드 혜택 효율 분석 API 구현

# 공통 에러 응답 함수 (중복 제거)
def error_response(message, code, status_code, reason=None):
    # [설명] 모든 뷰에서 공통으로 사용하는 에러 응답 포맷 함수
    res = {"message": message, "code": code}
    if reason:
        res["reason"] = reason
    return Response(res, status=status_code)

# 카드 목록 조회 뷰
class CardListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="내 카드 목록 조회",
        description="현재 로그인한 사용자가 등록한 모든 카드 리스트를 가져옵니다. 카드 이미지 URL 포함.",
        responses={200: UserCardListSerializer(many=True)},
        tags=["Cards"]
    )
    def get(self, request):
        # UserCard 목록을 가져옵니다.
        user_card_queryset = UserCard.objects.filter(user=request.user).select_related('card')
        
        # 카드 정보를 포맷팅하여 반환
        cards_data = []
        for uc in user_card_queryset:
            card = uc.card
            cards_data.append({
                "card_id": card.card_id,
                "card_name": card.card_name,
                "card_number": uc.card_number or "",  # 카드 번호 (마스킹된 형태)
                "card_image_url": card.card_image_url or "",  # 카드 이미지 URL
                "company": card.company,
                "card_type": ""  # 필요시 나중에 추가 (VISA, MASTER 등)
            })
        
        serializer = UserCardListSerializer(cards_data, many=True)
        return Response({
            "message": "내 카드 목록 조회 성공",
            "cards": serializer.data
        }, status=status.HTTP_200_OK)

# 카드 추천 뷰
class CardRecommendationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="카드 추천 조회",
        description="사용자가 가장 많이 소비한 카테고리 기반으로 추천 카드 목록을 반환합니다.",
        responses={200: RecommendedCardSerializer(many=True)},
        tags=["Cards"]
    )

    def get(self, request):
        user = request.user
        three_months_ago = timezone.now() - timedelta(days=90)

        # 1. 최근 3개월간 가장 많이 소비한 카테고리 Top 1 추출
        top_category_data = Expense.objects.filter(
            user=user,
            spent_at__gte=three_months_ago,
            deleted_at__isnull=True
        ).values('category').annotate(
            total_amount=Sum('amount')
        ).order_by('-total_amount').first()

        if not top_category_data:
            return error_response("추천 실패", "NO_DATA", 404, "최근 지출 내역이 없습니다.")

        top_category_id = top_category_data['category']

        # 2. 해당 카테고리 혜택이 높은 순으로 카드 조회 (중복 제거 필수)
        recommended_benefits = CardBenefit.objects.filter(
            category_id=top_category_id,
            deleted_at__isnull=True
        ).select_related('card').order_by('-benefit_rate')

        # [수정] 동일한 카드가 여러 번 나오지 않도록 중복 제거하며 5개 추출
        seen_cards = set()
        unique_cards = []
        for benefit in recommended_benefits:
            if benefit.card.card_id not in seen_cards:
                unique_cards.append(benefit.card)
                seen_cards.add(benefit.card.card_id)
            if len(unique_cards) >= 5: break

        serializer = RecommendedCardSerializer(unique_cards, many=True)
        return Response({
            "message": "카드 추천 목록 조회 성공",
            "target_category_id": top_category_id,
            "recommended_cards": serializer.data # 데이터가 잘 담겨 나가는지 확인
        }, status=200)
    
# 카드 혜택 효율 분석 뷰
class CardBenefitAnalysisView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="종합 카드 분석 및 추천",
        description="보유 카드의 효율 분석 결과와 소비 패턴 기반 추천 카드 TOP 5를 함께 반환합니다.",
        tags=["Analysis"]
    )
    def get(self, request):
        user = request.user
        three_months_ago = timezone.now() - timedelta(days=90)
        
        try:
            # --- 1. 내 카드 효율(ROI) 분석 로직 ---
            user_cards = UserCard.objects.filter(user=user).select_related('card')
            my_cards_analysis = []
            seen_card_ids = set() # 내 카드 ID 저장용 (이미 가진 카드 추천 제외용)

            for uc in user_cards:
                card = uc.card
                seen_card_ids.add(card.card_id) 
                
                total_benefit = 0
                benefits = CardBenefit.objects.filter(card=card)
                
                for benefit in benefits:
                    expense_sum = Expense.objects.filter(
                        user=user, category=benefit.category,
                        spent_at__gte=three_months_ago, deleted_at__isnull=True
                    ).aggregate(Sum('amount'))['amount__sum'] or 0
                    
                    if expense_sum > 0:
                        calc = expense_sum * (float(benefit.benefit_rate) / 100)
                        total_benefit += min(calc, benefit.benefit_limit) if benefit.benefit_limit else calc

                annual_fee = max(card.annual_fee_domestic, 1000)
                monthly_avg = total_benefit / 3
                roi = ((monthly_avg * 12) / annual_fee) * 100

                my_cards_analysis.append({
                    "section_title": "내 카드",
                    "card_id": card.card_id,
                    "card_name": card.card_name,
                    "roi_percent": round(roi, 1),
                    "expected_monthly_benefit": int(monthly_avg)
                })

            # --- 2. 추천 카드 분석 로직 ---
            # (소비패턴 전체 분석 후 상위 카테고리 3개 추출)
            category_stats = Expense.objects.filter(
                user=user, spent_at__gte=three_months_ago
            ).values('category').annotate(total_amount=Sum('amount')).order_by('-total_amount')[:3]
            
            top_category_ids = [s['category'] for s in category_stats]
            
            # 해당 카테고리 혜택이 좋은 카드 검색
            candidate_benefits = CardBenefit.objects.filter(
                category_id__in=top_category_ids
            ).select_related('card').order_by('-benefit_rate')

            recommendations = []
            for ben in candidate_benefits:
                card = ben.card
                if card.card_id in seen_card_ids: continue # 이미 보유한 카드 제외
                
                # 중복 추천 방지
                if any(r['card_id'] == card.card_id for r in recommendations): continue
                
                recommendations.append({
                    "card_id": card.card_id,
                    "card_name": card.card_name,
                    "company": card.company,
                    "benefit_summary": ben.category.category_name + " " + str(ben.benefit_rate) + "% 할인"
                })
                if len(recommendations) >= 5: break
            
            return Response({
                "my_cards_analysis": my_cards_analysis,
                "recommendations": recommendations
            }, status=200)

        except Exception as e:
            return error_response("분석 실패", "ANALYSIS_ERROR", 500, str(e))


# 카테고리별 이모지/컬러 매핑
CATEGORY_STYLE = {
    '식비': {'emoji': '🍔', 'color': '#FF5722'},
    '카페/디저트': {'emoji': '☕', 'color': '#795548'},
    '대중교통': {'emoji': '🚌', 'color': '#2196F3'},
    '편의점': {'emoji': '🏪', 'color': '#4CAF50'},
    '온라인쇼핑': {'emoji': '🛒', 'color': '#9C27B0'},
    '대형마트': {'emoji': '🛍️', 'color': '#E91E63'},
    '주유/차량': {'emoji': '⛽', 'color': '#607D8B'},
    '통신/공과금': {'emoji': '📱', 'color': '#00BCD4'},
    '디지털구독': {'emoji': '🎬', 'color': '#673AB7'},
    '문화/여가': {'emoji': '🎭', 'color': '#FF9800'},
    '의료/건강': {'emoji': '🏥', 'color': '#F44336'},
    '교육': {'emoji': '📚', 'color': '#3F51B5'},
    '뷰티/잡화': {'emoji': '💄', 'color': '#E91E63'},
    '여행/숙박': {'emoji': '✈️', 'color': '#00BCD4'},
}


# 카드 추천 API
class CardRecommendationsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @extend_schema(
        summary="카드 추천 조회",
        description="사용자의 최근 3개월 지출 내역을 분석하여 카테고리별로 최적의 카드를 추천합니다.",
        responses={200: CardRecommendationsResponseSerializer},
        tags=["Cards"]
    )
    def get(self, request):
        user = request.user
        now = timezone.now()
        three_months_ago = now - timedelta(days=90)

        # 분석 기간 설정
        analysis_period = {
            "start": three_months_ago.strftime("%Y-%m-%d"),
            "end": now.strftime("%Y-%m-%d")
        }

        # 1. 최근 3개월 지출 내역 가져오기
        expenses = Expense.objects.filter(
            user=user,
            spent_at__gte=three_months_ago,
            deleted_at__isnull=True,
            status='PAID'
        ).select_related('category')

        if not expenses.exists():
            return Response({
                "generated_at": now.isoformat(),
                "analysis_period": analysis_period,
                "categories": []
            }, status=status.HTTP_200_OK)

        # 2. 카테고리별 지출 집계
        category_spending = {}
        for expense in expenses:
            cat_id = expense.category_id
            cat_name = expense.category.category_name
            if cat_id not in category_spending:
                category_spending[cat_id] = {
                    'category_name': cat_name,
                    'total_spent': 0
                }
            category_spending[cat_id]['total_spent'] += expense.amount

        # 3. 월 평균 계산 및 필터링 (월 평균 10,000원 이상)
        category_list = []
        for cat_id, data in category_spending.items():
            monthly_avg = data['total_spent'] / 3
            if monthly_avg >= 10000:
                category_list.append({
                    'category_id': cat_id,
                    'category_name': data['category_name'],
                    'total_spent': data['total_spent'],
                    'monthly_average': int(monthly_avg)
                })

        # 4. 지출 금액 순으로 정렬 후 상위 5개 선택
        category_list.sort(key=lambda x: x['total_spent'], reverse=True)
        top_categories = category_list[:5]

        # 5. 각 카테고리별 추천 카드 조회
        result_categories = []
        for cat_data in top_categories:
            cat_id = cat_data['category_id']
            cat_name = cat_data['category_name']

            # 카테고리 스타일 가져오기 (기본값 설정)
            style = CATEGORY_STYLE.get(cat_name, {'emoji': '💳', 'color': '#757575'})

            # 해당 카테고리에 혜택이 있는 카드 찾기
            card_benefits = CardBenefit.objects.filter(
                category_id=cat_id,
                deleted_at__isnull=True
            ).select_related('card').prefetch_related('card__cardbenefit_set__category')

            # 카드별 ROI 계산
            card_roi_map = {}
            for benefit in card_benefits:
                card = benefit.card
                card_id = card.card_id

                if card_id not in card_roi_map:
                    # ROI 계산
                    annual_estimated = cat_data['monthly_average'] * 12
                    benefit_rate = float(benefit.benefit_rate or 0)
                    annual_benefit = int(annual_estimated * (benefit_rate / 100))

                    # 혜택 한도 적용
                    if benefit.benefit_limit:
                        annual_benefit = min(annual_benefit, benefit.benefit_limit * 12)

                    # ROI 계산
                    annual_fee = card.annual_fee_domestic or 0
                    if annual_fee > 0:
                        roi = (annual_benefit / annual_fee) * 100
                    else:
                        roi = annual_benefit  # 연회비가 0이면 ROI는 연간 혜택 금액

                    # 카드의 모든 혜택 정보 수집
                    all_benefits = CardBenefit.objects.filter(
                        card=card,
                        deleted_at__isnull=True
                    ).select_related('category')

                    main_benefits = []
                    category_benefits = []
                    for cb in all_benefits:
                        benefit_desc = f"{cb.category.category_name} {cb.benefit_rate}% 할인"
                        main_benefits.append(benefit_desc)

                        if cb.category_id == cat_id:
                            category_benefits.append({
                                'category': cb.category.category_name,
                                'description': benefit_desc,
                                'discount_rate': cb.benefit_rate
                            })

                    card_roi_map[card_id] = {
                        'card_id': card_id,
                        'card_name': card.card_name,
                        'card_company': card.company,
                        'card_image_url': card.card_image_url or '',
                        'annual_fee': annual_fee,
                        'roi_percent': round(roi, 1),
                        'estimated_annual_benefit': annual_benefit,
                        'main_benefits': main_benefits[:3],  # 상위 3개만
                        'category_benefits': category_benefits
                    }

            # ROI 순으로 정렬하여 상위 4개 선택
            recommended_cards = sorted(
                card_roi_map.values(),
                key=lambda x: x['roi_percent'],
                reverse=True
            )[:4]

            result_categories.append({
                'category_name': cat_name,
                'emoji': style['emoji'],
                'color': style['color'],
                'monthly_average': cat_data['monthly_average'],
                'total_spent': cat_data['total_spent'],
                'recommended_cards': recommended_cards
            })

        return Response({
            "generated_at": now.isoformat(),
            "analysis_period": analysis_period,
            "categories": result_categories
        }, status=status.HTTP_200_OK)
