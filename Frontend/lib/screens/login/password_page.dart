import 'package:flutter/material.dart';
import 'package:my_app/screens/bank/bank_selection_page.dart';

class PasswordPage extends StatefulWidget {
  final String phone;
  final String name;
  const PasswordPage({super.key, required this.phone, required this.name});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> with SingleTickerProviderStateMixin {
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  String? _pwError;
  String? _confirmError;
  bool _showConfirmField = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final RegExp _pwRule = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 80.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _pwController.dispose();
    _confirmController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _validatePw(String v) {
    if (v.isEmpty) {
      _pwError = null;
    } else {
      _pwError = _pwRule.hasMatch(v) ? null : '영문, 숫자, 특수문자 조합 (최소 8자)';
    }
    if (_showConfirmField) _validateConfirm(_confirmController.text);
    setState(() {});
  }

  void _validateConfirm(String v) {
    if (v.isEmpty) {
      _confirmError = null;
    } else if (!_pwRule.hasMatch(v)) {
      _confirmError = '영문, 숫자, 특수문자 조합 (최소 8자)';
    } else if (v != _pwController.text) {
      _confirmError = '입력한 비밀번호와 일치하지 않습니다.';
    } else {
      _confirmError = null;
    }
    setState(() {});
  }

  bool get _canProceedInitial {
    return _pwController.text.isNotEmpty && _pwError == null && _pwRule.hasMatch(_pwController.text);
  }

  bool get _canComplete {
    return _confirmController.text.isNotEmpty && _confirmError == null && _pwRule.hasMatch(_confirmController.text) && _confirmController.text == _pwController.text;
  }

  void _onNext() {
    if (!_canProceedInitial) return;
    setState(() {
      _showConfirmField = true;
    });
    _animationController.forward();
  }

  void _onComplete() {
    if (!_canComplete) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BankSelectionPage(name: widget.name)),
    );
  }

  InputDecoration _buildDecoration({
    required ThemeData theme,
    String? hint,
    String? error,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: null,
      errorText: error,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _showConfirmField ? '비밀번호를 재입력해주세요.' : '최소 8자리 이상\n비밀번호를 입력해주세요.',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 18),

                  // 비밀번호 재확인 필드 (애니메이션)
                  if (_showConfirmField) ...[
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('비밀번호 재확인', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            onChanged: _validateConfirm,
                            decoration: _buildDecoration(
                              theme: theme,
                              hint: '영문, 숫자, 특수문자 조합',
                              error: _confirmError,
                              suffix: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_confirmController.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () => setState(() => _confirmController.clear()),
                                    ),
                                  IconButton(
                                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ],

                  // 비밀번호 입력 필드 (이동 애니메이션)
                  Transform.translate(
                    offset: Offset(0, _showConfirmField ? _slideAnimation.value : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('비밀번호', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pwController,
                          obscureText: _obscurePw,
                          onChanged: _validatePw,
                          decoration: _buildDecoration(
                            theme: theme,
                            hint: '영문, 숫자, 특수문자 조합',
                            error: _pwError,
                            suffix: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_pwController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => setState(() => _pwController.clear()),
                                  ),
                                IconButton(
                                  icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showConfirmField 
                          ? (_canComplete ? _onComplete : null)
                          : (_canProceedInitial ? _onNext : null),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('확인'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}