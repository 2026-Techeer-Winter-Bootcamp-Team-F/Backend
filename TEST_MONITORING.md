# 모니터링 테스트 가이드

## 1. 로컬 환경에서 테스트

### 1.1 서비스 시작
```bash
# 기존 컨테이너 중지 및 삭제
docker-compose down

# 새로 빌드하고 시작
docker-compose up -d --build

# 서비스 상태 확인
docker-compose ps
```

### 1.2 헬스체크 엔드포인트 테스트

```bash
# 기본 헬스체크 (애플리케이션 + DB)
curl http://localhost:8000/health/ | jq

# 기대 결과:
# {
#   "status": "healthy",
#   "timestamp": 1706400000.0,
#   "checks": {
#     "database": {
#       "status": "healthy",
#       "message": "Database connection is working"
#     },
#     "application": {
#       "status": "healthy",
#       "message": "Application is running"
#     }
#   }
# }

# Readiness 체크
curl http://localhost:8000/health/ready/ | jq

# Liveness 체크
curl http://localhost:8000/health/live/ | jq
```

### 1.3 Prometheus 메트릭 테스트

```bash
# Prometheus 메트릭 엔드포인트 확인
curl http://localhost:8000/metrics/

# 일부 트래픽 생성 (메트릭 데이터 만들기)
for i in {1..10}; do curl http://localhost:8000/health/; done

# Prometheus UI 접속
open http://localhost:9090
# 또는 브라우저에서: http://localhost:9090
```

**Prometheus에서 확인할 쿼리:**
```promql
# HTTP 요청 수
django_http_requests_total_by_method_total

# 응답 시간
django_http_requests_latency_seconds_sum

# DB 쿼리 수
django_db_execute_total
```

### 1.4 Grafana 테스트

```bash
# Grafana 접속
open http://localhost:3000
# 로그인: admin / admin
```

**설정 순서:**
1. Data Sources → Add data source → Prometheus 선택
2. URL: `http://prometheus:9090` 입력
3. Save & Test 클릭
4. Dashboards → New Dashboard → Add new panel
5. PromQL 쿼리 입력하여 패널 생성

### 1.5 로그 확인

```bash
# Backend 로그
docker-compose logs -f backend

# Prometheus 로그
docker-compose logs -f prometheus

# Grafana 로그
docker-compose logs -f grafana
```

---

## 2. EC2 환경에서 테스트

### 2.1 사전 준비

EC2 보안 그룹에서 다음 포트를 열어야 합니다:
- **8000**: Backend API
- **9090**: Prometheus UI
- **3000**: Grafana UI

**AWS 콘솔에서 설정:**
1. EC2 → 보안 그룹 선택
2. Inbound rules → Edit inbound rules
3. 다음 규칙 추가:
   - Type: Custom TCP, Port: 8000, Source: My IP (또는 0.0.0.0/0)
   - Type: Custom TCP, Port: 9090, Source: My IP
   - Type: Custom TCP, Port: 3000, Source: My IP

### 2.2 배포 후 테스트

```bash
# EC2 퍼블릭 IP를 환경 변수로 설정
export EC2_IP="your-ec2-public-ip"

# 헬스체크 테스트
curl http://$EC2_IP:8000/health/ | jq

# Prometheus 메트릭 확인
curl http://$EC2_IP:8000/metrics/

# Prometheus UI 접속 테스트
curl -I http://$EC2_IP:9090

# Grafana UI 접속 테스트
curl -I http://$EC2_IP:3000
```

### 2.3 브라우저에서 확인

```
http://your-ec2-ip:8000/health/       # 헬스체크
http://your-ec2-ip:9090                # Prometheus
http://your-ec2-ip:3000                # Grafana (admin/admin)
```

### 2.4 EC2에서 직접 확인 (SSH 접속)

```bash
# EC2에 SSH 접속
ssh -i your-key.pem ec2-user@your-ec2-ip

# 컨테이너 상태 확인
sudo docker ps

# 헬스체크 (내부에서)
curl http://localhost:8000/health/

# 로그 확인
sudo docker logs backend
sudo docker logs prometheus
sudo docker logs grafana
```

---

## 3. CI/CD 파이프라인 테스트

### 3.1 CI 파이프라인에서 헬스체크 추가

CI에서 테스트 실행 후 헬스체크 엔드포인트를 테스트할 수 있습니다.

### 3.2 CD 파이프라인에서 배포 검증

배포 후 헬스체크를 실행하여 배포가 성공했는지 확인할 수 있습니다.

---

## 4. 문제 해결

### 헬스체크가 unhealthy를 반환하는 경우

```bash
# 상세 로그 확인
docker-compose logs backend

# DB 연결 확인
docker-compose exec backend python manage.py dbshell

# 환경 변수 확인
docker-compose exec backend env | grep DB_
```

### Prometheus가 메트릭을 수집하지 못하는 경우

```bash
# Prometheus 타겟 상태 확인 (브라우저)
http://localhost:9090/targets

# Backend 메트릭 엔드포인트 직접 확인
curl http://localhost:8000/metrics/

# Prometheus 설정 확인
cat prometheus/prometheus.yml

# Prometheus 재시작
docker-compose restart prometheus
```

### Grafana가 Prometheus에 연결되지 않는 경우

```bash
# 네트워크 확인
docker network ls
docker network inspect backend_default

# Prometheus 접근 테스트 (Grafana 컨테이너 내부에서)
docker-compose exec grafana curl http://prometheus:9090/api/v1/status/config
```

---

## 5. 성능 테스트 (선택사항)

### 부하 테스트 도구로 트래픽 생성

```bash
# Apache Bench로 부하 테스트
ab -n 1000 -c 10 http://localhost:8000/health/

# 또는 curl로 반복 요청
for i in {1..100}; do
  curl -s http://localhost:8000/api/v1/users/login/ > /dev/null
  echo "Request $i completed"
done
```

이후 Prometheus와 Grafana에서 메트릭 변화를 실시간으로 확인할 수 있습니다.

---

## 6. 프로덕션 체크리스트

배포 전 확인사항:
- [ ] 헬스체크 엔드포인트가 정상 응답 (200 OK, status: healthy)
- [ ] Prometheus가 메트릭을 수집 중 (http://localhost:9090/targets에서 UP 상태)
- [ ] Grafana 대시보드 설정 완료
- [ ] EC2 보안 그룹 포트 오픈 (8000, 9090, 3000)
- [ ] Grafana 기본 비밀번호 변경
- [ ] 알림 설정 (선택사항)
