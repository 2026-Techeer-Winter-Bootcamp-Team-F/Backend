import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:my_app/models/consumption_analysis.dart';
import 'package:my_app/services/expense_service.dart';

class BenefitScorePage extends StatefulWidget {
  const BenefitScorePage({super.key});

  @override
  State<BenefitScorePage> createState() => _BenefitScorePageState();
}

class _BenefitScorePageState extends State<BenefitScorePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;
  bool _isBlueCardFront = false; // true면 파란 카드가 앞, false면 흰 카드가 앞
  bool _isAnimating = false; // 애니메이션 진행 중 플래그
  bool _isLoading = true;
  String? _error;

  int _benefitScore = 0;
  int _receivedBenefit = 0;
  int _missedBenefit = 0;
  String _userName = "User";
  List<CardUsage> _cards = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalysisData();

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOutCubic,
    );

    // 애니메이션 상태 감지
    _cardAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isBlueCardFront = true;
          _isAnimating = false;
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isBlueCardFront = false;
          _isAnimating = false;
        });
      }
    });
  }

  Future<void> _fetchAnalysisData() async {
    try {
      final now = DateTime.now();
      // Format current month as YYYY-MM
      final monthStr = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      final analysis = await ExpenseService().getAnalysis(monthStr);

      if (mounted) {
        setState(() {
          _benefitScore = analysis.benefitStatus.achievementRate.round();
          _receivedBenefit = analysis.benefitStatus.totalBenefitReceived;
          _missedBenefit =
              analysis.benefitStatus.maxBenefitLimit - _receivedBenefit;
          _userName = analysis.userName;
          _cards = analysis.cardsUsage;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch benefit analysis: $e");
      if (mounted) {
        setState(() {
          _error = "데이터를 불러오는데 실패했습니다.";
          _isLoading = false;
          // Fallback dummy for smooth UX or keep loading/error state?
          // Using 0 values as per init.
        });
      }
    }
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _onWhiteCardTap() {
    if (_isAnimating) return;
    // 흰 카드 탭: 파란 카드가 메인일 때만 reverse (흰 카드를 메인으로)
    if (_isBlueCardFront) {
      setState(() {
        _isAnimating = true;
      });
      _cardAnimationController.reverse();
    }
  }

  void _onBlueCardTap() {
    if (_isAnimating) return;
    // 파란 카드 탭: 흰 카드가 메인일 때만 forward (파란 카드를 메인으로)
    if (!_isBlueCardFront) {
      setState(() {
        _isAnimating = true;
      });
      _cardAnimationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_benefitScore',
                    style: const TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    '/100',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '나의 혜택 점수',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '$_userName님이 사용하시는 카드 혜택의 $_benefitScore%를 챙기고 있어요',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      '받은 혜택',
                      _receivedBenefit,
                      accent: const Color(0xFF1560FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      '놓친 혜택',
                      _missedBenefit,
                      accent: Colors.black,
                      isWarning: true,
                      note: '잠재 혜택',
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // 하단 카드: 상세 카드 + 블루 백그라운드 (홈 탭에 표시)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: _buildBottomCard(),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
      // 하단 네비게이션은 이제 `MainNavigation`에서 관리합니다.
    );
  }

  Widget _statCard(
    String title,
    int amount, {
    Color? accent,
    String? note,
    String? percentLabel,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatWon(amount),
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: accent ?? Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (percentLabel != null) ...[
                Icon(Icons.trending_up, size: 14, color: accent ?? Colors.blue),
                const SizedBox(width: 6),
                Text(
                  percentLabel,
                  style: TextStyle(fontSize: 12, color: accent ?? Colors.blue),
                ),
              ] else if (isWarning) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  note ?? '잠재 혜택',
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ] else if (note != null) ...[
                Text(
                  note,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 카드 스택 관련 UI는 더 이상 홈에 표시하지 않습니다.

  String _formatWon(int value) {
    final s = value.toString();
    final out = s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return '₩$out';
  }

  // 하단에 보여줄 큰 카드 컴포넌트 (스택된 스타일)
  Widget _buildBottomCard() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        final progress = _cardAnimation.value;

        return Center(
          child: SizedBox(
            width: 311,
            height: 387,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Stack 순서: 초기(progress=0)에는 흰 카드가 메인으로 보여야 함
                // progress < 0.5: 파란 카드(아래), 흰 카드(위) -> 흰 카드 메인
                // progress >= 0.5: 흰 카드(아래), 파란 카드(위) -> 파란 카드 메인
                if (progress < 0.5) ...[
                  // 파란 카드 (아래)
                  _buildBlueCard(progress),
                  // 흰색 카드 (위, 메인)
                  _buildWhiteCard(progress),
                ] else ...[
                  // 흰색 카드 (아래)
                  _buildWhiteCard(progress),
                  // 파란 카드 (위, 메인)
                  _buildBlueCard(progress),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWhiteCard(double progress) {
    // 흰 카드가 탭 가능한 조건: 애니메이션 중이 아닐 때
    final isWhiteCardTappable = !_isAnimating;
    final cardData = _cards.isNotEmpty ? _cards[0] : null;

    return Positioned(
      left: progress * -245, // 0에서 -245로 (왼쪽으로 사라짐, 40px만 보이게)
      top: 0,
      child: IgnorePointer(
        ignoring: !isWhiteCardTappable,
        child: GestureDetector(
          onTap: _onWhiteCardTap,
          child: Transform.scale(
            scale: 1.0 - (progress * 0.05), // 살짝 작아지는 효과
            child: _buildCard(
              color: Colors.white,
              width: 285,
              height: 377,
              topOffset: 0,
              data: cardData,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlueCard(double progress) {
    // 파란 카드가 탭 가능한 조건: 애니메이션 중이 아닐 때
    final isBlueCardTappable = !_isAnimating;
    final cardData = _cards.length > 1 ? _cards[1] : null;

    return Positioned(
      left: 26 - (progress * 26), // 26에서 0으로 (왼쪽으로 이동)
      top: 10 - (progress * 10), // 10에서 0으로
      child: IgnorePointer(
        ignoring: !isBlueCardTappable,
        child: GestureDetector(
          onTap: _onBlueCardTap,
          child: Transform.scale(
            scale: 0.95 + (progress * 0.05), // 살짝 커지는 효과
            child: _buildCard(
              color: const Color(0xFF1560FF),
              width: 311,
              height: 365 + (progress * 12), // 365에서 377로
              topOffset: 0,
              data: cardData,
            ),
          ),
        ),
      ),
    );
  }

  // 카드 컨텐츠 생성 (동일한 UI 재사용)
  Widget _buildCard({
    required Color color,
    required double width,
    required double height,
    required double topOffset,
    required CardUsage? data,
  }) {
    final isWhiteCard = color == Colors.white;

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildCardContent(isWhiteCard: isWhiteCard, data: data),
    );
  }

  // 카드 내부 컨텐츠 (흰색/파란색 카드 모두 동일)
  Widget _buildCardContent({
    required bool isWhiteCard,
    required CardUsage? data,
  }) {
    if (data == null) {
      return Center(
        child: Text(
          "카드 정보 없음",
          style: TextStyle(
            color: isWhiteCard ? Colors.black54 : Colors.white70,
            fontSize: 16,
          ),
        ),
      );
    }

    final textColor = isWhiteCard ? Colors.black : Colors.white;
    final subtitleColor = isWhiteCard ? Colors.black54 : Colors.white70;

    // 기본 이미지 (데이터가 없거나 로드 실패시 사용)
    String cardImageUrl = data.cardImage;
    if (cardImageUrl.isEmpty) {
      cardImageUrl = isWhiteCard
          ? 'https://www.shinhancard.com/pconts/images/contents/card/plate/cdCreditBOADT2.gif'
          : 'https://www.shinhancard.com/pconts/images/contents/card/plate/cdCreditBA7AQ7.gif';
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // 상단 헤더 섹션 (카드 이미지 + 제목/부제 + 꺽쇠)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 카드 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Transform.rotate(
                    angle: isWhiteCard ? 0 : math.pi,
                    child: Image.network(
                      cardImageUrl,
                      width: 160,
                      height: 101,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 160,
                          height: 101,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.credit_card,
                              color: Colors.grey,
                              size: 36,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 제목 + 꺽쇠
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        data.cardName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: isWhiteCard ? Colors.black26 : Colors.white38,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 서브타이틀
                Text(
                  '${data.company} ${data.cardNumber}',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        // 구분선 (전체 너비)
        Container(
          height: 1,
          color: isWhiteCard ? Color(0xFFF0F0F0) : Colors.white24,
        ),
        // 하단 금액 섹션
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${DateTime.now().month}월 이용금액',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatWon(data.amount),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 하단 꺽쇠
                Icon(
                  Icons.chevron_right,
                  color: isWhiteCard ? Colors.black26 : Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
