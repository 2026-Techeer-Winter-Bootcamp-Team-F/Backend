import 'package:flutter/material.dart';
import 'package:my_app/screens/home/home_page.dart';
import 'package:my_app/screens/onboarding/benefit_score_page.dart';
// '소비' 탭은 기존 `HomePage`로 이동했으므로 ExpenseAnalysisPage import는 더 이상 필요하지 않습니다.
import 'package:my_app/screens/cards/card_analysis_page.dart';
import 'package:my_app/screens/subscription/subscription_page.dart';
import 'package:my_app/screens/chat/chat_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _Conversation {
  final int id;
  final String title;
  final String lastMessage;
  final String time;

  const _Conversation({required this.id, required this.title, required this.lastMessage, required this.time});
}

// 말풍선 CustomPainter
class ChatBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // 둥근 사각형 말풍선 그리기
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.75),
      const Radius.circular(4),
    );
    path.addRRect(rect);
    
    // 말풍선 꼬리 (아래쪽 작은 삼각형)
    final tailWidth = size.width * 0.25;
    final tailHeight = size.height * 0.25;
    final tailStartX = size.width * 0.15;
    
    path.moveTo(tailStartX, size.height * 0.75);
    path.lineTo(tailStartX, size.height);
    path.lineTo(tailStartX + tailWidth, size.height * 0.75);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class ChatbotFloating extends StatefulWidget {
  final VoidCallback? onTap;

  const ChatbotFloating({super.key, this.onTap});

  @override
  State<ChatbotFloating> createState() => _ChatbotFloatingState();
}

class _ChatbotFloatingState extends State<ChatbotFloating> {
  double _xPosition = 0;
  double _yPosition = 0;
  bool _isInitialized = false;
  bool _isHidden = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final screenSize = MediaQuery.of(context).size;
      _xPosition = screenSize.width - 72; // 오른쪽 여백 16 + 위젯 크기 56
      _yPosition = screenSize.height - 184; // 하단바 위
      _isInitialized = true;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final screenSize = MediaQuery.of(context).size;
    final widgetSize = 56.0;
    final threshold = 20.0; // 모서리 근처 감지 거리
    final hideOffset = 42.0; // 숨김 시 튀어나오는 크기

    setState(() {
      // 왼쪽 가장자리 근처인지 확인
      if (_xPosition < threshold) {
        _xPosition = -hideOffset;
        _isHidden = true;
      }
      // 오른쪽 가장자리 근처인지 확인
      else if (_xPosition > screenSize.width - widgetSize - threshold) {
        _xPosition = screenSize.width - (widgetSize - hideOffset);
        _isHidden = true;
      }
      // 위쪽 가장자리 근처인지 확인
      else if (_yPosition < threshold) {
        _yPosition = -hideOffset;
        _isHidden = true;
      }
      // 아래쪽 가장자리 근처인지 확인
      else if (_yPosition > screenSize.height - widgetSize - threshold) {
        _yPosition = screenSize.height - (widgetSize - hideOffset);
        _isHidden = true;
      } else {
        _isHidden = false;
      }

      // 화면 경계 내로 제한 (완전히 숨기지 않을 때)
      if (!_isHidden) {
        _xPosition = _xPosition.clamp(0.0, screenSize.width - widgetSize);
        _yPosition = _yPosition.clamp(0.0, screenSize.height - widgetSize);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _xPosition,
      top: _yPosition,
      child: GestureDetector(
        onTap: () {
          // 숨겨진 상태면 먼저 보이게 함
          if (_isHidden) {
            final screenSize = MediaQuery.of(context).size;
            final widgetSize = 56.0;
            setState(() {
              // 가장 가까운 안전한 위치로 복귀
              if (_xPosition < 0) {
                _xPosition = 16;
              } else if (_xPosition > screenSize.width - widgetSize) {
                _xPosition = screenSize.width - widgetSize - 16;
              }
              if (_yPosition < 0) {
                _yPosition = 16;
              } else if (_yPosition > screenSize.height - widgetSize) {
                _yPosition = screenSize.height - widgetSize - 16;
              }
              _isHidden = false;
            });
          } else {
            widget.onTap?.call();
          }
        },
        onPanUpdate: (details) {
          setState(() {
            _xPosition += details.delta.dx;
            _yPosition += details.delta.dy;
            _isHidden = false;
          });
        },
        onPanEnd: _onDragEnd,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1560FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.14), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 말풍선 모양
              CustomPaint(
                size: const Size(32, 32),
                painter: ChatBubblePainter(),
              ),
              // 물음표
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatbotSheet extends StatefulWidget {
  const ChatbotSheet({super.key});

  @override
  State<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<ChatbotSheet> {
  int _selectedIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_Conversation> _allConversations = const [
    _Conversation(id: 1, title: '카드 추천 문의', lastMessage: '토스카드 추천 감사합니다!', time: '1일 전'),
    _Conversation(id: 2, title: '구독 해지 문의', lastMessage: '넷플릭스 구독 해지 방법 알려주세요', time: '3일 전'),
    _Conversation(id: 3, title: '카페 지출 문의', lastMessage: '이번달 카페 지출이 많은 것 같아요', time: '1주 전'),
  ];

  List<_Conversation> get _filteredConversations {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return _allConversations;
    return _allConversations.where((c) => c.title.contains(q) || c.lastMessage.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.86;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).viewInsets.top),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header: avatar, title, close
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.circle, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('베네핏(BeneFit)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Content area: separate Home and Conversation screens using IndexedStack
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    // Home screen
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message card
                          Container(
                            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('안녕하세요! BeneFit(베네핏)입니다 :)', style: TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                const Text('궁금한 점이 있다면 언제든 편하게 말씀해 주세요! 💬', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1560FF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text('질문하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                        SizedBox(width: 8),
                                        Icon(Icons.send, color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text('챗봇 이용중', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                          const SizedBox(height: 12),
                          // Home can have additional content below
                          const SizedBox(height: 200),
                        ],
                      ),
                    ),

                    // Conversation screen
                    Column(
                      children: [
                        // 검색창
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: '채팅 검색',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: const Color(0xFFF4F6F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredConversations.length,
                            itemBuilder: (context, idx) {
                              final c = _filteredConversations[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F7F8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.smart_toy, color: Colors.blue)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 6),
                                              Text(c.lastMessage, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        Text(c.time, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // 새 문의하기 버튼
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 6),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1560FF),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('새 질문하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  SizedBox(width: 8),
                                  Icon(Icons.send, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Bottom tab bar inside sheet (홈, 대화)
              SizedBox(
                height: 68,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedIndex = 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, color: _selectedIndex == 0 ? const Color(0xFF1560FF) : Colors.grey, size: 22),
                            const SizedBox(height: 6),
                            Text('홈', style: TextStyle(color: _selectedIndex == 0 ? const Color(0xFF1560FF) : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                          onTap: () => setState(() => _selectedIndex = 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble, color: _selectedIndex == 1 ? const Color(0xFF1560FF) : Colors.grey, size: 22),
                            const SizedBox(height: 6),
                            Text('대화', style: TextStyle(color: _selectedIndex == 1 ? const Color(0xFF1560FF) : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BenefitScorePage(),
    const HomePage(),
    const CardAnalysisPage(),
    const SubscriptionPage(),
  ];

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final bool selected = _currentIndex == index;
    final color = selected ? const Color(0xFF1560FF) : Colors.grey.shade400;

    // Use larger icon when selected for emphasis
    final iconSize = selected ? 26.0 : 22.0;
    final selectedCircleSize = 36.0;
    final labelFontSize = 11.0;
    final spacing = 4.0;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // selected 상태는 파란 원 배경에 흰 아이콘
              if (selected)
                Container(
                  width: selectedCircleSize,
                  height: selectedCircleSize,
                  decoration: const BoxDecoration(color: Color(0xFF1560FF), shape: BoxShape.circle),
                  child: Center(child: Icon(icon, color: Colors.white, size: iconSize)),
                )
              else
                Icon(icon, color: color, size: iconSize),
              SizedBox(height: spacing),
              Text(label, style: TextStyle(color: color, fontSize: labelFontSize, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Floating chatbot widget visible across all main pages
          ChatbotFloating(onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const ChatbotSheet(),
            );
          }),
        ],
      ),
      bottomNavigationBar: Container(
        width: 440,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 74,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavItem(index: 0, icon: Icons.home, label: '홈'),
            _buildNavItem(index: 1, icon: Icons.pie_chart_outline, label: '소비'),
            _buildNavItem(index: 2, icon: Icons.credit_card, label: '카드'),
            _buildNavItem(index: 3, icon: Icons.subscriptions, label: '구독'),
          ],
        ),
      ),
    );
  }
}
