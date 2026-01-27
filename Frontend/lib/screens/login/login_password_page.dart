import 'package:flutter/material.dart';
import 'package:my_app/services/api_service.dart';
import 'package:my_app/screens/main_navigation.dart';

class LoginPasswordPage extends StatefulWidget {
  final String phone;
  const LoginPasswordPage({super.key, required this.phone});

  @override
  State<LoginPasswordPage> createState() => _LoginPasswordPageState();
}

class _LoginPasswordPageState extends State<LoginPasswordPage> {
  final TextEditingController _pwController = TextEditingController();
  bool _obscure = true;
  String? _error;
  final RegExp _passwordRegex = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
  );

  @override
  void dispose() {
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    final text = _pwController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '비밀번호를 입력해주세요.');
      return;
    }
    if (!_passwordRegex.hasMatch(text)) {
      setState(() => _error = '비밀번호는 영문, 숫자, 특수문자를 포함한 8자 이상이어야 합니다.');
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ApiService.login(widget.phone, text);

      if (!mounted) return;
      Navigator.of(context).pop(); // 로딩 닫기

      // 메인 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // 로딩 닫기
      setState(() => _error = '로그인 실패: 다시 시도해주세요.');
      debugPrint('Login Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isValidPassword = _passwordRegex.hasMatch(
      _pwController.text.trim(),
    );
    final canProceed = isValidPassword;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '비밀번호를 입력해주세요.',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _pwController,
                obscureText: _obscure,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  hintText: '영문, 숫자, 특수문자 조합',
                  errorText: _error,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_pwController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _pwController.clear()),
                        ),
                      IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '전화번호',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    widget.phone,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF0F0F0),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canProceed ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
