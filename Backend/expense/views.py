from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.db.models import Sum, Avg, Q
from django.utils import timezone
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
from calendar import monthrange
from drf_spectacular.utils import extend_schema, OpenApiParameter
from .models import Expense, Subscription
from cards.models import CardBenefit, Card
from users.models import UserCard
from category.models import Category
from .serializers import (
    AccumulatedDataSerializer, DailySummarySerializer, TransactionSerializer,
    WeeklyDataSerializer, MonthlyDataSerializer, CategoryDataSerializer,
    MonthComparisonSerializer, CATEGORY_MAPPING
)

# 1. 공통 Base 클래스 (인증 및 에러 응답 통일)
class BaseAuthView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    auth_error_message = "조회 실패"
    auth_error_reason = "로그인이 필요하거나 만료되었습니다."
    auth_error_code = "AUTH_REQUIRED"

    def handle_exception(self, exc):
        response = super().handle_exception(exc)
        if response.status_code == status.HTTP_401_UNAUTHORIZED:
            return Response({
                "message": self.auth_error_message,
                "error_code": self.auth_error_code,
                "reason": self.auth_error_reason
            }, status=status.HTTP_401_UNAUTHORIZED)
        return response

# 2. 소비 패턴 분석 뷰
class ConsumptionPatternAnalysisView(BaseAuthView):
    @extend_schema(
        summary="소비 패턴 분석",
        description="특정 월의 지출을 그룹 평균과 비교하고 혜택 달성률 및 백분위를 분석합니다.",
        parameters=[
            OpenApiParameter(name='month', description='조회 대상 월 (YYYY-MM)', required=True, type=str)
        ],
        tags=['Expense']
    )
    def get(self, request): # 소비자에게 패턴 분석 데이터 제공
        user = request.user    # 인증된 사용자
        target_month = request.query_params.get('month') # YYYY-MM 형식

        if not target_month: # 월 누락시
            return Response({"message": "필수 파라미터(month)가 누락되었습니다."}, status=400)

        try: # 년, 월 분리
            year, month = map(int, target_month.split('-'))
            
            # 1. 내 지출 데이터 조회
            my_expenses = Expense.objects.filter(
                user=user, 
                spent_at__year=year, 
                spent_at__month=month,
                deleted_at__isnull=True
            )
            
            my_total_spent = my_expenses.aggregate(Sum('amount'))['amount__sum'] or 0 # 내 총 지출

            # 2. 그룹(전체 유저) 평균 및 백분위 계산
            # 모든 유저의 해당 월 총 지출 리스트를 가져옴
            all_user_totals = Expense.objects.filter(
                spent_at__year=year, 
                spent_at__month=month, 
                deleted_at__isnull=True
            ).values('user').annotate(user_total=Sum('amount')).order_by('user_total')

            total_users = all_user_totals.count()
            group_avg_spent = all_user_totals.aggregate(Avg('user_total'))['user_total__avg'] or 1
            
            # 내 위치(백분위) 계산
            my_rank = 0
            for index, entry in enumerate(all_user_totals):
                if entry['user_total'] >= my_total_spent:
                    my_rank = index
                    break
            
            # 백분위 (0~100, 낮을수록 적게 씀)
            percentile = round((my_rank / total_users) * 100) if total_users > 0 else 0
            diff_percent = round(((my_total_spent - group_avg_spent) / group_avg_spent) * 100, 1)

            # 3. 실시간 혜택 달성률 계산 (게이지바용)
            total_benefit_received = 0
            user_benefits = CardBenefit.objects.filter(card__usercard__user=user)
            
            for benefit in user_benefits: # 각 혜택별로 계산, 필터로 기준 정함
                cat_expense = my_expenses.filter(category=benefit.category).aggregate(Sum('amount'))['amount__sum'] or 0
                if cat_expense > 0:
                    raw_benefit = cat_expense * (float(benefit.benefit_rate) / 100)
                    total_benefit_received += min(raw_benefit, benefit.benefit_limit or raw_benefit)

            max_limit = user_benefits.aggregate(Sum('benefit_limit'))['benefit_limit__sum'] or 1
            achievement_rate = round((total_benefit_received / max_limit) * 100, 1)

            # 4. 카드별 사용 내역 집계 (화면 하단 카드용)
            # UserCard 별로 Expense group by sum
            user_card_usage = my_expenses.values(
                'user_card__card__card_name', 
                'user_card__card_number', 
                'user_card__card__card_image_url',
                'user_card__card__company'
            ).annotate(total_amount=Sum('amount')).order_by('-total_amount')

            cards_usage = []
            for usage in user_card_usage:
                # user_card가 null인 경우(현금/기타) 제외 혹은 별도 처리
                if not usage['user_card__card__card_name']:
                    continue
                
                cards_usage.append({
                    "card_name": usage['user_card__card__card_name'],
                    "card_number": usage['user_card__card_number'] or "",
                    "card_image": usage['user_card__card__card_image_url'] or "",
                    "company": usage['user_card__card__company'] or "",
                    "amount": usage['total_amount']
                })
            
            # 최소 2개 이상의 카드가 필요하다면, 없으면 빈 리스트 혹은 더미(현재는 DB실제값만)
            
            # 5. JSON 응답 (사용자 요구 형식 반영)
            return Response({
                "message": "소비 패턴 분석 데이터 조회 성공",
                "result": {
                    "user_id": user.user_id,
                    "user_name": user.name,
                    "comparison": {
                        "my_total_spent": my_total_spent,
                        "group_avg_spent": round(group_avg_spent),
                        "diff_percent": diff_percent,
                        "percentile": percentile
                    },
                    "benefit_status": {
                        "total_benefit_received": round(total_benefit_received),
                        "max_benefit_limit": max_limit,
                        "achievement_rate": min(achievement_rate, 100.0) # 100% 초과 방지
                    },
                    "cards_usage": cards_usage
                }
            }, status=200)

        except Exception as e:
            return Response({"message": str(e)}, status=500)

# 3. 구독 정보 삭제 (소프트 삭제) ---> 수정 필요
class DeleteSubscription(BaseAuthView):
    @extend_schema(
        summary="구독 정보 삭제",
        description="특정 구독 정보를 소프트 삭제 처리합니다.",
        tags=['Expense']
    )
    def delete(self, request, subs_id):
        try:
            subscription = Subscription.objects.get(
                subs_id=subs_id, 
                user_card__user=request.user,
                deleted_at__isnull=True
            )
            subscription.deleted_at = timezone.now()
            subscription.status = "CANCELED"
            subscription.save()

            return Response({"message": "삭제 성공"}, status=200)
        except Subscription.DoesNotExist:
            return Response({"message": "삭제할 구독 정보를 찾을 수 없습니다."}, status=404)

# 4. 소비 내역 조회
class ShowExpense(BaseAuthView):
    @extend_schema(
        summary="월간 소비 내역 조회",
        description="특정 월의 전체 소비 내역 리스트를 조회합니다.",
        parameters=[
            OpenApiParameter(name='month', description='조회 대상 월 (YYYY-MM)', required=True, type=str)
        ],
        tags=['Expense']
    )
    def get(self, request):
        target_month = request.query_params.get('month')
        if not target_month:
            return Response({"message": "조회 월(month)이 필요합니다."}, status=400)

        try:
            year, month = map(int, target_month.split('-'))
            expenses = Expense.objects.filter(
                user=request.user, spent_at__year=year, spent_at__month=month, deleted_at__isnull=True
            ).select_related('category', 'user_card__card')

            total_spent = expenses.aggregate(total=Sum('amount'))['total'] or 0
            expense_list = [{
                "expense_id": e.expense_id,
                "merchant_name": e.merchant_name,
                "amount": e.amount,
                "spent_at": e.spent_at.strftime("%Y-%m-%dT%H:%M:%S"),
                "category_name": e.category.category_name if e.category else "미분류",
                "card_name": e.user_card.card.card_name if e.user_card else "기타"
            } for e in expenses]

            return Response({
                "message": "월간 지출 내역 조회 성공",
                "result": {"total_spent": total_spent, "expense_list": expense_list}
            }, status=200)
        except Exception as e:
            return Response({"message": str(e)}, status=400)


# 5. 구독 내역 조회 (보안 및 데이터 보완 버전)
class ShowSubscription(BaseAuthView):
    @extend_schema(summary="구독 내역 조회", description="사용자의 활성 구독 목록을 조회합니다.", tags=['Expense'])
    def get(self, request):
        try:
            # 결제일이 가까운 순서로 정렬 추가
            subscriptions = Subscription.objects.filter(
                user=request.user,  # user_card를 통하는 것보다 직접 연결된 user 필드 사용 권장
                deleted_at__isnull=True
            ).select_related('user_card__card', 'category').order_by('next_billing')
            
            sub_list = []
            for s in subscriptions:
                # 오늘 기준으로 결제일까지 남은 일수 계산 (선택 사항)
                days_left = (s.next_billing - timezone.now().date()).days

                sub_list.append({
                    "subs_id": s.subs_id,
                    "service_name": s.service_name,
                    "monthly_fee": s.monthly_fee,
                    "next_billing": s.next_billing.strftime("%Y-%m-%d"),
                    "d_day": days_left, # "결제일까지 D-3" 등으로 활용 가능
                    "status": s.status, # "ACTIVE"
                    "status_kor": s.get_status_display(), # "구독중" (모델의 choices 기반 자동 변환)
                    "category_name": s.category.category_name if s.category else "기타"
                })

            return Response({
                "message": "구독 내역 조회 성공", 
                "result": sub_list
            }, status=200)
        except Exception as e:
            return Response({"message": str(e)}, status=400)


# ==================== 프론트엔드 홈화면용 신규 API ====================

# 6. 누적 데이터 API
class AccumulatedDataView(BaseAuthView):
    @extend_schema(
        summary="월별 누적 데이터 조회",
        description="특정 월의 일별 누적 지출 데이터를 반환합니다.",
        parameters=[
            OpenApiParameter(name='year', description='연도 (예: 2026)', required=True, type=int),
            OpenApiParameter(name='month', description='월 (예: 1)', required=True, type=int)
        ],
        responses={200: AccumulatedDataSerializer},
        tags=['Home']
    )
    def get(self, request):
        try:
            year = int(request.query_params.get('year'))
            month = int(request.query_params.get('month'))
        except (TypeError, ValueError):
            return Response({"message": "year와 month 파라미터가 필요합니다."}, status=400)

        try:
            user = request.user
            expenses = Expense.objects.filter(
                user=user,
                spent_at__year=year,
                spent_at__month=month,
                deleted_at__isnull=True
            ).order_by('spent_at')

            # 일별 지출 집계
            daily_totals = {}
            for expense in expenses:
                day = expense.spent_at.day
                daily_totals[day] = daily_totals.get(day, 0) + expense.amount

            # 누적 합계 계산
            daily_data = []
            accumulated = 0
            days_in_month = monthrange(year, month)[1]
            
            for day in range(1, days_in_month + 1):
                daily_amount = daily_totals.get(day, 0)
                accumulated += daily_amount
                daily_data.append({
                    "day": day,
                    "amount": float(accumulated)
                })

            result = {
                "total": accumulated,
                "dailyData": daily_data
            }

            serializer = AccumulatedDataSerializer(result)
            return Response(serializer.data, status=200)

        except Exception as e:
            return Response({"message": f"데이터 조회 실패: {str(e)}"}, status=500)


# 7. 일별 요약 API
class DailySummaryView(BaseAuthView):
    @extend_schema(
        summary="일별 지출 요약",
        description="특정 월의 각 날짜별 지출 합계를 반환합니다.",
        parameters=[
            OpenApiParameter(name='year', description='연도', required=True, type=int),
            OpenApiParameter(name='month', description='월', required=True, type=int)
        ],
        responses={200: DailySummarySerializer},
        tags=['Home']
    )
    def get(self, request):
        try:
            year = int(request.query_params.get('year'))
            month = int(request.query_params.get('month'))
        except (TypeError, ValueError):
            return Response({"message": "year와 month 파라미터가 필요합니다."}, status=400)

        try:
            user = request.user
            expenses = Expense.objects.filter(
                user=user,
                spent_at__year=year,
                spent_at__month=month,
                deleted_at__isnull=True
            )

            # 일별 합계
            daily_expenses = {}
            for expense in expenses:
                day = expense.spent_at.day
                daily_expenses[str(day)] = daily_expenses.get(str(day), 0) + expense.amount

            result = {"expenses": daily_expenses}
            serializer = DailySummarySerializer(result)
            return Response(serializer.data, status=200)

        except Exception as e:
            return Response({"message": f"데이터 조회 실패: {str(e)}"}, status=500)


# 8. 일별 상세 거래 내역 API
class DailyDetailView(BaseAuthView):
    @extend_schema(
        summary="특정 날짜 거래 상세 내역",
        description="특정 날짜의 모든 거래 내역을 반환합니다.",
        parameters=[
            OpenApiParameter(name='year', description='연도', required=True, type=int),
            OpenApiParameter(name='month', description='월', required=True, type=int),
            OpenApiParameter(name='day', description='일', required=True, type=int)
        ],
        tags=['Home']
    )
    def get(self, request):
        try:
            year = int(request.query_params.get('year'))
            month = int(request.query_params.get('month'))
            day = int(request.query_params.get('day'))
        except (TypeError, ValueError):
            return Response({"message": "year, month, day 파라미터가 필요합니다."}, status=400)

        try:
            user = request.user
            expenses = Expense.objects.filter(
                user=user,
                spent_at__year=year,
                spent_at__month=month,
                spent_at__day=day,
                deleted_at__isnull=True
            ).select_related('category').order_by('-spent_at')

            transactions = []
            for expense in expenses:
                category_name = expense.category.category_name if expense.category else "기타"
                category_info = CATEGORY_MAPPING.get(category_name, {})
                
                transactions.append({
                    "name": expense.merchant_name,
                    "category": category_info.get('en_name', 'shopping'),
                    "amount": expense.amount,
                    "currency": "KRW"
                })

            return Response({"transactions": transactions}, status=200)

        except Exception as e:
            return Response({"message": f"데이터 조회 실패: {str(e)}"}, status=500)


# 9. 주간 평균 API
class WeeklyAverageView(BaseAuthView):
    @extend_schema(
        summary="주간 평균 지출",
        description="특정 월의 주간 평균 지출을 계산합니다.",
        parameters=[
            OpenApiParameter(name='year', description='연도', required=True, type=int),
            OpenApiParameter(name='month', description='월', required=True, type=int)
        ],
        responses={200: WeeklyDataSerializer},
        tags=['Home']
    )
    def get(self, request):
        try:
            year = int(request.query_params.get('year'))
            month = int(request.query_params.get('month'))
        except (TypeError, ValueError):
            return Response({"message": "year와 month 파라미터가 필요합니다."}, status=400)

        try:
            user = request.user
            
            # 해당 월의 총 지출
            total_spent = Expense.objects.filter(
                user=user,
                spent_at__year=year,
                spent_at__month=month,
                deleted_at__isnull=True
            ).aggregate(total=Sum('amount'))['total'] or 0

            # 해당 월의 주 수 계산 (대략 4주로 계산)
            days_in_month = monthrange(year, month)[1]
            weeks = days_in_month / 7
            
            average = int(total_spent / weeks) if weeks > 0 else 0

            result = {"average": average}
            serializer = WeeklyDataSerializer(result)
            return Response(serializer.data, status=200)

        except Exception as e:
            return Response({"message": f"데이터 조회 실패: {str(e)}"}, status=500)


# 10. 월간 평균 API
class MonthlyAverageView(BaseAuthView):
    @extend_schema(
        summary="월간 평균 지출",
        description="최근 6개월 간의 월평균 지출을 계산합니다.",
        parameters=[
            OpenApiParameter(name='year', description='연도', required=True, type=int),
            OpenApiParameter(name='month', description='월', required=True, type=int)
        ],
        responses={200: MonthlyDataSerializer},
        tags=['Home']
    )
    def get(self, request):
        try:
            year = int(request.query_params.get('year'))
            month = int(request.query_params.get('month'))
        except (TypeError, ValueError):
            return Response({"message": "year와 month 파라미터가 필요합니다."}, status=400)

        try:
            user = request.user
            current_date = datetime(year, month, 1)
            
            # 최근 6개월 데이터 집계
            monthly_totals = []
            for i in range(6):
                target_date = current_date - relativedelta(months=i)
                month_total = Expense.objects.filter(
                    user=user,
                    spent_at__year=target_date.year,
                    spent_at__month=target_date.month,
                    deleted_at__isnull=True
                ).aggregate(total=Sum('amount'))['total'] or 0
                monthly_totals.append(month_total)

            average = int(sum(monthly_totals) / len(monthly_totals)) if monthly_totals else 0

            result = {"average": average}
            serializer = MonthlyDataSerializer(result)
            return Response(serializer.data, status=200)

        except Exception as e:
            return Response({"message": f"데이터 조회 실패: {str(e)}"}, status=500)


# 11. 카테고리별 요약 API
class CategorySummaryView(BaseAuthView):
    @extend_schema(
        summary="카테고리별 지출 요약",
        description="특정 월의 카테고리별 지출 및 전월 대비 변화를 반환합니다.",
        parameters=[
            OpenApiParameter(name='year', description='연도', required=True, type=int),
            OpenApiParameter(name='month', description='월', required=True, type=int)
        ],
        tags=['Home']
    )
    def get(self, request):
        try:
            year = int(request.query_params.get('year'))
            month = int(request.query_params.get('month'))
        except (TypeError, ValueError):
            return Response({"message": "year와 month 파라미터가 필요합니다."}, status=400)

        try:
            user = request.user
            
            # 이번 달 카테고리별 지출
            current_expenses = Expense.objects.filter(
                user=user,
                spent_at__year=year,
                spent_at__month=month,
                deleted_at__isnull=True
            ).values('category__category_name').annotate(
                total=Sum('amount')
            )

            # 전월 카테고리별 지출
            prev_date = datetime(year, month, 1) - relativedelta(months=1)
            prev_expenses = Expense.objects.filter(
                user=user,
                spent_at__year=prev_date.year,
                spent_at__month=prev_date.month,
                deleted_at__isnull=True
            ).values('category__category_name').annotate(
                total=Sum('amount')
            )

            # 전월 데이터를 딕셔너리로 변환
            prev_dict = {item['category__category_name']: item['total'] for item in prev_expenses}
            
            # 이번 달 총 지출
            total_spent = sum(item['total'] for item in current_expenses) or 1

            categories = []
            for item in current_expenses:
                category_name = item['category__category_name'] or "기타"
                current_amount = item['total']
                prev_amount = prev_dict.get(category_name, 0)
                change = current_amount - prev_amount
                percent = int((current_amount / total_spent) * 100)
                
                category_info = CATEGORY_MAPPING.get(category_name, {
                    'emoji': '🏷️',
                    'color': '#757575',
                    'en_name': 'other'
                })

                categories.append({
                    "name": category_name,
                    "emoji": category_info['emoji'],
                    "amount": current_amount,
                    "change": change,
                    "percent": percent,
                    "color": category_info['color']
                })

            # 금액순 정렬
            categories.sort(key=lambda x: x['amount'], reverse=True)

            return Response({"categories": categories}, status=200)

        except Exception as e:
            return Response({"message": f"데이터 조회 실패: {str(e)}"}, status=500)


# 12. 월간 비교 API
class MonthComparisonView(BaseAuthView):
    @extend_schema(
        summary="월간 비교 데이터",
        description="이번 달과 지난 달의 누적 지출 비교 데이터를 반환합니다.",
        parameters=[
            OpenApiParameter(name='year', description='연도', required=True, type=int),
            OpenApiParameter(name='month', description='월', required=True, type=int)
        ],
        responses={200: MonthComparisonSerializer},
        tags=['Home']
    )
    def get(self, request):
        try:
            year = int(request.query_params.get('year'))
            month = int(request.query_params.get('month'))
        except (TypeError, ValueError):
            return Response({"message": "year와 month 파라미터가 필요합니다."}, status=400)

        try:
            user = request.user
            current_date = datetime(year, month, 1)
            today = datetime.now()
            current_day = today.day if today.year == year and today.month == month else monthrange(year, month)[1]

            # 이번 달 일별 누적 데이터
            this_month_expenses = Expense.objects.filter(
                user=user,
                spent_at__year=year,
                spent_at__month=month,
                deleted_at__isnull=True
            ).order_by('spent_at')

            this_month_daily = {}
            for expense in this_month_expenses:
                day = expense.spent_at.day
                this_month_daily[day] = this_month_daily.get(day, 0) + expense.amount

            this_month_data = []
            accumulated = 0
            for day in range(1, current_day + 1):
                accumulated += this_month_daily.get(day, 0)
                this_month_data.append({"day": day, "amount": float(accumulated)})

            this_month_total = accumulated

            # 지난 달 같은 날짜까지의 누적 데이터
            prev_date = current_date - relativedelta(months=1)
            prev_expenses = Expense.objects.filter(
                user=user,
                spent_at__year=prev_date.year,
                spent_at__month=prev_date.month,
                spent_at__day__lte=current_day,
                deleted_at__isnull=True
            ).order_by('spent_at')

            prev_daily = {}
            for expense in prev_expenses:
                day = expense.spent_at.day
                prev_daily[day] = prev_daily.get(day, 0) + expense.amount

            last_month_data = []
            accumulated = 0
            for day in range(1, current_day + 1):
                accumulated += prev_daily.get(day, 0)
                last_month_data.append({"day": day, "amount": float(accumulated)})

            last_month_same_day = accumulated

            result = {
                "thisMonthTotal": this_month_total,
                "lastMonthSameDay": last_month_same_day,
                "thisMonthData": this_month_data,
                "lastMonthData": last_month_data
            }

            serializer = MonthComparisonSerializer(result)
            return Response(serializer.data, status=200)

        except Exception as e:
            return Response({"message": f"데이터 조회 실패: {str(e)}"}, status=500)
