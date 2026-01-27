import 'package:flutter/material.dart';
import 'package:my_app/models/card.dart';
import 'package:my_app/services/card_service.dart';
import 'package:my_app/screens/cards/card_detail_page.dart';
import 'package:my_app/screens/bank/bank_selection_page.dart';

class CardAnalysisPage extends StatefulWidget {
  const CardAnalysisPage({super.key});

  @override
  State<CardAnalysisPage> createState() => _CardAnalysisPageState();
}

class _CardAnalysisPageState extends State<CardAnalysisPage> {
  List<CreditCard> _myCards = [];
  List<CreditCard> _recommendedCards = [];
  bool _isLoading = true;

  // 카드 배경색 리스트 (순서대로 할당)
  final List<Color> _cardColors = [
    const Color(0xFFECECEC),
    const Color(0xFFEFF66A),
    const Color(0xFFF2F2F4),
    const Color(0xFFBFCFE6),
    const Color(0xFFE8EAF6),
    const Color(0xFFFFCCBC),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final cardService = CardService();
      final results = await Future.wait([
        cardService.getMyCards(),
        cardService.getRecommendedCards(),
      ]);

      if (mounted) {
        setState(() {
          _myCards = results[0];
          _recommendedCards = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Title intentionally left blank per UI request
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet stack (full width inside padding)
                _isLoading
                    ? const SizedBox(
                        height: 520,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _myCards.isEmpty
                    ? const SizedBox(
                        height: 200,
                        child: Center(child: Text("등록된 카드가 없습니다.")),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 520,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: List.generate(_myCards.length, (i) {
                            final card = _myCards[i];
                            // Keep all visible cards the same scale/size.
                            final offset =
                                i *
                                40.0; // tighten overlap so more cards are visible
                            final scale = 1.0;
                            return Positioned(
                              top: offset,
                              left: 0,
                              right: 0,
                              child: Transform.scale(
                                scale: scale,
                                alignment: Alignment.topCenter,
                                child: _buildCard(
                                  context,
                                  card,
                                  i,
                                  i == _myCards.length - 1,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                // [추가] 카드 연결 버튼
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const BankSelectionPage(name: "사용자"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_card),
                      label: const Text("카드 연결하기"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Header text like the screenshot (left-aligned)
                const Text(
                  '이 카드는 어때요?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  '소비 패턴에 따른 추천 카드입니다.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 18),

                // Recommendation sections (Dynamic)
                _buildDynamicRecommendations(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicRecommendations() {
    if (_recommendedCards.isEmpty) {
      return const Center(child: Text("추천 카드가 없습니다."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _recommendedCards
              .map((card) => _RecommendationCard(card: card))
              .toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  String _formatWon(int value) {
    final s = value.toString();
    final out = s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return '$out원';
  }

  Widget _buildCard(
    BuildContext context,
    CreditCard card,
    int index,
    bool isBottom,
  ) {
    Color cardColor = _cardColors[index % _cardColors.length];

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => CardDetailPage(card: card))),
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 20,
              child: Container(
                width: 48,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: card.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          card.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
            // optional badge on top-right
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.company,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (card.cardNumber != null)
                    Text(
                      card.cardNumber!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            if (!isBottom)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final CreditCard card;
  const _RecommendationCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: card.imageUrl != null
                  ? Image.network(
                      card.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.credit_card,
                          size: 28,
                          color: Colors.black26,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.credit_card,
                          size: 28,
                          color: Colors.black26,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  card.company,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
