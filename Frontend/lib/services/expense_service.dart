import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/consumption_analysis.dart';
import 'package:my_app/services/api_service.dart';

class ExpenseService {
  static const String baseUrl = ApiService.baseUrl;

  Future<Map<String, String>> get _headers async {
    final token = await ApiService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // 소비 패턴 분석 데이터 조회
  Future<ConsumptionAnalysis> getAnalysis(String month) async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/expense/analysis/?month=$month'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return ConsumptionAnalysis.fromJson(jsonResponse['result']);
    } else {
      throw Exception(
        'Failed to load consumption analysis: ${response.statusCode}',
      );
    }
  }
}
