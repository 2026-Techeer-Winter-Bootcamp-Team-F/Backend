// lib/services/card_service.dart
// [설명] 백엔드 카드 API와 통신하는 서비스 클래스
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/card.dart';
import 'package:my_app/services/api_service.dart';

class CardService {
  static final String baseUrl = ApiService.baseUrl;

  // [설명] 인증 토큰을 포함한 HTTP 헤더 생성 헬퍼 메서드
  // [용도] API 요청 시 JWT 토큰을 Authorization 헤더에 포함
  Future<Map<String, String>> get _headers async {
    final token = await ApiService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // [설명] 사용자가 등록한 카드 목록 조회
  // [API 엔드포인트] GET /api/v1/cards/
  // [백엔드 응답 형식]
  // {
  //   "message": "내 카드 목록 조회 성공",
  //   "cards": [
  //     {
  //       "card_id": 1,
  //       "card_name": "신한Deep Dream 카드",
  //       "card_image_url": "https://...",  // 백엔드 DB에 저장된 이미지 URL
  //       "company": "신한카드",
  //       "card_number": "**** 1234"
  //     }
  //   ]
  // }
  Future<List<CreditCard>> getMyCards() async {
    final headers = await _headers;
    // [설명] 백엔드 카드 목록 API 호출
    final response = await http.get(
      Uri.parse('$baseUrl/cards/'),
      headers: headers,
    );

    print('[CardService] getMyCards 응답: ${response.statusCode}');
    print('[CardService] 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        // [설명] 응답의 'cards' 배열을 CreditCard 객체 리스트로 변환
        // 각 카드 객체에는 백엔드에서 제공하는 이미지 URL이 포함됨
        return (data['cards'] as List)
            .map((card) => CreditCard.fromJson(card))
            .toList();
      } catch (e) {
        print('[CardService] JSON 파싱 에러: $e');
        throw Exception('카드 데이터 파싱 실패: $e');
      }
    } else if (response.statusCode == 401) {
      // [설명] 인증 실패 시 에러 처리
      throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
    } else {
      // [설명] 기타 에러 처리
      throw Exception('카드 목록 조회 실패: ${response.statusCode} - ${response.body}');
    }
  }

  // [설명] 추천 카드 목록 조회 (사용자 소비 패턴 기반)
  // [API 엔드포인트] GET /api/v1/cards/recommend/
  // [백엔드 응답] 최근 3개월 소비가 많은 카테고리에 혜택이 높은 카드 반환
  Future<List<CreditCard>> getRecommendedCards() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/cards/recommend/'),
      headers: headers,
    );

    print('[CardService] getRecommendedCards 응답: ${response.statusCode}');
    print('[CardService] 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        // [설명] 추천 카드 리스트 파싱 (각 카드에 이미지 URL 포함)
        return (data['recommended_cards'] as List)
            .map((card) => CreditCard.fromJson(card))
            .toList();
      } catch (e) {
        print('[CardService] JSON 파싱 에러: $e');
        throw Exception('추천 카드 데이터 파싱 실패: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
    } else if (response.statusCode == 404) {
      // [수정] 지출 데이터가 없으면 빈 리스트 반환 (에러 대신)
      print('[CardService] 지출 데이터가 없어서 추천 카드가 없습니다.');
      return [];
    } else {
      throw Exception('추천 카드 조회 실패: ${response.statusCode} - ${response.body}');
    }
  }

  // [추가] 혜택 분석 데이터 조회
  Future<Map<String, dynamic>> getBenefitAnalysis() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/cards/benefit_analysis/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load benefit analysis');
    }
  }

  // [추가] Codef Token 발급
  Future<String> getCodefToken() async {
    // 토큰 발급은 인증 없이 가능할 수도 있지만, 보통은 서버에서 처리하므로 인증 헤더 불필요할 수도 있음.
    // 하지만 CodefAPIService 호출하는 뷰는 권한 체크를 AllowAny로 설정했으므로 헤더 없어도 됨.
    // 다만 _headers 헬퍼를 쓰면 토큰이 있는 경우 보냄.
    final headers = await _headers;
    final response = await http.post(
      Uri.parse('$baseUrl/codef/token/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['access_token'];
      }
    }
    throw Exception('Failed to get Codef token');
  }

  // [추가] Connected ID 생성
  Future<Map<String, dynamic>> createConnectedId({
    required String organization,
    required String loginType,
    required String cardId,
    required String password,
    String? identity,
  }) async {
    final headers = await _headers;
    final Map<String, dynamic> bodyMap = {
      'organization': organization,
      'login_type': loginType,
      'card_id': cardId,
      'password': password,
    };
    if (identity != null && identity.isNotEmpty) {
      bodyMap['identity'] = identity;
    }
    final body = json.encode(bodyMap);

    final response = await http.post(
      Uri.parse('$baseUrl/codef/connected-id/create/'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create connected ID');
      }
    }

    // 에러 응답 파싱 시도
    try {
      final errorData = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(
        errorData['error_message'] ??
            'Failed to create connected ID: ${response.statusCode}',
      );
    } catch (e) {
      if (e.toString().contains('Failed to create')) rethrow;
      throw Exception('Failed to create connected ID: ${response.statusCode}');
    }
  }

  // [추가] 카드 목록 조회 (Codef 연동)
  Future<void> getCardList(
    String organization,
    String connectedId,
    String codefToken,
  ) async {
    final headers = await _headers;
    headers['X-Codef-Token'] = codefToken;

    final body = json.encode({
      'organization': organization,
      'connected_id': connectedId,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/codef/card/list/'),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync card list');
    }
  }

  // [추가] 승인 내역 조회 (Codef 연동)
  Future<void> getApprovalList(
    String organization,
    String connectedId,
    String codefToken,
    String startDate,
    String endDate,
  ) async {
    final headers = await _headers;
    final body = json.encode({
      'organization': organization,
      'connectedId': connectedId,
      'startDate': startDate,
      'endDate': endDate,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/codef/card/approval/'),
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync approval list');
    }
  }

  // [추가] 청구 내역 조회 (Codef 연동)
  Future<void> getBillingList(
    String organization,
    String connectedId,
    String codefToken,
  ) async {
    final headers = await _headers;
    final body = json.encode({
      'organization': organization,
      'connectedId': connectedId,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/codef/card/billing/'),
      headers: headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to sync billing list');
    }
  }
}
