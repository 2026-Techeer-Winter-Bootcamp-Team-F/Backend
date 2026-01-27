from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.utils import timezone
from datetime import timedelta
from .models import CardBenefit  # [설명] 본인 앱(cards)의 모델
from users.models import UserCard  # [설명] users 앱의 User 모델
from expense.models import Expense  # [설명] expense 앱의 Expense 모델
from django.db.models import Avg, Sum  # [설명] 집계 함수 import
from .serializers import CardSerializer, RecommendedCardSerializer, UserCardListSerializer
from drf_spectacular.utils import extend_schema, OpenApiParameter  # [추가] drf-spectacular 스웨거 설정을 위해 import
from category.models import Category
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
