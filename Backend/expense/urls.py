from django.urls import path
from .views import (
    ConsumptionPatternAnalysisView,  # [설명] 소비 패턴 분석 뷰
    DeleteSubscription,  # [설명] 구독 삭제 뷰
    ShowSubscription,  # [설명] 구독 목록 조회 뷰
    ShowExpense,  # [설명] 월간 지출 내역 조회 뷰
    # 홈화면용 신규 API
    AccumulatedDataView,
    DailySummaryView,
    DailyDetailView,
    WeeklyAverageView,
    MonthlyAverageView,
    CategorySummaryView,
    MonthComparisonView,
)

urlpatterns = [

    # 소비 패턴 분석 (예: /api/analysis/?month=2026-01)
    path('analysis/', ConsumptionPatternAnalysisView.as_view(), name='consumption-analysis'),  # [설명] 소비 패턴 분석
    
    # 지출 내역 조회 (예: /api/expenses/?month=2026-01)
    path('expenses/', ShowExpense.as_view(), name='show-expense'),  # [설명] 월간 지출 내역 조회
    
    # 구독 목록 조회 및 삭제
    path('subscriptions/', ShowSubscription.as_view(), name='show-subscription'),  # [설명] 구독 목록 조회
    path('subscriptions/<int:subs_id>/', DeleteSubscription.as_view(), name='delete-subscription'),  # [설명] 구독 단건 삭제
    
    # ==================== 홈화면용 신규 API ====================
    # 1. 누적 데이터
    path('transactions/accumulated', AccumulatedDataView.as_view(), name='accumulated-data'),
    
    # 2. 일별 요약
    path('transactions/daily-summary', DailySummaryView.as_view(), name='daily-summary'),
    
    # 3. 일별 상세
    path('transactions/daily-detail', DailyDetailView.as_view(), name='daily-detail'),
    
    # 4. 주간 평균
    path('transactions/weekly-average', WeeklyAverageView.as_view(), name='weekly-average'),
    
    # 5. 월간 평균
    path('transactions/monthly-average', MonthlyAverageView.as_view(), name='monthly-average'),
    
    # 6. 카테고리 요약
    path('transactions/category-summary', CategorySummaryView.as_view(), name='category-summary'),
    
    # 7. 월간 비교
    path('transactions/month-comparison', MonthComparisonView.as_view(), name='month-comparison'),
]
