import os
# import google.generativeai as old_genai # 구버전 (비교용) -> 삭제됨
from google import genai # 신버전
from dotenv import load_dotenv

# 1. 환경변수 로드
load_dotenv('backend.env')
api_key = os.getenv('GEMINI_API_KEY')


print(f"--- Gemini API 진단 시작 ---")
print(f"API Key 확인: {'***' + api_key[-4:] if api_key else '없음'}")

if not api_key:
    print("오류: API 키가 없습니다. backend.env 파일을 확인해주세요.")
    exit()

# 2. 신버전 (google-genai) 테스트
print("\n[테스트 1] 신버전 라이브러리 (google-genai)")
try:
    client = genai.Client(api_key=api_key)
    print(">> 클라이언트 연결 성공")
    
    # 모델 목록 조회 시도 (신버전은 방식이 다를 수 있어 생성 테스트로 바로 진입)
    print(">> gemini-2.0-flash 모델 테스트 중...")
    try:
        response = client.models.generate_content(
            model="gemini-2.0-flash", 
            contents="Hello"
        )
        print(f"✅ 성공! 응답: {response.text}")
    except Exception as e:
        print(f"❌ 실패 (2.0-flash): {e}")

    print(">> gemini-1.5-flash 모델 테스트 중...")
    try:
        response = client.models.generate_content(
            model="gemini-1.5-flash", 
            contents="Hello"
        )
        print(f"✅ 성공! 응답: {response.text}")
    except Exception as e:
        print(f"❌ 실패 (1.5-flash): {e}")

except Exception as e:
    print(f"❌ 클라이언트 초기화 실패: {e}")


# 3. 구버전 (google-generativeai) 호환성 테스트 - 삭제됨 (패키지 제거함)
# print("\n[테스트 2] 구버전 라이브러리 (google.generativeai)")
# try:
#     old_genai.configure(api_key=api_key)
#     print(">> 사용 가능한 모델 목록 조회 중...")
#     
#     found_models = []
#     for m in old_genai.list_models():
#         if 'generateContent' in m.supported_generation_methods:
#             found_models.append(m.name)
#             print(f"   - {m.name}")
#             
#     if not found_models:
#         print("⚠️ 사용 가능한 모델이 하나도 조회되지 않습니다. (API 키 권한 또는 지역 문제 가능성)")
#     
#     # 구버전 연결 테스트
#     if 'models/gemini-pro' in found_models:
#         print("\n>> gemini-pro (구버전) 테스트...")
#         model = old_genai.GenerativeModel('gemini-pro')
#         res = model.generate_content("Hi")
#         print(f"✅ 성공! 응답: {res.text}")
#     
# except Exception as e:
#     print(f"❌ 구버전 테스트 실패: {e}")

print("\n--- 진단 종료 ---")
