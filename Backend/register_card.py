import os
import requests
import json
import base64
import urllib.parse
import rsa
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

# ==========================================
# 1. 설정 정보
# ==========================================
CLIENT_ID = os.getenv('CODEF_CLIENT_ID')
CLIENT_SECRET = os.getenv('CODEF_CLIENT_SECRET')

# Codef API 도메인
BASE_URL = "https://api.codef.io"

def get_access_token():
    env_token = os.getenv('ACCESS_TOKEN')
    if env_token:
        # 토큰 유효성 간단 체크 (길이 등)
        if len(env_token) > 20: 
            return env_token

    print("토큰 새로 발급 중...")
    url = "https://oauth.codef.io/oauth/token"
    auth_str = f"{CLIENT_ID}:{CLIENT_SECRET}"
    auth_b64 = base64.b64encode(auth_str.encode('utf-8')).decode('utf-8')
    
    headers = {
        'Authorization': f'Basic {auth_b64}',
        'Content-Type': 'application/x-www-form-urlencoded'
    }
    data = {'grant_type': 'client_credentials', 'scope': 'read'}
    
    try:
        res = requests.post(url, headers=headers, data=data)
        if res.status_code == 200:
            return res.json().get('access_token')
        print(f"토큰 발급 실패: {res.text}")
    except Exception as e:
        print(f"토큰 요청 중 에러: {e}")
    return None

def encrypt_data(public_key_str, data):
    try:
        # 1. 공개키 로딩
        key_der = base64.b64decode(public_key_str)
        public_key = rsa.PublicKey.load_pkcs1_openssl_der(key_der)
        
        # 2. 데이터 암호화
        encrypted_data = rsa.encrypt(data.encode('utf-8'), public_key)
        
        # 3. Base64 인코딩
        return base64.b64encode(encrypted_data).decode('utf-8')
    except Exception as e:
        raise Exception(f"Encryption failed: {e}")

def register_card_rsa():
    print("=== Codef 카드 등록 (RSA 암호화 / 새 ID 생성) ===")
    
    token = get_access_token()
    if not token: return
    
    # .env에서 키 로드 및 공백 제거
    raw_public_key = os.getenv('CODEF_CLIENT_PUBLIC', '').replace('\n', '').replace('\r', '').strip()
    if not raw_public_key:
        print("Error: .env에 CODEF_CLIENT_PUBLIC이 없습니다.")
        return
        
    print(f" 토큰: {token[:10]}...")
    print(f" 공개키 로드 (길이: {len(raw_public_key)})")

    # 입력
    print("\n[ 카드사 정보 입력 ]")
    org_code = input("기관코드 (신한:0306, 국민:0301): ").strip()
    user_id = input("아이디: ").strip()
    user_pw = input("비밀번호: ").strip()
    user_identity = input("주민번호 7자리 (생년월일+성별, 필수): ").strip()
    
    # 옵션: ID 암호화 여부 및 카드번호 입력 제어
    print("\n[ (선택) 카드번호/비번 앞2자리 ]")
    print("※ 팁: 실패 시 카드번호 없이 ID/비번만으로 먼저 시도해보세요.")
    card_no = input("카드번호 (엔터치면 생략): ").strip()
    card_pw = ""
    if card_no:
        card_pw = input("비번 앞2자리: ").strip()

    encrypt_id_choice = input("\n['아이디'도 암호화 하시겠습니까?] (y/n, 엔터=y): ").strip().lower()
    should_encrypt_id = (encrypt_id_choice != 'n')

    # 암호화 수행
    try:
        # ID 암호화 선택적 적용
        if should_encrypt_id:
            final_id = encrypt_data(raw_public_key, user_id)
        else:
            final_id = user_id
            
        final_pw = encrypt_data(raw_public_key, user_pw)
        final_identity = encrypt_data(raw_public_key, user_identity)
        
        final_card_pw = None
        if card_pw:
            final_card_pw = encrypt_data(raw_public_key, card_pw)

    except Exception as e:
        print(f"암호화 준비 중 에러: {e}")
        return

    # Payload 구성
    account = {
        "countryCode": "KR",
        "businessType": "CD",
        "clientType": "P",
        "organization": org_code,
        "loginType": "1",
        "id": final_id,
        "password": final_pw,
        "identity": final_identity
    }
    
    if card_no: account["cardNo"] = card_no
    if final_card_pw: account["cardPassword"] = final_card_pw

    payload = {
        "accountList": [account]
    }

    url = f"{BASE_URL}/v1/account/create"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    print("\n⏳ 등록 요청 중 (RSA 암호화 전송)...")
    try:
        res = requests.post(url, headers=headers, json=payload, timeout=90)
        
        # URL Decoding
        resp_text = res.text
        if resp_text.startswith('%7B') or '%22' in resp_text:
             resp_text = urllib.parse.unquote_plus(resp_text)
        
        print("\n=== 결과 ===")
        print(resp_text) # 원본 JSON 문자열 출력 (디버깅용)
        
        data = json.loads(resp_text)
        result = data.get('result', {})
        
        if result.get('code') == 'CF-00000':
            new_id = data.get('data', {}).get('connectedId')
            print(f"\n🎉 성공! Connected ID: {new_id}")
            print(f"👉 .env 파일의 CONNECT_ID를 {new_id} 로 변경하세요!")
        else:
            print(f"\n🚨 실패: {result.get('message')}")
            print(f"코드: {result.get('code')}")
            
    except Exception as e:
        print(f"\n🚨 요청 오류: {e}")

if __name__ == "__main__":
    register_card_rsa()
