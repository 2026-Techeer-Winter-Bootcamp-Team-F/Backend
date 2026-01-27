import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/services/api_service.dart';

class ChatService {
  static const String baseUrl = ApiService.baseUrl;

  Future<Map<String, String>> get _headers async {
    final token = await ApiService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // 1. 메시지 전송 및 AI 응답 받기
  Future<Map<String, dynamic>> sendMessage(String message) async {
    final headers = await _headers;
    final url = Uri.parse('$baseUrl/chat/api/chat/');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data;
      } else {
        throw Exception('메시지 전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('채팅 서비스 오류: $e');
    }
  }

  // 2. 채팅 내역 조회
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final headers = await _headers;
    final url = Uri.parse('$baseUrl/chat/api/chat/');

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('채팅 기록 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('채팅 기록 로드 오류: $e');
    }
  }
}
