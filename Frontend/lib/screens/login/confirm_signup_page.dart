import 'package:flutter/material.dart';
import 'package:my_app/screens/login/verification_code_page.dart';

class ConfirmSignupPage extends StatefulWidget {
  final String name;
  final String ssnFront;
  final String ssnBackFirst; // 실제 입력된 1자리
  final String carrier;
  const ConfirmSignupPage({
    super.key,
    required this.name,
    required this.ssnFront,
    required this.ssnBackFirst,
    required this.carrier,
  });

  @override
  State<ConfirmSignupPage> createState() => _ConfirmSignupPageState();
}

class _ConfirmSignupPageState extends State<ConfirmSignupPage> {
  final TextEditingController _phoneController = TextEditingController();
  late String _carrier;
  final List<String> _carriers = [
    'SKT',
    'KT',
    'LG U+',
    'SKT 알뜰폰',
    'KT 알뜰폰',
    'LG U+ 알뜰폰',
  ];

  bool get _phoneValid => RegExp(r'^\d{10,11}$').hasMatch(_phoneController.text.trim());
  bool get _canProceed => _phoneValid;

  @override
  void initState() {
    super.initState();
    _carrier = widget.carrier;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onComplete() {
    if (!_canProceed) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationCodePage(phone: _phoneController.text.trim(), name: widget.name),
      ),
    );
  }

  Widget _maskedSsnRow() {
    return Row(
      children: [
        Text(widget.ssnFront, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        const Text('-', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(widget.ssnBackFirst, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Row(
          children: List.generate(6, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: Colors.grey.shade500, shape: BoxShape.circle),
              ),
            );
          }),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(ThemeData theme) {
    return InputDecoration(
      hintText: '',
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                '휴대폰 번호를 입력해주세요.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration(theme).copyWith(hintText: '01012345678'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              const Text('통신사', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _carrier,
                items: _carriers.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _carrier = v ?? _carrier),
                decoration: _fieldDecoration(theme),
                icon: const Icon(Icons.arrow_drop_down),
              ),
              const SizedBox(height: 18),
              const Text('주민등록번호', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              _maskedSsnRow(),
              const SizedBox(height: 18),
              const Text('이름', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed ? _onComplete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1787FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('내 명의의 휴대폰이 아닙니다', style: TextStyle(color: Colors.grey)),
                      SizedBox(width: 6),
                      Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
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