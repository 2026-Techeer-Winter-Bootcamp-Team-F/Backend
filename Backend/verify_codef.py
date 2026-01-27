import os
import requests
import json
import base64
import urllib.parse
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

def verify_codef_credentials():
    print("=== Codef API 자격증명 및 연결 검증 스크립트 ===")
    
    # 1. 환경변수 확인
    client_id = os.getenv('CODEF_CLIENT_ID')
    client_secret = os.getenv('CODEF_CLIENT_SECRET')
    access_token = os.getenv('ACCESS_TOKEN')
    connected_id = os.getenv('CONNECT_ID') # .env에는 CONNECT_ID로 저장되어 있음

    print(f"\n[1] 환경 변수 확인:")
    print(f"  - CODEF_CLIENT_ID: {'설정됨' if client_id else '없음 (심각: 토큰 재발급 불가)'}")
    print(f"  - CODEF_CLIENT_SECRET: {'설정됨' if client_secret else '없음 (심각: 토큰 재발급 불가)'}")
    print(f"  - ACCESS_TOKEN: {'설정됨' if access_token else '없음'}")
    print(f"  - CONNECT_ID: {'설정됨' if connected_id else '없음'}")

    # 2. 토큰 발급 테스트 (Client Credentials Flow)
    new_token = None
    if client_id and client_secret:
        print(f"\n[2] 새로운 토큰 발급 테스트 (Client ID/Secret 사용):")
        try:
            url = "https://oauth.codef.io/oauth/token"
            auth_str = f"{client_id}:{client_secret}"
            auth_b64 = base64.b64encode(auth_str.encode('utf-8')).decode('utf-8')
            
            headers = {
                "Authorization": f"Basic {auth_b64}",
                "Content-Type": "application/x-www-form-urlencoded"
            }
            data = {
                "grant_type": "client_credentials",
                "scope": "read"
            }
            
            response = requests.post(url, headers=headers, data=data)
            
            if response.status_code == 200:
                result = response.json()
                new_token = result.get('access_token')
                print("  ✓ 토큰 발급 성공!")
                print(f"  ✓ 발급된 토큰: {new_token[:20]}...")
            else:
                print(f"  ✗ 토큰 발급 실패. 상태 코드: {response.status_code}")
                print(f"  ✗ 응답: {response.text}")
        except Exception as e:
            print(f"  ✗ 에러 발생: {e}")
    else:
        print("\n[2] Client ID/Secret 없음. 토큰 발급 테스트 건너뜀.")

    # 3. 기존 토큰 유효성 테스트 (Connected ID 정보 조회 등)
    token_to_use = access_token if access_token else new_token
    
    if token_to_use and connected_id:
        print(f"\n[3] Connected ID 연결 테스트 (토큰 및 Connected ID 사용):")
        try:
            # 커넥티드 아이디 목록 조회 (또는 간단한 조회)
            # Codef 엔드포인트: /v1/account/list
            url = "https://api.codef.io/v1/account/list"
            
            headers = {
                "Authorization": f"Bearer {token_to_use}",
                "Content-Type": "application/json"
            }
            
            # body에 connectedId 포함
            body = {
                "connectedId": connected_id
            }
            
            response = requests.post(url, headers=headers, json=body)
            
            print(f"  - 요청 URL: {url}")
            print(f"  - 상태 코드: {response.status_code}")
            
            try:
                # URL Decoding 로직 추가
                response_text = response.text
                if response_text.startswith('%7B') or '%22' in response_text:
                    decoded_text = urllib.parse.unquote_plus(response_text)
                    res_json = json.loads(decoded_text)
                    print(f"  - 응답 본문 (Decoded): {json.dumps(res_json, indent=2, ensure_ascii=False)}")
                else:
                    res_json = response.json()
                    print(f"  - 응답 본문: {json.dumps(res_json, indent=2, ensure_ascii=False)}")
                
                result_code = res_json.get('result', {}).get('code')
                result_msg = res_json.get('result', {}).get('message')
                
                if result_code == 'CF-00000':
                    print("  ✓ Connected ID 조회 성공! (자격증명 유효함)")
                else:
                    print(f"  ✗ API 호출 실패 코드: {result_code}")
                    print(f"  ✗ 메시지: {result_msg}")
                    analyze_error_code(result_code, result_msg)
                    
            except json.JSONDecodeError:
                print(f"  ✗ 응답이 JSON이 아님: {response.text}")
                
        except Exception as e:
            print(f"  ✗ 연결 테스트 중 에러: {e}")
    else:
        print("\n[3] 토큰 또는 Connected ID가 없어 연결 테스트를 수행할 수 없습니다.")

def analyze_error_code(code, msg):
    print("\n[!] 에러 분석:")
    if code == 'CF-00401':
        print("  - 토큰이 유효하지 않습니다. (만료되었거나 잘못됨)")
        print("  - 해결: 새로운 토큰을 발급받아 .env의 ACCESS_TOKEN을 갱신하세요.")
    elif code == 'CF-03002':
        print("  - 추가 인증이 필요합니다.")
    elif code == 'CF-01001':
        print("  - 해당 리소스에 접근 권한이 없습니다.")
    elif 'CF-12' in code:
         print("  - 계정/비밀번호 오류 또는 은행 사이트 접속 문제입니다.")
    else:
        print("  - Codef 기술지원 문서를 참고하거나, Client ID/Secret 권한을 확인하세요.")

if __name__ == "__main__":
    verify_codef_credentials()
