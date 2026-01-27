from rest_framework import serializers


# 카테고리 매핑 (이모지, 색상, 영문명)
CATEGORY_MAPPING = {
    '식비': {'emoji': '🍽️', 'color': '#FF6B6B', 'en_name': 'food'},
    '카페/디저트': {'emoji': '☕', 'color': '#8D6E63', 'en_name': 'cafe'},
    '대중교통': {'emoji': '🚌', 'color': '#2196F3', 'en_name': 'transport'},
    '편의점': {'emoji': '🏪', 'color': '#4CAF50', 'en_name': 'shopping'},
    '온라인쇼핑': {'emoji': '🛒', 'color': '#9C27B0', 'en_name': 'shopping'},
    '대형마트': {'emoji': '🛒', 'color': '#FF9800', 'en_name': 'shopping'},
    '주유/차량': {'emoji': '⛽', 'color': '#607D8B', 'en_name': 'transport'},
    '통신/공과금': {'emoji': '📱', 'color': '#00BCD4', 'en_name': 'money'},
    '디지털구독': {'emoji': '💻', 'color': '#3F51B5', 'en_name': 'github'},
    '문화/여가': {'emoji': '🎬', 'color': '#E91E63', 'en_name': 'shopping'},
    '의료/건강': {'emoji': '💊', 'color': '#009688', 'en_name': 'shopping'},
    '교육': {'emoji': '📚', 'color': '#FFC107', 'en_name': 'shopping'},
    '뷰티/잡화': {'emoji': '💄', 'color': '#F06292', 'en_name': 'shopping'},
    '여행/숙박': {'emoji': '✈️', 'color': '#00ACC1', 'en_name': 'shopping'},
}


class DailyAccumulatedSerializer(serializers.Serializer):
    """일별 누적 데이터"""
    day = serializers.IntegerField()
    amount = serializers.FloatField()


class AccumulatedDataSerializer(serializers.Serializer):
    """월별 누적 데이터"""
    total = serializers.IntegerField()
    dailyData = DailyAccumulatedSerializer(many=True)


class DailySummarySerializer(serializers.Serializer):
    """일별 요약 (지출 합계만)"""
    expenses = serializers.DictField(child=serializers.IntegerField())


class TransactionSerializer(serializers.Serializer):
    """거래 상세 정보"""
    name = serializers.CharField()  # merchant_name
    category = serializers.CharField()  # 카테고리 영문명
    amount = serializers.IntegerField()
    currency = serializers.CharField(default='KRW')


class WeeklyDataSerializer(serializers.Serializer):
    """주간 평균"""
    average = serializers.IntegerField()


class MonthlyDataSerializer(serializers.Serializer):
    """월간 평균"""
    average = serializers.IntegerField()


class CategoryDataSerializer(serializers.Serializer):
    """카테고리별 요약"""
    name = serializers.CharField()
    emoji = serializers.CharField()
    amount = serializers.IntegerField()
    change = serializers.IntegerField()  # 전월 대비 증감액
    percent = serializers.IntegerField()  # 전체 지출 대비 비율
    color = serializers.CharField()


class MonthComparisonSerializer(serializers.Serializer):
    """월간 비교 데이터"""
    thisMonthTotal = serializers.IntegerField()
    lastMonthSameDay = serializers.IntegerField()
    thisMonthData = DailyAccumulatedSerializer(many=True)
    lastMonthData = DailyAccumulatedSerializer(many=True)
