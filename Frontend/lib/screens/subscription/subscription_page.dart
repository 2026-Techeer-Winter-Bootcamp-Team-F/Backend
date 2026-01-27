import 'package:flutter/material.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  // Sample data used for previewing the UI. In the real app this should
  // come from your backend / state management layer.
  static final List<_SubscriptionItem> _sample = [
    _SubscriptionItem(name: '넷플릭스', amount: 13000, daysLeft: 21, color: Color(0xFFe50914), icon: Icons.play_circle_fill),
    _SubscriptionItem(name: '유튜브 프리미엄', amount: 20000, daysLeft: 15, color: Color(0xFFFF0000), icon: Icons.ondemand_video),
    _SubscriptionItem(name: '제미나이', amount: 3000, daysLeft: 10, color: Color(0xFF2D9CDB), icon: Icons.star),
    _SubscriptionItem(name: '네이버플러스', amount: 4000, daysLeft: 15, color: Color(0xFF03C75A), icon: Icons.check_circle),
    _SubscriptionItem(name: '듀오링고', amount: 12500, daysLeft: 20, color: Color(0xFF72D22F), icon: Icons.school),
    _SubscriptionItem(name: '챗GPT플러스', amount: 33500, daysLeft: 17, color: Color(0xFF000000), icon: Icons.smart_toy),
    _SubscriptionItem(name: '알바몬', amount: 5000, daysLeft: 13, color: Color(0xFF8A4FFF), icon: Icons.local_offer),
    _SubscriptionItem(name: '쿠팡이츠', amount: 7500, daysLeft: 20, color: Color(0xFFFF8A00), icon: Icons.delivery_dining),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SpeechBubble(
                              text: '내가 구독한 서비스가 뭐더라?',
                              tailAlignment: TailAlignment.left,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SpeechBubble(
                              text: '내게 꼭 필요한 걸까?',
                              tailAlignment: TailAlignment.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      '🧐',
                      style: TextStyle(fontSize: 220),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.02,
                children: _sample.map((s) => SubscriptionCard(item: s)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TailAlignment { left, right }

class SpeechBubble extends StatelessWidget {
  final String text;
  final TailAlignment tailAlignment;

  const SpeechBubble({super.key, required this.text, this.tailAlignment = TailAlignment.left});

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

    final triangle = CustomPaint(
      size: const Size(18, 12),
      painter: _TrianglePainter(color: const Color(0xFFF2F4F5), alignLeft: tailAlignment == TailAlignment.left),
    );

    if (tailAlignment == TailAlignment.left) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bubble,
          Transform.translate(offset: const Offset(12, -6), child: triangle),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bubble,
        Transform.translate(offset: const Offset(-12, -6), child: triangle),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool alignLeft;

  _TrianglePainter({required this.color, this.alignLeft = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (alignLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simple local model used only for the preview grid in this file.
class _SubscriptionItem {
  final String name;
  final int amount;
  final int daysLeft;
  final Color color;
  final IconData icon;

  const _SubscriptionItem({required this.name, required this.amount, required this.daysLeft, required this.color, required this.icon});
}

class SubscriptionCard extends StatelessWidget {
  final _SubscriptionItem item;

  const SubscriptionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F9),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item.color,
                radius: 22,
                child: Icon(item.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(fontSize: 13, color: Color(0xFF2F3A45), fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _formatAmount(item.amount),
                style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            '${item.daysLeft}일',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2F3A45)),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    // simple thousands separator
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${s.replaceAllMapped(reg, (m) => ',')}원';
  }
}
