import 'package:flutter/material.dart';
import 'package:my_app/screens/cards/card_connect_page.dart';

class BankSelectionPage extends StatefulWidget {
  final String name;
  const BankSelectionPage({super.key, required this.name});

  @override
  State<BankSelectionPage> createState() => _BankSelectionPageState();
}

class _BankSelectionPageState extends State<BankSelectionPage> {
  final List<_BankItem> banks = [
    _BankItem(name: '신한카드', color: Colors.blue),
    _BankItem(name: 'BC카드', color: Colors.red),
    _BankItem(name: '국민카드', color: Colors.brown),
    _BankItem(name: '현대카드', color: Colors.black),
    _BankItem(name: '하나카드', color: Colors.teal),
    _BankItem(name: '롯데카드', color: Colors.redAccent),
  ];

  int? _selectedIndex;

  void _onSelect(int idx) {
    setState(() => _selectedIndex = idx);
  }

  void _onConnect() {
    if (_selectedIndex == null) return;

    final selectedBank = banks[_selectedIndex!];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CardConnectPage(bankName: selectedBank.name, userName: widget.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Center(child: FlutterLogo(size: 72)),
              const SizedBox(height: 24),
              const Text(
                '은행을 선택해주세요.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.builder(
                  itemCount: banks.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final b = banks[index];
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => _onSelect(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.blue.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? Colors.blue : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: b.color,
                              child: Text(
                                b.name[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(b.name, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIndex != null ? _onConnect : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF1787FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '카드사 연결하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

class _BankItem {
  final String name;
  final Color color;
  _BankItem({required this.name, required this.color});
}
