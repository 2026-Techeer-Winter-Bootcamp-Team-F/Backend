# serializers.py
from rest_framework import serializers
from .models import Card, CardBenefit

# 카드 시리얼라이저
class CardSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()  # 절대 URL 변환용
    
    class Meta:
        model = Card 
        fields = ['card_id', 'card_name', 'image']

    def get_image(self, obj):
        """card_image_url이 상대경로일 때도 절대경로로 반환"""
        request = self.context.get('request')
        url = obj.card_image_url
        if not url:
            return None
        if request and url.startswith('/'):
            return request.build_absolute_uri(url)
        return url

# 내 카드 목록용 시리얼라이저 (카드 번호 포함)
class UserCardListSerializer(serializers.Serializer):
    """사용자 보유 카드 목록 조회용 시리얼라이저"""
    card_id = serializers.IntegerField()
    card_name = serializers.CharField()
    card_number = serializers.CharField()  # 마스킹된 카드 번호
    card_image_url = serializers.CharField()  # 카드 이미지 URL
    company = serializers.CharField()  # 카드사
    card_type = serializers.CharField(default="")  # VISA, MASTER 등 

# 추천 카드 시리얼라이저
class RecommendedCardSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()  # 절대 URL 변환용
    benefit_summary = serializers.ReadOnlyField(source='benefit_cap_summary') # 혜택 요약 매핑
    annual_fee = serializers.ReadOnlyField(source='annual_fee_domestic') # 국내 연회비 매핑
    annual_fee_international = serializers.ReadOnlyField(source='annual_fee_overseas') # 해외 연회비 매핑

    class Meta:
        model = Card
        fields = ['card_id', 'card_name', 'annual_fee', 'annual_fee_international', 
                  'company', 'image', 'benefit_summary']

    def get_image(self, obj):
        request = self.context.get('request')
        url = obj.card_image_url
        if not url:
            return None
        if request and url.startswith('/'):
            return request.build_absolute_uri(url)
        return url
        


    # 카드 및 혜택 동시 생성 처리
    def create(self, validated_data):
        # 1. Card 모델에 없는 데이터들을 먼저 분리 (pop)
        benefits_data = validated_data.pop('benefits', [])
        # card_number는 이제 UserCard에 저장할 것이므로 미리 빼둡니다.
        card_number = validated_data.pop('card_number', '') 
        
        # 2. 순수한 카드 정보(상품명, 연회비 등)만 Card 모델에 저장
        card = Card.objects.create(**validated_data)
        
        # 3. [중요] 유저와 생성된 카드를 연결 (UserCard 테이블)
        # 여기에 사용자가 입력한 '카드 번호'를 함께 저장합니다.
        from users.models import UserCard
        UserCard.objects.create(
            user=self.context['request'].user,
            card=card,
            card_number=card_number
        )

        # 4. 혜택 데이터를 순회하며 저장
        from category.models import Category 
        for benefit in benefits_data:
            category_input = benefit.pop('category')
            category_obj, _ = Category.objects.get_or_create(category_name=category_input)
            
            # 실제 CardBenefit 테이블에 연결하여 저장
            CardBenefit.objects.create(card=card, category=category_obj, **benefit)
            
        return card
