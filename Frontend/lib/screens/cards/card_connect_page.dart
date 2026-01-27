import 'package:flutter/material.dart';
import 'package:my_app/services/card_service.dart';
import 'package:my_app/screens/login/signup_complete_page.dart';

class CardConnectPage extends StatefulWidget {
  final String bankName;
  final String userName;

  const CardConnectPage({
    super.key,
    required this.bankName,
    required this.userName,
  });

  @override
  State<CardConnectPage> createState() => _CardConnectPageState();
}

class _CardConnectPageState extends State<CardConnectPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _identityController =
      TextEditingController(); // 주민번호/생년월일

  bool _obscurePw = true;
  bool _isLoading = false;
  String? _error;

  final CardService _cardService = CardService();

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    _identityController.dispose();
    super.dispose();
  }

  Future<void> _onConnect() async {
    if (_idController.text.isEmpty || _pwController.text.isEmpty) {
      setState(() => _error = '아이디와 비밀번호를 모두 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // organization 코드는 실제로는 은행별로 다름.
      // 여기서는 데모용으로 입력받거나 매핑해야 함.
      // 간단히 예시 코드 '0001' (신한카드 등) 등으로 하드코딩하거나 매핑 필요.
      // 프로젝트 문맥상 'organization'은 CodeF 기관코드.
      // 일단 bankName을 기반으로 매핑하거나, 더미로 '0309'(코드에프 예제) 사용 등.
      // 유저가 "카드 등록 기능이 제거되었다, 다시 추가해"라고 했으므로,
      // 실제 작동하는 로직을 위해서는 올바른 기관코드가 필요함.
      String orgCode = _getOrgCode(widget.bankName);

      // CardService.createConnectedId 호출
      final result = await _cardService.createConnectedId(
        organization: orgCode,
        loginType: '1', // ID/PW 방식
        cardId: _idController.text,
        password: _pwController.text,
        identity: _identityController.text,
      );

      // 성공 시
      if (!mounted) return;

      // 카드 목록 동기화 요청
      try {
        String connectedId = result['connected_id'];

        // 1. Codef 토큰 발급
        String codefToken = await _cardService.getCodefToken();

        // 2. 카드 목록 동기화
        await _cardService.getCardList(orgCode, connectedId, codefToken);
      } catch (e) {
        print('카드 동기화 실패 (계속 진행): $e');
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SignupCompletePage(name: widget.userName),
        ),
      );
    } catch (e) {
      setState(
        () => _error = '연동 실패: ${e.toString().replaceAll("Exception:", "")}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getOrgCode(String name) {
    // 실제 CodeF 기관 코드 매핑 필요
    switch (name) {
      case '신한카드':
        return '0309';
      case '국민카드':
        return '0306';
      case '현대카드':
        return '0304';
      case '삼성카드':
        return '0301';
      case '롯데카드':
        return '0303';
      case '우리카드':
        return '0313';
      case '하나카드':
        return '0310';
      case 'BC카드':
        return '0301'; // 예시
      default:
        return '0309'; // Default 신한
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.bankName} 연결'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: '아이디',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pwController,
                obscureText: _obscurePw,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePw ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscurePw = !_obscurePw),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 주민번호 앞 7자리 등 추가 정보가 필요할 수 있음 (선택)
              TextField(
                controller: _identityController,
                decoration: const InputDecoration(
                  labelText: '주민번호 앞 7자리 (생년월일6자리+성별1자리)',
                  border: OutlineInputBorder(),
                  hintText: '예: 0201043',
                ),
                keyboardType: TextInputType.number,
                maxLength: 7,
              ),

              const SizedBox(height: 32),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onConnect,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('연동하기', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
