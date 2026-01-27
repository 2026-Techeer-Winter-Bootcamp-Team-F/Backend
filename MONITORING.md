# 모니터링 가이드

## 개요

이 프로젝트는 다음의 모니터링 시스템이 구축되어 있습니다:
- **헬스체크 엔드포인트**: 애플리케이션 및 DB 상태 확인
- **Prometheus**: 메트릭 수집 및 저장
- **Grafana**: 메트릭 시각화 대시보드

## 1. 시작하기

### 서비스 실행

```bash
docker-compose up -d
```

### 서비스 중지

```bash
docker-compose down
```

## 2. 헬스체크 엔드포인트

### 기본 헬스체크
- **URL**: `http://localhost:8000/health/`
- **설명**: 애플리케이션 전체 상태 확인 (DB 연결 포함)
- **응답 예시**:
  ```json
  {
    "status": "healthy",
    "timestamp": 1706400000.0,
    "checks": {
      "database": {
        "status": "healthy",
        "message": "Database connection is working"
      },
      "application": {
        "status": "healthy",
        "message": "Application is running"
      }
    }
  }
  ```

### Readiness Probe (준비 상태)
- **URL**: `http://localhost:8000/health/ready/`
- **설명**: 서비스가 트래픽을 받을 준비가 되었는지 확인
- **용도**: Kubernetes readiness probe

### Liveness Probe (생존 상태)
- **URL**: `http://localhost:8000/health/live/`
- **설명**: 애플리케이션이 실행 중인지 확인
- **용도**: Kubernetes liveness probe

## 3. Prometheus

### 접속 정보
- **URL**: `http://localhost:9090`
- **설명**: Prometheus UI에서 메트릭 쿼리 및 확인 가능

### Django 메트릭 엔드포인트
- **URL**: `http://localhost:8000/metrics/`
- **설명**: Prometheus가 수집하는 메트릭 데이터

### 주요 메트릭

#### HTTP 요청 관련
- `django_http_requests_total_by_method_total`: HTTP 메소드별 총 요청 수
- `django_http_requests_total_by_view_transport_method_total`: 뷰별 요청 수
- `django_http_responses_total_by_status_total`: HTTP 상태 코드별 응답 수
- `django_http_requests_latency_seconds`: 요청 처리 시간

#### 데이터베이스 관련
- `django_db_new_connections_total`: 새로운 DB 연결 수
- `django_db_execute_total`: 실행된 쿼리 수
- `django_db_execute_time_seconds`: 쿼리 실행 시간

#### 시스템 리소스
- `process_cpu_seconds_total`: CPU 사용 시간
- `process_resident_memory_bytes`: 메모리 사용량

### PromQL 쿼리 예시

```promql
# 최근 5분간 초당 요청 수
rate(django_http_requests_total_by_method_total[5m])

# 평균 응답 시간
rate(django_http_requests_latency_seconds_sum[5m]) / rate(django_http_requests_latency_seconds_count[5m])

# HTTP 상태 코드별 요청 비율
rate(django_http_responses_total_by_status_total[5m])
```

## 4. Grafana

### 접속 정보
- **URL**: `http://localhost:3000`
- **기본 계정**:
  - Username: `admin`
  - Password: `admin`

⚠️ **중요**: 운영 환경에서는 반드시 비밀번호를 변경하세요!

### 데이터 소스 추가

1. Grafana에 로그인
2. 좌측 메뉴에서 **Configuration** → **Data Sources** 선택
3. **Add data source** 클릭
4. **Prometheus** 선택
5. 설정:
   - **Name**: `Prometheus`
   - **URL**: `http://prometheus:9090`
   - **Access**: `Server (default)`
6. **Save & Test** 클릭

### 대시보드 생성

#### 방법 1: 직접 생성
1. 좌측 메뉴에서 **+** → **Dashboard** 선택
2. **Add new panel** 클릭
3. PromQL 쿼리를 입력하여 패널 설정

#### 방법 2: 커뮤니티 대시보드 가져오기
1. [Grafana Dashboards](https://grafana.com/grafana/dashboards/)에서 Django 관련 대시보드 검색
2. 추천 대시보드:
   - **Django Prometheus** (ID: 9528)
3. Grafana에서 **+** → **Import** 선택
4. 대시보드 ID 입력 또는 JSON 업로드

### 추천 패널

#### 1. 요청 수 (Requests per Second)
```promql
rate(django_http_requests_total_by_method_total[5m])
```

#### 2. 평균 응답 시간 (Average Response Time)
```promql
rate(django_http_requests_latency_seconds_sum[5m]) / rate(django_http_requests_latency_seconds_count[5m])
```

#### 3. 에러율 (Error Rate)
```promql
rate(django_http_responses_total_by_status_total{status=~"5.."}[5m])
```

#### 4. DB 쿼리 수 (Database Queries)
```promql
rate(django_db_execute_total[5m])
```

#### 5. 메모리 사용량 (Memory Usage)
```promql
process_resident_memory_bytes
```

## 5. 알림 설정 (선택사항)

### Prometheus Alertmanager

`prometheus/alerts.yml` 파일을 생성하여 알림 규칙 정의:

```yaml
groups:
  - name: django_alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate(django_http_responses_total_by_status_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors per second"

      - alert: HighResponseTime
        expr: rate(django_http_requests_latency_seconds_sum[5m]) / rate(django_http_requests_latency_seconds_count[5m]) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "Average response time is {{ $value }} seconds"
```

### Grafana 알림

1. Grafana 패널에서 **Alert** 탭 선택
2. 알림 조건 설정
3. 알림 채널 추가 (Email, Slack, Webhook 등)

## 6. 문제 해결

### Prometheus가 메트릭을 수집하지 못할 때
1. Backend 서비스가 정상 실행 중인지 확인: `docker-compose ps`
2. `/metrics/` 엔드포인트 접속 확인: `curl http://localhost:8000/metrics/`
3. Prometheus 설정 파일 확인: `prometheus/prometheus.yml`
4. Prometheus 로그 확인: `docker-compose logs prometheus`

### Grafana가 Prometheus에 연결되지 않을 때
1. Prometheus가 실행 중인지 확인
2. 데이터 소스 URL이 `http://prometheus:9090`인지 확인 (Docker 네트워크 내부 주소)
3. Grafana 로그 확인: `docker-compose logs grafana`

### 메트릭이 표시되지 않을 때
1. Backend 서비스에 트래픽 발생시키기 (API 호출)
2. Prometheus에서 메트릭 확인: `http://localhost:9090/targets`
3. 쿼리가 올바른지 확인

## 7. 추가 리소스

- [Prometheus 공식 문서](https://prometheus.io/docs/)
- [Grafana 공식 문서](https://grafana.com/docs/)
- [django-prometheus 문서](https://github.com/korfuri/django-prometheus)
- [PromQL 가이드](https://prometheus.io/docs/prometheus/latest/querying/basics/)
