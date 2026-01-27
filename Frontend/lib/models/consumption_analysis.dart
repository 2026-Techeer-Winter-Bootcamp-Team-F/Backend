class ConsumptionAnalysis {
  final int userId;
  final String userName;
  final ComparisonData comparison;
  final BenefitStatus benefitStatus;
  final List<CardUsage> cardsUsage;

  ConsumptionAnalysis({
    required this.userId,
    required this.userName,
    required this.comparison,
    required this.benefitStatus,
    required this.cardsUsage,
  });

  factory ConsumptionAnalysis.fromJson(Map<String, dynamic> json) {
    var list = json['cards_usage'] as List? ?? [];
    List<CardUsage> usageList = list.map((i) => CardUsage.fromJson(i)).toList();

    return ConsumptionAnalysis(
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'User',
      comparison: ComparisonData.fromJson(json['comparison'] ?? {}),
      benefitStatus: BenefitStatus.fromJson(json['benefit_status'] ?? {}),
      cardsUsage: usageList,
    );
  }
}

class CardUsage {
  final String cardName;
  final String cardNumber;
  final String cardImage;
  final String company;
  final int amount;

  CardUsage({
    required this.cardName,
    required this.cardNumber,
    required this.cardImage,
    required this.company,
    required this.amount,
  });

  factory CardUsage.fromJson(Map<String, dynamic> json) {
    return CardUsage(
      cardName: json['card_name'] ?? 'Unknown Card',
      cardNumber: json['card_number'] ?? '',
      cardImage: json['card_image'] ?? '',
      company: json['company'] ?? '',
      amount: json['amount'] ?? 0,
    );
  }
}

class ComparisonData {
  final int myTotalSpent;
  final int groupAvgSpent;
  final double diffPercent;
  final int percentile;

  ComparisonData({
    required this.myTotalSpent,
    required this.groupAvgSpent,
    required this.diffPercent,
    required this.percentile,
  });

  factory ComparisonData.fromJson(Map<String, dynamic> json) {
    return ComparisonData(
      myTotalSpent: json['my_total_spent'] ?? 0,
      groupAvgSpent: json['group_avg_spent'] ?? 0,
      diffPercent: (json['diff_percent'] ?? 0).toDouble(),
      percentile: json['percentile'] ?? 0,
    );
  }
}

class BenefitStatus {
  final int totalBenefitReceived;
  final int maxBenefitLimit;
  final double achievementRate;

  BenefitStatus({
    required this.totalBenefitReceived,
    required this.maxBenefitLimit,
    required this.achievementRate,
  });

  factory BenefitStatus.fromJson(Map<String, dynamic> json) {
    return BenefitStatus(
      totalBenefitReceived: json['total_benefit_received'] ?? 0,
      maxBenefitLimit:
          json['max_benefit_limit'] ?? 100, // avoid division by zero
      achievementRate: (json['achievement_rate'] ?? 0).toDouble(),
    );
  }
}
