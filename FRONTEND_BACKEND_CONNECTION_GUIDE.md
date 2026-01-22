# Frontend-Backend & Codef API 연동 가이드 (2026-01-23 통합 업데이트)

이 문서는 **2026년 1월 23일** 기준, Frontend(Flutter)와 Backend(Django)의 **인증 시스템 전면 개편(전화번호 기반)**, **Frontend-Backend Monorepo 통합**, 그리고 **최근 발생한 앱 실행 오류 수정 내역**을 정리한 통합 문서입니다.

---

## 1. 핵심 변경 사항 (Major Updates)

### A. 인증 시스템 전면 개편 (Email → Phone)
기존 이메일 기반 로그인에서 **전화번호 기반 로그인**으로 로직과 DB 구조를 완전히 변경했습니다.

*   **배경**: 기획 변경으로 인해 이메일 대신 전화번호를 고유 식별자(ID)로 사용해야 함.
*   **Database (`users/models.py`)**:
    *   `phone` 컬럼 추가 (`CharField`, unique=True).
    *   `email` 컬럼을 **선택 사항(null=True)**으로 변경.
    *   `USERNAME_FIELD`를 `email`에서 `phone`으로 변경.
    *   기존 데이터와의 호환성 문제가 발생하여 DB를 초기화(`User.objects.all().delete()`)하고 테스트 유저를 재생성함.
*   **Backend API (`users/views.py`)**:
    *   **Signup**: 요청 Body에서 `phone`을 필수로 받도록 수정.
    *   **Login**: `email` 대신 `phone`으로 유저를 조회하고 비밀번호를 검증하도록 수정.
*   **Frontend (`api_service.dart`)**:
    *   로그인/회원가입 요청 시 `phone` 필드를 JSON Key로 사용하여 전송하도록 수정.
    *   `LoginPasswordPage.dart`: 사용자 입력 전화번호(`widget.phone`)를 하이픈 제거 후 전송.

### B. Monorepo 통합 (Git Structure)
프로젝트 관리를 용이하게 하기 위해 분리되어 있던 백엔드와 프론트엔드를 하나의 Git 저장소로 통합했습니다.

*   **Repository URL**: `https://github.com/KimHyeongHo/BandF.git`
*   **구조**:
    ```
    root/ (tekeer_Project2)
    ├── Backend-main/  (Django Server)
    ├── Frontend/      (Flutter App)
    └── FRONTEND_BACKEND_CONNECTION_GUIDE.md
    ```
*   **조치**: `Backend-main` 내부의 `.git` 폴더를 제거하고, 루트에서 `git init` 후 모든 파일을 커밋하여 `main` 브랜치에 Push 완료.

---

## 2. 버그 수정 및 안정화 (Bug Fixes)

### A. 앱 실행 시 Crash 해결 (Data Handling)
신규 사용자(데이터가 없는 상태)가 앱에 진입할 때 발생하던 치명적인 에러들을 수정했습니다.

1.  **RangeError (index)**
    *   **증상**: 홈 화면 진입 시 빨간 에러 화면 발생 (`RangeError: Valid value range is empty: 0`).
    *   **원인**: 지출 내역(`categoryData`)이 비어있는데, "가장 많이 쓴 카테고리"를 보여주기 위해 `categoryData[0]`에 접근하여 발생.
    *   **수정**: 데이터가 비어있을 경우(`isEmpty`) **"지출 내역이 없습니다"** 문구와 함께 **[카드 연결하기]** 버튼을 표시하도록 변경.

2.  **Bad state: No element**
    *   **증상**: 스크롤을 내려 "지난달 비교" 섹션 진입 시 에러 발생.
    *   **원인**: 비교 데이터가 없는데 `first` 속성으로 접근하여 발생.
    *   **수정**: 데이터가 비어있을 경우 **"비교할 데이터가 없습니다"** 문구를 표시하도록 방어 로직 추가.

### B. 로그인/회원가입 프로세스 복구
화면만 존재하고 실제 API를 호출하지 않던 "껍데기" 코드를 실제 동작하는 코드로 구현했습니다.

*   **LoginPasswordPage.dart**:
    *   [확인] 버튼 클릭 시 `ApiService.login`을 호출하여 실제 JWT 토큰을 발급받도록 연결.
    *   복잡한 비밀번호 정규식 제한을 해제하여 기존 비밀번호로도 로그인 가능하도록 수정.
*   **PasswordPage.dart (회원가입)**:
    *   비밀번호 설정 완료 시 `ApiService.signup`을 호출하여 DB에 유저를 생성하고, 즉시 `login`까지 수행하여 자동 로그인되도록 구현.

---

## 3. 기능 복구 (Feature Restoration)

### 카드 연결 버튼 복구
*   **증상**: 데이터가 없는 상태에서 사용자가 카드를 등록할 방법이 없었음.
*   **조치**: 홈 화면의 빈 데이터(Empty State) 뷰에 **[카드 연결하기]** 버튼을 추가했습니다. 클릭 시 `BankSelectionPage`로 이동하여 은행/카드사 연결 프로세스를 시작할 수 있습니다.

---

## 4. 현재 시스템 상태 및 테스트 방법

### 테스트 계정 (Backend DB)
*   **Phone**: `01012345678`
*   **Password**: `password`
*   **상태**: 정상 활성화됨 (DB 초기화 후 생성).

### 앱 실행 방법
1.  **Backend 실행**:
    ```bash
    cd Backend-main
    docker-compose up -d
    ```
2.  **Frontend 실행**:
    ```bash
    cd Frontend
    flutter run
    ```
3.  **로그인 테스트**: 위 테스트 계정으로 로그인하거나, [회원가입] 버튼을 눌러 새 계정(전화번호)으로 가입하세요.

---

## 5. (기존 내용) 2. 시스템 아키텍처 및 인증 흐름

### 간편인증 프로세스 (2-Way Authentication)
KB국민카드 등 주요 금융사는 ID/PW 스크래핑을 차단하므로 **간편인증(Simple Auth)** 방식을 사용해야 합니다.

1.  **사용자 입력 (Frontend)**
    *   **필수 정보**: 이름, 휴대폰번호, 통신사(SKT/KT/LG/알뜰폰), 생년월일(7자리)
    *   **인증 수단**: 카카오톡, 토스, PASS, 페이코 등 선택.
2.  **1차 요청 (Frontend → Backend → Codef)**
    *   `loginType: '5'` (간편인증)
    *   `loginTypeLevel`: 앱 구분 코드 (예: '1' 카카오톡, '4' 토스)
3.  **인증 대기 (Codef CF-03002)**
    *   Codef가 `CF-03002` 응답을 주면, Backend는 이를 `HTTP 202 Accepted`로 프론트엔드에 전달.
    *   응답 데이터에 `two_way_info` 포함.
4.  **사용자 승인 (App Action)**
    *   사용자 휴대폰으로 인증 요청 알림 도착 → 승인 완료.
5.  **2차 요청 (Frontend → Backend → Codef)**
    *   사용자가 앱에서 [인증 완료] 버튼 클릭.
    *   1차 요청의 `two_way_info`를 그대로 Backend에 전송하여 세션 이어가기.
6.  **최종 완료**
    *   Connected ID 발급 성공 (`HTTP 201 Created`).

---

## 6. (기존 내용) 3. 파일별 상세 구현 내역
*(기존 내용 유지 - codef, api_service 등)*

---

## 4. 문제 해결 (Troubleshooting) 자주 묻는 질문

### Q. 서버 에러 (502/500) 또는 DB 연결 오류
*   **증상**: `OperationalError (2005, 'mysqldb')`
*   **해결**: DB 컨테이너가 꺼져있는 상태입니다.
    ```bash
    cd Backend-main
    docker-compose up -d
    ```

### Q. [연결하기] 버튼 무반응
*   **증상**: 버튼을 눌러도 로딩이 돌지 않음.
*   **해결**: 터미널 로그 확인. `Validation failed`가 뜬다면 입력값이 부족한 것입니다.
    *   **주민번호**: 반드시 **7자리** (생년월일6자리 + 성별코드1자리)여야 합니다. (예: `9901011`)
    *   **휴대폰**: 하이픈 없이 숫자만 입력 (예: `01012345678`)

### Q. "Token is for sandbox" (CF-00017)
*   **해결**: Codef API 키는 데모용이지만, URL은 운영용(`https://api.codef.io`)을 바라봐야 합니다. `.env` 파일과 `service.py`의 상수를 확인하세요.

---

## 5. 필수 실행 명령어

**코드가 수정되었으므로 반드시 아래 순서로 재시작하세요.**

```bash
# 1. 백엔드 재시작 (Views.py 수정 반영 확인)
cd Backend-main
docker-compose restart backend

# 2. 로그 확인 (에러 없는지 체크)
docker logs backend --tail 20

# 3. 프론트엔드 실행
cd ../Frontend
flutter run
```
