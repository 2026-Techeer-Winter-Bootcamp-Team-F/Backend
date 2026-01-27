# Home API 연동 명세

> 테스트 일시: 2026-01-28
> 서버: `http://localhost:8000` (Docker)
> 인증: JWT Bearer Token
> 전체 7개 엔드포인트 — 모두 `GET`, 인증 필수

---

## 인증

모든 Home API는 JWT 토큰이 필요합니다.

### 로그인

```bash
curl -X POST http://localhost:8000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"01011112222","password":"mock1234"}'
```

**응답:**

```json
{
  "message": "로그인 성공",
  "user_id": "3",
  "name": "목데이터",
  "token": {
    "access": "<ACCESS_TOKEN>",
    "refresh": "<REFRESH_TOKEN>"
  }
}
```

이후 모든 요청에 아래 헤더를 포함합니다:

```
Authorization: Bearer <ACCESS_TOKEN>
```

### 인증 실패 시 공통 응답 (401)

```json
{
  "message": "조회 실패",
  "error_code": "AUTH_REQUIRED",
  "reason": "로그인이 필요하거나 만료되었습니다."
}
```

### 파라미터 누락 시 공통 응답 (400)

```json
{ "message": "year와 month 파라미터가 필요합니다." }
```

---

## 1. 월별 누적 데이터

월의 1일부터 말일까지 일별 누적 지출 금액을 반환합니다. 차트용 데이터입니다.

| 항목 | 값 |
|------|-----|
| **URL** | `GET /api/v1/transactions/accumulated` |
| **파라미터** | `year` (int, 필수), `month` (int, 필수) |
| **테스트 결과** | 200 OK |

### curl

```bash
curl "http://localhost:8000/api/v1/transactions/accumulated?year=2026&month=1" \
  -H "Authorization: Bearer <TOKEN>"
```

### 응답 (200)

```json
{
  "total": 468300,
  "dailyData": [
    { "day": 1, "amount": 0.0 },
    { "day": 2, "amount": 10750.0 },
    { "day": 3, "amount": 18750.0 },
    { "day": 5, "amount": 74250.0 },
    { "day": 7, "amount": 147500.0 },
    { "day": 10, "amount": 232100.0 },
    { "day": 15, "amount": 330550.0 },
    { "day": 20, "amount": 405750.0 },
    { "day": 26, "amount": 468300.0 },
    { "day": 31, "amount": 468300.0 }
  ]
}
```

> `dailyData`는 1일부터 해당 월의 말일(31일 등)까지 매일 포함됩니다. 위는 일부만 발췌.

### 타입 정의

```typescript
interface AccumulatedData {
  total: number;           // 해당 월 총 지출
  dailyData: {
    day: number;           // 1 ~ 28/29/30/31
    amount: number;        // 해당 일까지의 누적 금액 (float)
  }[];
}
```

---

## 2. 일별 지출 요약

캘린더 뷰용. 해당 월에서 지출이 있는 날짜별 합계를 반환합니다.

| 항목 | 값 |
|------|-----|
| **URL** | `GET /api/v1/transactions/daily-summary` |
| **파라미터** | `year` (int, 필수), `month` (int, 필수) |
| **테스트 결과** | 200 OK |

### curl

```bash
curl "http://localhost:8000/api/v1/transactions/daily-summary?year=2026&month=1" \
  -H "Authorization: Bearer <TOKEN>"
```

### 응답 (200)

```json
{
  "expenses": {
    "2": 10750,
    "3": 8000,
    "5": 55500,
    "7": 73250,
    "8": 6500,
    "10": 78100,
    "12": 29500,
    "14": 4450,
    "15": 64500,
    "17": 16700,
    "19": 45000,
    "20": 13500,
    "22": 37150,
    "24": 16100,
    "26": 9300
  }
}
```

> 지출이 없는 날짜는 키가 포함되지 않습니다. 키는 **문자열**입니다.

### 타입 정의

```typescript
interface DailySummary {
  expenses: Record<string, number>;  // key: 날짜(문자열), value: 합계(원)
}
```

---

## 3. 일별 거래 상세 내역

특정 날짜의 개별 거래 내역을 반환합니다.

| 항목 | 값 |
|------|-----|
| **URL** | `GET /api/v1/transactions/daily-detail` |
| **파라미터** | `year` (int, 필수), `month` (int, 필수), `day` (int, 필수) |
| **테스트 결과** | 200 OK |

### curl

```bash
curl "http://localhost:8000/api/v1/transactions/daily-detail?year=2026&month=1&day=5" \
  -H "Authorization: Bearer <TOKEN>"
```

### 응답 (200)

```json
{
  "transactions": [
    {
      "name": "맘스터치 선릉점",
      "category": "shopping",
      "amount": 13500,
      "currency": "KRW"
    }
  ]
}
```

### 타입 정의

```typescript
interface DailyDetail {
  transactions: {
    name: string;       // 가맹점명
    category: string;   // 카테고리 영문 코드 (아래 매핑표 참조)
    amount: number;     // 결제 금액 (원)
    currency: string;   // 항상 "KRW"
  }[];
}
```

### 카테고리 영문 코드 매핑

| 한글 카테고리 | category 값 | emoji | color |
|--------------|------------|-------|-------|
| 식비 | `food` | 🍽️ | #FF6B6B |
| 카페/디저트 | `cafe` | ☕ | #8D6E63 |
| 대중교통 | `transport` | 🚌 | #2196F3 |
| 편의점 | `shopping` | 🏪 | #4CAF50 |
| 온라인쇼핑 | `shopping` | 🛒 | #9C27B0 |
| 대형마트 | `shopping` | 🛒 | #FF9800 |
| 주유/차량 | `transport` | ⛽ | #607D8B |
| 통신/공과금 | `money` | 📱 | #00BCD4 |
| 디지털구독 | `github` | 💻 | #3F51B5 |
| 문화/여가 | `shopping` | 🎬 | #E91E63 |
| 의료/건강 | `shopping` | 💊 | #009688 |
| 교육 | `shopping` | 📚 | #FFC107 |
| 뷰티/잡화 | `shopping` | 💄 | #F06292 |
| 여행/숙박 | `shopping` | ✈️ | #00ACC1 |

---

## 4. 주간 평균 지출

해당 월의 총 지출을 주 수(일수/7)로 나눈 주간 평균입니다.

| 항목 | 값 |
|------|-----|
| **URL** | `GET /api/v1/transactions/weekly-average` |
| **파라미터** | `year` (int, 필수), `month` (int, 필수) |
| **테스트 결과** | 200 OK |

### curl

```bash
curl "http://localhost:8000/api/v1/transactions/weekly-average?year=2026&month=1" \
  -H "Authorization: Bearer <TOKEN>"
```

### 응답 (200)

```json
{
  "average": 105745
}
```

### 타입 정의

```typescript
interface WeeklyAverage {
  average: number;  // 주간 평균 지출 (원, 정수)
}
```

---

## 5. 월간 평균 지출

최근 6개월의 월평균 지출을 반환합니다.

| 항목 | 값 |
|------|-----|
| **URL** | `GET /api/v1/transactions/monthly-average` |
| **파라미터** | `year` (int, 필수), `month` (int, 필수) |
| **테스트 결과** | 200 OK |

### curl

```bash
curl "http://localhost:8000/api/v1/transactions/monthly-average?year=2026&month=1" \
  -H "Authorization: Bearer <TOKEN>"
```

### 응답 (200)

```json
{
  "average": 162441
}
```

> 계산: (1월 지출 + 12월 지출 + 11월~8월 지출) / 6
> 데이터가 없는 달은 0으로 계산됩니다.

### 타입 정의

```typescript
interface MonthlyAverage {
  average: number;  // 6개월 월평균 지출 (원, 정수)
}
```

---

## 6. 카테고리별 지출 요약

해당 월의 카테고리별 지출 금액, 전월 대비 증감, 비율을 반환합니다.

| 항목 | 값 |
|------|-----|
| **URL** | `GET /api/v1/transactions/category-summary` |
| **파라미터** | `year` (int, 필수), `month` (int, 필수) |
| **테스트 결과** | 200 OK |

### curl

```bash
curl "http://localhost:8000/api/v1/transactions/category-summary?year=2026&month=1" \
  -H "Authorization: Bearer <TOKEN>"
```

### 응답 (200)

```json
{
  "categories": [
    {
      "name": "온라인쇼핑",
      "emoji": "🛒",
      "amount": 77900,
      "change": 48000,
      "percent": 16,
      "color": "#9C27B0"
    },
    {
      "name": "식비",
      "emoji": "🍽️",
      "amount": 77700,
      "change": 21600,
      "percent": 16,
      "color": "#FF6B6B"
    },
    {
      "name": "대형마트",
      "emoji": "🛒",
      "amount": 72000,
      "change": 7000,
      "percent": 15,
      "color": "#FF9800"
    }
  ]
}
```

> 금액 내림차순 정렬. `change`는 전월 대비 증감액 (양수=증가, 음수=감소).

### 타입 정의

```typescript
interface CategorySummary {
  categories: {
    name: string;     // 카테고리 한글명
    emoji: string;    // 이모지
    amount: number;   // 이번 달 해당 카테고리 지출 합계 (원)
    change: number;   // 전월 대비 증감액 (원)
    percent: number;  // 전체 지출 대비 비율 (%, 정수)
    color: string;    // HEX 색상 코드
  }[];
}
```

---

## 7. 월간 비교

이번 달과 지난 달의 누적 지출을 일별로 비교합니다.

| 항목 | 값 |
|------|-----|
| **URL** | `GET /api/v1/transactions/month-comparison` |
| **파라미터** | `year` (int, 필수), `month` (int, 필수) |
| **테스트 결과** | 200 OK |

### curl

```bash
curl "http://localhost:8000/api/v1/transactions/month-comparison?year=2026&month=1" \
  -H "Authorization: Bearer <TOKEN>"
```

### 응답 (200)

```json
{
  "thisMonthTotal": 468300,
  "lastMonthSameDay": 496950,
  "thisMonthData": [
    { "day": 1, "amount": 0.0 },
    { "day": 2, "amount": 10750.0 },
    { "day": 5, "amount": 74250.0 },
    { "day": 10, "amount": 232100.0 },
    { "day": 20, "amount": 405750.0 },
    { "day": 28, "amount": 468300.0 }
  ],
  "lastMonthData": [
    { "day": 1, "amount": 9850.0 },
    { "day": 5, "amount": 57500.0 },
    { "day": 10, "amount": 190900.0 },
    { "day": 20, "amount": 296150.0 },
    { "day": 28, "amount": 496950.0 }
  ]
}
```

> `thisMonthData`/`lastMonthData`는 1일부터 오늘(또는 해당 월 말일)까지 매일 포함됩니다. 위는 일부만 발췌.

### 타입 정의

```typescript
interface MonthComparison {
  thisMonthTotal: number;      // 이번 달 누적 총액
  lastMonthSameDay: number;    // 지난 달 같은 날짜까지의 누적 총액
  thisMonthData: {
    day: number;
    amount: number;            // 누적 금액 (float)
  }[];
  lastMonthData: {
    day: number;
    amount: number;
  }[];
}
```

---

## 테스트 결과 요약

| # | 엔드포인트 | HTTP | 결과 |
|---|-----------|------|------|
| 1 | `GET /api/v1/transactions/accumulated` | 200 | PASS |
| 2 | `GET /api/v1/transactions/daily-summary` | 200 | PASS |
| 3 | `GET /api/v1/transactions/daily-detail` | 200 | PASS |
| 4 | `GET /api/v1/transactions/weekly-average` | 200 | PASS |
| 5 | `GET /api/v1/transactions/monthly-average` | 200 | PASS |
| 6 | `GET /api/v1/transactions/category-summary` | 200 | PASS |
| 7 | `GET /api/v1/transactions/month-comparison` | 200 | PASS |

### 에러 케이스

| 케이스 | HTTP | 응답 |
|--------|------|------|
| 토큰 없음 | 401 | `{"message":"조회 실패","error_code":"AUTH_REQUIRED","reason":"로그인이 필요하거나 만료되었습니다."}` |
| 잘못된 토큰 | 401 | 동일 |
| 파라미터 누락 | 400 | `{"message":"year와 month 파라미터가 필요합니다."}` |
| 데이터 없는 월 | 200 | 빈 배열/0 값 정상 반환 |

---

## 테스트용 계정 (Mock)

Seed 스크립트 실행 시 자동 생성되는 계정입니다.

| 항목 | 값 |
|------|-----|
| phone | `01011112222` |
| password | `mock1234` |
| name | `목데이터` |
| email | `mockuser@test.com` |
| age_group | `20대` |
| birth_date | `19990301` |

### 로그인 방법

```bash
curl -X POST http://localhost:8000/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"01011112222","password":"mock1234"}'
```

응답의 `token.access` 값을 이후 모든 API 요청의 `Authorization: Bearer <TOKEN>` 헤더에 사용합니다.

### Mock 데이터 구성

| 월 | 건수 | 비고 |
|----|------|------|
| 2025-12 | 23건 | 전월 비교용 |
| 2026-01 | 29건 | 이번 달 메인 데이터 |

14개 카테고리(식비, 카페/디저트, 대중교통, 편의점, 온라인쇼핑, 대형마트, 주유/차량, 통신/공과금, 디지털구독, 문화/여가, 의료/건강, 교육, 뷰티/잡화, 여행/숙박) 골고루 분포.

### Seed 스크립트 실행

```bash
docker exec -i mysqldb mysql -u root -proot \
  --default-character-set=utf8mb4 \
  card_recommend_db < scripts/seed_mock_data.sql
```

> `--default-character-set=utf8mb4` 필수. 없으면 한글이 깨집니다.
