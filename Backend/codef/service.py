import os
import requests
import logging
import base64
import json
import urllib.parse
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_v1_5 as PKCS1
from typing import Dict, List, Optional
from django.conf import settings

logger = logging.getLogger(__name__)

class CodefAPIService:
    TOKEN_URL = "https://oauth.codef.io/oauth/token"
    CODEF_API_URL = "https://development.codef.io"  # 데모 서버    
    
    def __init__(self):
        self.client_id = os.getenv('CODEF_CLIENT_ID')
        self.client_secret = os.getenv('CODEF_CLIENT_SECRET')
        self.public_key = os.getenv('CODEF_CLIENT_PUBLIC')
        self.access_token = None  # 동적으로 발급받음
        
        if not self.client_id or not self.client_secret:
            logger.warning("Codef API credentials not configured properly")

    def get_access_token(self) -> Optional[str]:
        """Codef API 액세스 토큰 발급 (매번 새로 발급)"""
        try:
            auth_string = f"{self.client_id}:{self.client_secret}"
            auth_bytes = auth_string.encode('utf-8')
            auth_encoded = base64.b64encode(auth_bytes).decode('utf-8')
            headers = {"Authorization": f"Basic {auth_encoded}", "Content-Type": "application/x-www-form-urlencoded"}
            params = {"grant_type": "client_credentials", "scope": "read"}
            response = requests.post(self.TOKEN_URL, data=params, headers=headers, timeout=10)
            response.raise_for_status()
            self.access_token = response.json().get('access_token')
            return self.access_token
        except Exception as e:
            logger.error(f"Failed to get Access Token: {e}")
            return None

    def _encrypt_field(self, data: str) -> str:
        """Codef 공개키로 데이터를 암호화합니다 (공식 라이브러리 방식)."""
        if not data:
            print("[DEBUG] ⚠️  _encrypt_field: No data provided")
            return data
        
        if not self.public_key:
            print("[DEBUG] ❌ _encrypt_field: No public key available!")
            return data
        
        try:
            print(f"[DEBUG] 🔒 _encrypt_field: Encrypting data (length: {len(data)})")
            print(f"[DEBUG] Public key (first 50 chars): {self.public_key[:50]}...")
            
            # ⭐ Codef 공식 방식: Base64 디코드 → Crypto RSA 사용
            print("[DEBUG] Decoding public key from Base64 (DER format)")
            key_der = base64.b64decode(self.public_key)
            
            print("[DEBUG] Loading RSA public key using Crypto library")
            key_pub = RSA.importKey(key_der)
            
            print("[DEBUG] Creating PKCS1_v1_5 cipher")
            cipher = PKCS1.new(key_pub)
            
            print(f"[DEBUG] Performing RSA encryption with PKCS1_v1_5...")
            cipher_text = cipher.encrypt(data.encode())
            print(f"[DEBUG] Raw encrypted data length: {len(cipher_text)} bytes")
            
            encrypted_base64 = base64.b64encode(cipher_text).decode('utf-8')
            print(f"[DEBUG] ✅ Base64 encoded length: {len(encrypted_base64)} chars")
            print(f"[DEBUG] Encrypted data (first 50 chars): {encrypted_base64[:50]}...")
            return encrypted_base64
        except Exception as e:
            logger.error(f"[DEBUG] Encryption failed for field: {str(e)}")
            logger.error(f"[DEBUG] Encryption error type: {type(e).__name__}")
            import traceback
            traceback.print_exc()
            return data

    def create_connected_id(
        self,
        organization: str,
        card_id: str = "",
        password: str = "",
        card_no: str = "",
        card_password: str = "",
        login_type: str = "1",
        user_name: str = "",
        phone_no: str = "",
        identity: str = "",
        telecom: str = "",
        two_way_info: Dict = None
    ) -> Dict:
        """Connected ID 발급 (자동 RSA 암호화 적용)"""
        try:
            print(f"\n{'='*80}")
            print(f"[DEBUG] Starting Connected ID creation")
            print(f"[DEBUG] Organization: {organization}")
            print(f"[DEBUG] Login Type: {login_type}")
            print(f"[DEBUG] Card ID length: {len(card_id) if card_id else 0}")
            print(f"[DEBUG] Password length: {len(password) if password else 0}")
            print(f"{'='*80}\n")
            
            if not self.access_token:
                print("[DEBUG] Access token not found, requesting new token...")
                if not self.get_access_token():
                    print("[DEBUG] ❌ Failed to get access token")
                    return {"success": False, "error_message": "Token Error"}
                print(f"[DEBUG] ✅ Access token obtained: {self.access_token[:30]}...")
            
            url = f"{self.CODEF_API_URL}/v1/account/create"
            logger.info(f"[DEBUG] Request URL: {url}")
            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }
            
            # 기본 정보 (필수 필드)
            account_info = {
                "countryCode": "KR",
                "businessType": "CD",
                "clientType": "P",
                "organization": organization,
                "loginType": login_type,
                "certType": "1",  # ⭐ 필수 필드!
            }

            # 암호화 적용
            # ID/PW 방식
            if login_type == "1":
                encrypted_pw = self._encrypt_field(password)

                account_info["id"] = card_id
                account_info["password"] = encrypted_pw
                
                if identity:
                    account_info["identity"] = self._encrypt_field(identity)

            # 간편인증 방식
            elif login_type == "5" or login_type == "4":
                account_info["userName"] = user_name
                account_info["phoneNo"] = self._encrypt_field(phone_no) if phone_no else ""
                account_info["identity"] = self._encrypt_field(identity) if identity else ""
                account_info["telecom"] = telecom
                
                if two_way_info and "loginTypeLevel" in two_way_info:
                    account_info["loginTypeLevel"] = two_way_info["loginTypeLevel"]

            # 공통 추가 정보
            if card_no: 
                account_info["cardNo"] = self._encrypt_field(card_no)
            if card_password: 
                account_info["cardPassword"] = self._encrypt_field(card_password)

            if two_way_info:
                account_info["isTwoWay"] = True
                account_info["simpleAuth"] = two_way_info

            payload = {"accountList": [account_info]}
            
            # 민감정보 마스킹 후 로그 출력
            log_info = account_info.copy()
            if 'password' in log_info: log_info['password'] = '***ENCRYPTED***'
            if 'id' in log_info: log_info['id'] = '***ENCRYPTED***'
            if 'identity' in log_info: log_info['identity'] = '***'
            if 'cardPassword' in log_info: log_info['cardPassword'] = '***'
            if 'phoneNo' in log_info: log_info['phoneNo'] = '***'
            
            print(f"\n[DEBUG] 📦 Request payload structure:")
            print(f"[DEBUG] accountList[0]: {json.dumps(log_info, indent=2, ensure_ascii=False)}")
            print(f"[DEBUG] Full payload: {json.dumps({'accountList': [log_info]}, indent=2, ensure_ascii=False)}")
            print(f"[DEBUG] Payload keys: {list(account_info.keys())}")
            print(f"[DEBUG] 🌐 Sending request to Codef API: {url}\n")
            
            # ⭐ 공식 방식: json 파라미터 사용 (URL 인코딩 안 함!)
            response = requests.post(url, json=payload, headers=headers, timeout=60)
            
            print(f"\n[DEBUG] 📥 Response status code: {response.status_code}")
            print(f"[DEBUG] Response content-type: {response.headers.get('content-type')}\n")
            
            # ... (rest of code)
            
            # 응답 디코딩
            resp_text = response.text
            print(f"[DEBUG] Raw response (first 300 chars): {resp_text[:300]}\n")
            
            if resp_text.startswith('%7B') or '%22' in resp_text:
                print("[DEBUG] Response is URL encoded, decoding...")
                resp_text = urllib.parse.unquote_plus(resp_text)
            
            try:
                api_response = json.loads(resp_text)
                print(f"[DEBUG] 📋 Parsed JSON response:")
                print(json.dumps(api_response, indent=2, ensure_ascii=False))
                print()
            except Exception as e:
                print(f"[DEBUG] ❌ Failed to parse JSON: {str(e)}")
                return {"success": False, "error_message": "Invalid JSON response"}

            result_code = api_response.get('result', {}).get('code')
            print(f"[DEBUG] Result code: {result_code}\n")
            
            if result_code == 'CF-00000':
                return {
                    "success": True,
                    "connected_id": api_response.get('data', {}).get('connectedId')
                }
            elif result_code == 'CF-00002': # 이미 존재하는 계정 (기등록)
                # 이미 존재하는 경우, 성공으로 간주하고 connectedId 반환 시도
                cid = api_response.get('data', {}).get('connectedId')
                if cid:
                     return { "success": True, "connected_id": cid, "message": "Already registered" }
                else:
                     logger.warning(f"Already registered (CF-00002) but no connectedId returned. Response: {api_response}")
                     return { "success": False, "error_message": "이미 등록된 계정입니다. (Connected ID 확인 불가)" }

            elif result_code == 'CF-03002': # 추가 인증 필요
                return {
                    "success": False,
                    "is_2fa": True,
                    "message": api_response.get('result', {}).get('message'),
                    "two_way_info": api_response.get('data', {})
                }
            else:
                msg = api_response.get('result', {}).get('message') or "Unknown Error"
                logger.error(f"Codef Error [{result_code}]: {msg} | Response: {api_response}")
                return {"success": False, "error_message": f"[{result_code}] {msg}"}

        except Exception as e:
            logger.error(f"Service Error: {str(e)}")
            return {"success": False, "error_message": str(e)}

    def get_card_list(
        self,
        organization: str,
        connected_id: str,
        birth_date: str = "",
        card_no: str = "",
        card_password: str = "",
        inquiry_type: str = "0"
    ) -> Dict:
        """
        보유 카드 목록 조회
        
        Args:
            organization (str): 기관 코드
            connected_id (str): Connected ID
            birth_date (str): 생년월일 (선택)
            card_no (str): 카드 번호 (선택)
            card_password (str): 카드 비밀번호 (선택)
            inquiry_type (str): 조회 구분 (기본값 "0")
            
        Returns:
            Dict: 카드 목록 조회 결과
        """
        try:
            # 1. 액세스 토큰 확인 (없으면 새로 발급)
            if not self.access_token:
                if not self.get_access_token():
                    return {
                        "success": False,
                        "error_message": "Failed to obtain Codef API access token"
                    }
            
            # 2. 카드 목록 조회 요청
            url = f"{self.CODEF_API_URL}/v1/kr/card/p/account/card-list"

            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }

            payload = {
                "connectedId": connected_id,
                "organization": organization,
                "birthDate": birth_date,
            }
            if card_no:
                payload["cardNo"] = card_no
            if card_password:
                # ⭐ 카드 비밀번호는 RSA 암호화 필요!
                payload["cardPassword"] = self._encrypt_field(card_password)
            if inquiry_type != "0":
                payload["inquiryType"] = inquiry_type

            # ⭐ 공식 방식: json 파라미터 사용
            response = requests.post(
                url,
                json=payload,
                headers=headers,
                timeout=30
            )
            
            if not response.text:
                logger.error(f"Empty response from Codef API. Status: {response.status_code}")
                return {
                    "success": False,
                    "error_message": f"Codef API returned empty response (Status: {response.status_code})"
                }

            try:
                # URL 인코딩 처리
                response_text = response.text
                if response_text.startswith('%7B') or '%22' in response_text:
                    try:
                        decoded_text = urllib.parse.unquote(response_text)
                        api_response = json.loads(decoded_text)
                    except Exception:
                        api_response = response.json()
                else:
                    api_response = response.json()
                    
            except json.JSONDecodeError:
                logger.error(f"Invalid JSON response from Codef API: {response.text}")
                return {
                    "success": False,
                    "error_message": f"Invalid JSON response from Codef API (Status: {response.status_code}): {response.text[:200]}"
                }

            result_code = api_response.get('result', {}).get('code')
            
            if response.status_code == 200 and result_code in ['00000', 'CF-00000']:
                return {
                    "success": True,
                    "data": api_response.get('data')
                }
            else:
                error_msg = api_response.get('result', {}).get('message')
                if not error_msg:
                    error_msg = api_response.get('error_description') or api_response.get('error') or f"Unknown error (HTTP {response.status_code})"

                logger.error(f"Codef API error: {error_msg}")
                return {
                    "success": False,
                    "error_message": error_msg
                }

        except requests.exceptions.RequestException as e:
            logger.error(f"Codef API request failed: {str(e)}")
            return {
                "success": False,
                "error_message": f"API request failed: {str(e)}"
            }
        except Exception as e:
            logger.error(f"Unexpected error in get_card_list: {str(e)}")
            return {
                "success": False,
                "error_message": f"Unexpected error: {str(e)}"
            }

    def get_billing_list(
        self,
        organization: str,
        connected_id: str,
        birth_date: str = "",
        card_no: str = "",
        card_password: str = "",
        inquiry_type: str = "0"
    ) -> Dict:
        """
        보유 카드 청구 내역 조회
        
        Args:
            organization (str): 기관 코드
            connected_id (str): Connected ID
            birth_date (str): 생년월일 (선택)
            card_no (str): 카드 번호 (선택)
            card_password (str): 카드 비밀번호 (선택)
            inquiry_type (str): 조회 구분 (기본값 "0")
            
        Returns:
            Dict: 청구 내역 조회 결과
        """
        try:
            # 1. 액세스 토큰 확인
            if not self.access_token:
                if not self.get_access_token():
                    return {
                        "success": False,
                        "error_message": "Failed to obtain Codef API access token"
                    }
            
            # 2. 청구 내역 조회 요청
            url = f"{self.CODEF_API_URL}/v1/kr/card/p/account/billing-list"

            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }

            payload = {
                "connectedId": connected_id,
                "organization": organization,
                "birthDate": birth_date,
            }
            if card_no:
                payload["cardNo"] = card_no
            if card_password:
                # ⭐ 카드 비밀번호는 RSA 암호화 필요!
                payload["cardPassword"] = self._encrypt_field(card_password)
            if inquiry_type != "0":
                payload["inquiryType"] = inquiry_type

            # ⭐ 공식 방식: json 파라미터 사용
            response = requests.post(
                url,
                json=payload,
                headers=headers,
                timeout=30
            )
            
            if not response.text:
                return {
                    "success": False,
                    "error_message": f"Codef API returned empty response (Status: {response.status_code})"
                }

            try:
                # URL 인코딩 처리
                response_text = response.text
                if response_text.startswith('%7B') or '%22' in response_text:
                    try:
                        decoded_text = urllib.parse.unquote(response_text)
                        api_response = json.loads(decoded_text)
                    except Exception:
                        api_response = response.json()
                else:
                    api_response = response.json()
                    
            except json.JSONDecodeError:
                return {
                    "success": False,
                    "error_message": f"Invalid JSON response from Codef API"
                }

            result_code = api_response.get('result', {}).get('code')
            
            if response.status_code == 200 and result_code in ['00000', 'CF-00000']:
                return {
                    "success": True,
                    "data": api_response.get('data')
                }
            else:
                error_msg = api_response.get('result', {}).get('message')
                if not error_msg:
                    error_msg = api_response.get('error_description') or api_response.get('error') or "Unknown Codef Error"

                logger.error(f"Codef API error: {error_msg}")
                return {
                    "success": False,
                    "error_message": error_msg
                }

        except Exception as e:
            logger.error(f"Unexpected error in get_billing_list: {str(e)}")
            return {
                "success": False,
                "error_message": f"Unexpected error: {str(e)}"
            }

    def get_approval_list(
        self,
        organization: str,
        connected_id: str,
        start_date: str,
        end_date: str,
        card_no: str = "",
        card_password: str = "",
        birth_date: str = "",
        inquiry_type: str = "0",  # 0: 전체, 1: 승인, 2: 취소
    ) -> Dict:
        """
        카드 승인 내역 조회
        """
        try:
            if not self.access_token:
                if not self.get_access_token():
                    return {
                        "success": False,
                        "error_message": "Failed to obtain Codef API access token"
                    }

            url = f"{self.CODEF_API_URL}/v1/kr/card/p/account/approval-list"

            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json"
            }

            payload = {
                "connectedId": connected_id,
                "organization": organization,
                "startDate": start_date,
                "endDate": end_date,
                "orderBy": "1",
                "inquiryType": inquiry_type
            }
            if card_no: payload["cardNo"] = card_no
            if card_password:
                # ⭐ 카드 비밀번호는 RSA 암호화 필요!
                payload["cardPassword"] = self._encrypt_field(card_password)
            if birth_date: payload["birthDate"] = birth_date

            # ⭐ 공식 방식: json 파라미터 사용
            response = requests.post(
                url,
                json=payload,
                headers=headers,
                timeout=30
            )

            if not response.text:
                return {"success": False, "error_message": "Empty response"}

            try:
                # URL 인코딩 처리
                response_text = response.text
                if response_text.startswith('%7B') or '%22' in response_text:
                    try:
                        decoded_text = urllib.parse.unquote(response_text)
                        api_response = json.loads(decoded_text)
                    except:
                        api_response = response.json()
                else:
                    api_response = response.json()
            except:
                return {"success": False, "error_message": "Invalid JSON"}

            if api_response.get('result', {}).get('code') in ['00000', 'CF-00000']:
                return {"success": True, "data": api_response.get('data')}
            else:
                error_msg = api_response.get('result', {}).get('message') or "Unknown Error"
                return {"success": False, "error_message": error_msg}

        except Exception as e:
            logger.error(f"Error in get_approval_list: {str(e)}")
            return {"success": False, "error_message": str(e)}

