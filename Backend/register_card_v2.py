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
PUBLIC_KEY = os.getenv('CODEF_CLIENT_PUBLIC')
BASE_URL = "https://api.codef.io"

def get_access_token():
    env_token = os.getenv('ACCESS_TOKEN')
    if env_token and len(env_token) > 20:
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
        key_der = base64.b64decode(public_key_str)
        public_key = rsa.PublicKey.load_pkcs1_openssl_der(key_der)
        encrypted_data = rsa.encrypt(data.encode('utf-8'), public_key)
        return base64.b64encode(encrypted_data).decode('utf-8')
    except Exception as e:
        print(f"암호화 실패: {e}")
        return None

def register_card_final():
    print("=== Codef 카드 등록 진단 도구 v2 ===")
    
    token = get_access_token()
    if not token: 
        print("토큰 확보 실패")
        return

    # 입력 단계
    print("\n[ 필 수 정 보 ]")
    org_code = input("기관코드 (신한:0306, 국민:0301): ").strip()
    user_id = input("아이디: ").strip()
    user_pw = input("비밀번호: ").strip()
    print("※ KB카드 등 일부 기관은 주민번호/생년월일이 필수일 수 있습니다.")
    user_identity = input("주민번호 7자리 (생년월일+성별1자리, 예: 9001011): ").strip()
    
    print("\n[ (선택) 카드번호/비번 앞2자리 ]")
    card_no = input("카드번호 (없으면 엔터): ").strip()
    card_pw = input("비번 앞2자리 (없으면 엔터): ").strip()

    use_encryption = input("\nRSA 암호화를 사용하시겠습니까? (y/n) [권장: y]: ").strip().lower()
    if use_encryption == '': use_encryption = 'y'

    # 데이터 준비
    final_id = user_id
    final_pw = user_pw
    final_card_pw = card_pw if card_pw else None
    final_identity = user_identity

    if use_encryption == 'y':
        if not PUBLIC_KEY:
            print("오류: .env에 CODEF_CLIENT_PUBLIC 키가 없습니다.")
            return
        print(f"암호화 수행 중... (Key len: {len(PUBLIC_KEY)})")
        final_id = encrypt_data(PUBLIC_KEY, user_id)
        final_pw = encrypt_data(PUBLIC_KEY, user_pw)
        if card_pw:
            final_card_pw = encrypt_data(PUBLIC_KEY, card_pw)
        if user_identity:
            final_identity = encrypt_data(PUBLIC_KEY, user_identity)
        
        if not final_id or not final_pw:
            return

    # Payload 구성
    account_info = {
        "countryCode": "KR",
        "businessType": "CD",
        "clientType": "P",
        "organization": org_code,
        "loginType": "1",
        "id": final_id,
        "password": final_pw,
    }
    
    if final_identity: account_info["identity"] = final_identity
    if card_no: account_info["cardNo"] = card_no
    if final_card_pw: account_info["cardPassword"] = final_card_pw

    payload = {
        "accountList": [account_info]
    }

    url = f"{BASE_URL}/v1/account/create"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    print(f"\n⏳ 등록 요청 중... (암호화: {use_encryption})")
    try:
        res = requests.post(url, headers=headers, json=payload, timeout=90)
        
        # URL Decoding
        resp_text = res.text
        if resp_text.startswith('%7B') or '%22' in resp_text:
             resp_text = urllib.parse.unquote_plus(resp_text)
        
        print("\n=== 결과 ===")
        # 보기 좋게 출력
        try:
            data = json.loads(resp_text)
            print(json.dumps(data, indent=2, ensure_ascii=False))

            if data.get('result', {}).get('code') == 'CF-00000':
                new_id = data.get('data', {}).get('connectedId')
                print(f"\n🎉 성공! Connected ID: {new_id}")
                print(f"👉 .env 파일의 CONNECT_ID를 {new_id} 로 변경하세요!")
            elif data.get('result', {}).get('code') == 'CF-04000':
                 print("\n💡 팁: 주민번호를 입력했는지, 암호화 여부를 바꿔보세요.")
        except:
            print(resp_text)

    except Exception as e:
        print(f"\n🚨 요청 오류: {e}")

if __name__ == "__main__":
    register_card_final()
