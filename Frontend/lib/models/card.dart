// [설명] 신용카드 정보를 담는 모델 클래스
// [용도] 백엔드 API에서 받아온 카드 정보를 Flutter 앱에서 사용하기 위한 객체로 변환
class CreditCard {
  final int id; // [설명] 카드 고유 ID (백엔드 card_id)
  final String name; // [설명] 카드 이름 (예: "신한Deep Dream 카드")
  final String company; // [설명] 카드 발급사 (예: "신한카드", "KB국민카드")
  final int annualFee; // [설명] 연회비 (국내)
  final String? imageUrl; // [설명] 카드 이미지 URL (백엔드에서 제공, null 가능)
  final List<CardBenefit> benefits; // [설명] 카드 혜택 리스트
  final String? cardNumber; // [추가] 카드 번호 (마스킹됨)
  final String? cardType; // [추가] 카드 타입 (신용/체크)

  CreditCard({
    required this.id,
    required this.name,
    required this.company,
    required this.annualFee,
    this.imageUrl,
    this.benefits = const [],
    this.cardNumber,
    this.cardType,
  });

  // [설명] JSON 데이터를 CreditCard 객체로 변환하는 팩토리 생성자
  // [백엔드 API 응답 필드]
  //   - card_id -> id
  //   - card_name -> name
  //   - company -> company
  //   - annual_fee -> annualFee
  //   - image -> imageUrl (백엔드 serializer에서 card_image_url을 'image'로 매핑)
  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      // [설명] 백엔드 응답의 'card_id' 필드를 id로 매핑
      id: json['card_id'] ?? json['id'] ?? 0,
      // [설명] 백엔드 응답의 'card_name' 필드를 name으로 매핑
      name: json['card_name'] ?? json['name'] ?? '',
      // [설명] 카드 발급사 정보
      company: json['company'] ?? '',
      // [설명] 연회비 정보 (기본값 0)
      annualFee: json['annual_fee'] ?? 0,
      // [중요] 백엔드에서 'image' 필드로 card_image_url을 반환하므로 'image'에서 가져옴
      // 백엔드 CardSerializer에서 card_image_url -> 'image'로 매핑됨
      imageUrl: json['image'] ?? json['card_image_url'] ?? json['image_url'],
      // [설명] 혜택 리스트 파싱 (없으면 빈 리스트)
      benefits:
          (json['benefits'] as List?)
              ?.map((b) => CardBenefit.fromJson(b))
              .toList() ??
          [],
      cardNumber: json['card_number'],
      cardType: json['card_type'],
    );
  }
}

class CardBenefit {
  final int id;
  final String category;
  final String description;
  final double discountRate;
  final int? maxDiscount;

  CardBenefit({
    required this.id,
    required this.category,
    required this.description,
    required this.discountRate,
    this.maxDiscount,
  });

  factory CardBenefit.fromJson(Map<String, dynamic> json) {
    return CardBenefit(
      id: json['id'],
      category: json['category'],
      description: json['description'],
      discountRate: (json['discount_rate'] as num).toDouble(),
      maxDiscount: json['max_discount'],
    );
  }
}

class UserCard {
  final int id;
  final CreditCard card;
  final double totalBenefitReceived;
  final double totalSpent;
  final double benefitRate;

  UserCard({
    required this.id,
    required this.card,
    required this.totalBenefitReceived,
    required this.totalSpent,
    required this.benefitRate,
  });

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      id: json['id'],
      card: CreditCard.fromJson(json['card']),
      totalBenefitReceived: (json['total_benefit_received'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      benefitRate: (json['benefit_rate'] as num).toDouble(),
    );
  }

  double get roi {
    final monthlyAnnualFee = card.annualFee / 12;
    return totalBenefitReceived - monthlyAnnualFee;
  }
}
