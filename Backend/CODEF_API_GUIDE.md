# Codef API 연동 설명서

## 개요
이 문서는 Codef API를 통해 사용자의 카드 정보를 자동으로 동기화하고 DB에 저장하는 시스템에 대해 설명합니다.

---

## 시스템 구조

### 1. **codef/service.py** - Codef API 연동
- `CodefAPIService` 클래스: Codef API 호출 및 인증 담당
- Basic Auth 방식의 토큰 발급 (Java 코드 기반)
- 사용자 카드 정보 조회
- API 응답 데이터 파싱

### 2. **codef/sync.py** - 데이터 동기화
- `CardSyncManager` 클래스: DB 저장/업데이트 로직 담당
- Codef 데이터를 Django 모델에 맞게 변환
- 중복 카드 방지 (`get_or_create`)
- `UserCard` 관계 설정

### 3. **cards/views.py** - API 엔드포인트
- `CardCodefSyncView`: Codef 동기화 요청
- `CardListFromDBView`: DB에서 카드 조회

---

## 토큰 발급 방식 (Java 코드 기반)

Python `CodefAPIService`는 다음과 같이 Java 코드를 따릅니다:

```
1. Basic Auth 헤더 생성
   - clientId:clientSecret을 Base64로 인코딩
   - Authorization: Basic [Base64 인코딩값]

2. POST 요청
   - URL: https://oauth.codef.io/oauth/token
   - Content-Type: application/x-www-form-urlencoded
   - 바디: grant_type=client_credentials&scope=read

3. 응답에서 access_token 추출
```

---

## 사용 방법

### 1. 환경 변수 설정

`.env` 파일에 다음을 추가하세요:

```bash
# Codef API 인증 정보
CODEF_CLIENT_ID=your_client_id
CODEF_CLIENT_SECRET=your_client_secret
```

### 2. 카드 정보 동기화 (첫 요청 시)

**엔드포인트:** `POST /api/cards/sync/`

**요청 헤더:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**요청 본문:**
```json
{
    "codef_user_id": "사용자의_Codef_ID",
    "codef_password": "사용자의_Codef_비밀번호",
    "codef_connection_id": null  // 재인증 시에만 필요
}
```

**응답 (성공):**
```json
{
    "message": "카드 동기화 성공",
    "cards_added": 3,
    "cards_updated": 1,
    "cards": [
        {
            "card_id": 1,
            "card_name": "신한 체크카드",
            "company": "신한은행",
            "newly_added": true
        },
        ...
    ]
}
```

### 3. 저장된 카드 불러오기

**엔드포인트:** `GET /api/cards/db/`

**요청 헤더:**
```
Authorization: Bearer <JWT_TOKEN>
```

**응답:**
```json
{
    "message": "카드 조회 성공",
    "count": 4,
    "cards": [
        {
            "card_id": 1,
            "card_name": "신한 체크카드",
            "image": "https://..."
        },
        ...
    ]
}
```

---

## 데이터 흐름

```
┌─────────────────────────────────────────────────────────┐
│  클라이언트 (모바일 앱 / 웹)                           │
└────────────────────┬────────────────────────────────────┘
                     │
        POST /api/cards/sync/ (Codef 인증정보)
                     │
        ┌────────────▼────────────┐
        │   CardCodefSyncView     │
        │  (API 엔드포인트)        │
        └────────────┬────────────┘
                     │
        ┌────────────▼──────────────────┐
        │  CardSyncManager              │
        │  (동기화 로직)                  │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼────────────────┐
        │  CodefAPIService            │
        │  (Codef API 호출)            │
        └────────────┬────────────────┘
                     │
                Codef API ◄──────────► 카드사 데이터
                     │
        ┌────────────▼─────────────────┐
        │  파싱 & 데이터 변환            │
        │  (우리 모델에 맞게)            │
        └────────────┬─────────────────┘
                     │
        ┌────────────▼──────────────┐
        │  Django ORM                │
        │  (get_or_create)           │
        └────────────┬──────────────┘
                     │
                  DB 저장
                     │
     ┌───────────────────────────────────┐
     │  GET /api/cards/db/               │
     │  (저장된 카드 조회)                │
     └───────────────────────────────────┘
```

---

## 주요 특징

### 1. **중복 방지**
- `Card.objects.get_or_create(card_name, company)` 사용
- 같은 이름/발급사 조합은 한 번만 저장

### 2. **사용자 카드 매핑**
- `UserCard` 테이블로 사용자-카드 관계 관리
- 카드 번호 저장

### 3. **트랜잭션 처리**
- `@transaction.atomic` 데코레이터로 일관성 보장
- 한 카드 처리 실패 시에도 다른 카드는 계속 진행

### 4. **에러 로깅**
- Python logging 사용
- 모든 에러 상황 기록

---

## 매뉴얼 카드 동기화 (선택사항)

Django 관리자 패널에서 직접 실행:

```python
# Django shell
python manage.py shell

from cards.card_sync import CardSyncManager
from users.models import User

user = User.objects.get(id=1)
success, result = CardSyncManager.sync_user_cards_from_codef(
    user,
    codef_user_id='user_id',
    codef_password='password'
)

print(result)
```

---

## 트러블슈팅

### 문제 1: "Codef API credentials not configured"
- **원인:** 환경 변수 미설정
- **해결:** `.env` 파일에 `CODEF_CLIENT_ID`, `CODEF_CLIENT_SECRET` 추가

### 문제 2: "Failed to obtain Codef API access token"
- **원인:** Codef 인증 정보 오류 또는 API 서버 문제
- **해결:** 인증 정보 확인 및 Codef API 상태 점검

### 문제 3: 카드가 중복으로 저장됨
- **원인:** 이미 수정됨 (get_or_create 사용)
- **확인:** Card 테이블에서 `card_name`, `company` 조합 확인

### 문제 4: UserCard가 없는 카드가 있음
- **원인:** 직접 DB에 카드 추가된 경우
- **해결:** `UserCard.objects.create()` 실행

---

## 보안 주의사항

⚠️ **중요:**
1. **비밀번호 암호화:** Codef 비밀번호는 요청 본문에 평문으로 전송되므로 **HTTPS** 필수
2. **인증 토큰 관리:** JWT 토큰은 안전하게 저장
3. **API 자격증명 보호:** `.env` 파일은 `.gitignore`에 포함
4. **재인증:** 보안상 주기적으로 사용자에게 재인증 요청

---

## 확장 기능 아이디어

1. **자동 동기화 스케줄러**
   - Celery를 사용한 주기적 동기화
   - 매월 1일 자동 동기화

2. **카드 이미지 다운로드**
   - Codef에서 받은 이미지 로컬 저장
   - CDN에 업로드

3. **혜택 정보 자동 파싱**
   - Codef의 혜택 정보 → CardBenefit 자동 생성
   - 카테고리 자동 매핑

4. **사용자 알림**
   - 새로운 카드 추가 시 알림
   - 특정 카테고리 혜택 권장

---

## 참고 링크

- [Codef API 문서](https://api.codef.io/docs) (요청 필요)
- [Django Transactions](https://docs.djangoproject.com/en/stable/topics/db/transactions/)
- [DRF Serializers](https://www.django-rest-framework.org/api-guide/serializers/)
