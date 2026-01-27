# EC2 모니터링 구축 가이드

## 1. EC2 사전 설정

### 1.1 Docker Compose 설치 (EC2에서)

```bash
# EC2에 SSH 접속
ssh -i your-key.pem ec2-user@your-ec2-ip

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 설치 확인
docker-compose --version
```

### 1.2 작업 디렉토리 생성

```bash
mkdir -p ~/app
cd ~/app
```

## 2. AWS 보안 그룹 설정

EC2 인스턴스의 보안 그룹에 다음 포트를 추가해야 합니다:

| 포트 | 서비스 | 설명 | 권장 Source |
|------|--------|------|-------------|
| 8000 | Backend API | Django 애플리케이션 | 0.0.0.0/0 또는 특정 IP |
| 9090 | Prometheus | 메트릭 수집 및 쿼리 | 관리자 IP만 허용 권장 |
| 3000 | Grafana | 대시보드 UI | 관리자 IP만 허용 권장 |
| 80 | Nginx (선택) | 웹 서버 | 0.0.0.0/0 |
| 3306 | MySQL (선택) | DB 외부 접속 | 특정 IP만 허용 권장 |

### AWS 콘솔에서 설정하기

1. **EC2 콘솔** → **인스턴스** 선택
2. 인스턴스 선택 → **보안** 탭
3. **보안 그룹** 클릭
4. **인바운드 규칙 편집** 클릭
5. 다음 규칙 추가:

```
Type: Custom TCP
Port: 8000
Source: 0.0.0.0/0  (또는 My IP)
Description: Backend API

Type: Custom TCP
Port: 9090
Source: My IP
Description: Prometheus UI

Type: Custom TCP
Port: 3000
Source: My IP
Description: Grafana Dashboard
```

### AWS CLI로 설정하기

```bash
# 보안 그룹 ID 확인
aws ec2 describe-security-groups --filters "Name=group-name,Values=your-security-group-name"

# 포트 추가
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 8000 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 9090 \
  --cidr your-ip/32

aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 3000 \
  --cidr your-ip/32
```

## 3. GitHub Secrets 추가

CD 파이프라인이 작동하려면 다음 Secrets가 필요합니다:

### 기존 Secrets (확인)
- `EC2_HOST`: EC2 퍼블릭 IP 또는 도메인
- `EC2_USER`: EC2 사용자 (일반적으로 `ec2-user` 또는 `ubuntu`)
- `EC2_KEY`: EC2 SSH 프라이빗 키
- `DOCKERHUB_USERNAME`: DockerHub 사용자명
- `DOCKERHUB_TOKEN`: DockerHub 액세스 토큰
- `SECRET_KEY`: Django SECRET_KEY
- `DB_NAME`: 데이터베이스 이름
- `DB_USER`: 데이터베이스 사용자
- `DB_PASSWORD`: 데이터베이스 비밀번호
- `DB_HOST`: 데이터베이스 호스트
- `CODEF_CLIENT_ID`: CODEF API Client ID
- `CODEF_CLIENT_SECRET`: CODEF API Client Secret
- `CODEF_CLIENT_PUBLIC`: CODEF API Public Key
- `GEMINI_API_KEY`: Gemini API Key

### 추가 필요 Secrets
- `DB_ROOT_PASSWORD`: MySQL Root 비밀번호 (새로 추가)

**GitHub에서 Secrets 추가:**
1. GitHub 저장소 → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭
3. Name: `DB_ROOT_PASSWORD`, Value: 강력한 비밀번호 입력

## 4. 배포 및 테스트

### 4.1 코드 푸시 (자동 배포 트리거)

```bash
git add .
git commit -m "Add monitoring stack (Prometheus + Grafana)"
git push origin main
```

### 4.2 GitHub Actions 확인

1. GitHub 저장소 → **Actions** 탭
2. CI 워크플로우 성공 확인
3. CD 워크플로우 성공 확인

### 4.3 배포 후 테스트

```bash
# 환경 변수 설정 (본인의 EC2 IP로 변경)
export EC2_IP="your-ec2-public-ip"

# 헬스체크 테스트
curl http://$EC2_IP:8000/health/ | jq

# 기대 결과:
# {
#   "status": "healthy",
#   "timestamp": ...,
#   "checks": {
#     "database": { "status": "healthy", ... },
#     "application": { "status": "healthy", ... }
#   }
# }

# Prometheus 접속 확인
curl -I http://$EC2_IP:9090

# Grafana 접속 확인
curl -I http://$EC2_IP:3000
```

### 4.4 브라우저에서 확인

```
http://your-ec2-ip:8000/health/       # 헬스체크
http://your-ec2-ip:8000/api/v1/docs/  # API 문서
http://your-ec2-ip:9090                # Prometheus
http://your-ec2-ip:3000                # Grafana (admin/admin)
```

## 5. Grafana 초기 설정

### 5.1 Grafana 접속

```
URL: http://your-ec2-ip:3000
Username: admin
Password: admin
```

⚠️ **첫 로그인 시 비밀번호 변경 필수!**

### 5.2 Prometheus 데이터 소스 추가

1. 좌측 메뉴 → **Connections** → **Data sources**
2. **Add data source** 클릭
3. **Prometheus** 선택
4. 설정:
   - **Name**: `Prometheus`
   - **URL**: `http://prometheus:9090`
   - **Access**: `Server (default)`
5. **Save & Test** 클릭

### 5.3 대시보드 생성

#### 옵션 1: 커뮤니티 대시보드 Import

1. 좌측 메뉴 → **Dashboards**
2. **New** → **Import**
3. Grafana.com 대시보드 ID 입력: `9528` (Django Prometheus)
4. **Load** → Prometheus 데이터 소스 선택 → **Import**

#### 옵션 2: 직접 생성

1. 좌측 메뉴 → **Dashboards** → **New** → **New Dashboard**
2. **Add visualization** 클릭
3. Prometheus 데이터 소스 선택
4. PromQL 쿼리 입력:

**추천 패널:**

```promql
# 1. 초당 요청 수 (RPS)
rate(django_http_requests_total_by_method_total[5m])

# 2. 평균 응답 시간
rate(django_http_requests_latency_seconds_sum[5m]) /
rate(django_http_requests_latency_seconds_count[5m])

# 3. HTTP 상태 코드별 응답 수
rate(django_http_responses_total_by_status_total[5m])

# 4. DB 쿼리 수
rate(django_db_execute_total[5m])

# 5. 에러율 (5xx)
rate(django_http_responses_total_by_status_total{status=~"5.."}[5m])
```

## 6. EC2에서 직접 확인 (문제 발생 시)

### 6.1 SSH 접속

```bash
ssh -i your-key.pem ec2-user@your-ec2-ip
cd ~/app
```

### 6.2 서비스 상태 확인

```bash
# 컨테이너 상태
sudo docker-compose ps

# 로그 확인
sudo docker-compose logs backend
sudo docker-compose logs prometheus
sudo docker-compose logs grafana
sudo docker-compose logs mysqldb

# 실시간 로그
sudo docker-compose logs -f backend
```

### 6.3 헬스체크

```bash
# 내부에서 헬스체크
curl http://localhost:8000/health/ | jq

# Prometheus 메트릭
curl http://localhost:8000/metrics/

# Prometheus 타겟 확인
curl http://localhost:9090/api/v1/targets | jq
```

### 6.4 서비스 재시작

```bash
# 전체 재시작
sudo docker-compose restart

# 개별 서비스 재시작
sudo docker-compose restart backend
sudo docker-compose restart prometheus
sudo docker-compose restart grafana
```

### 6.5 볼륨 및 네트워크 확인

```bash
# 볼륨 목록
sudo docker volume ls

# 네트워크 목록
sudo docker network ls

# 컨테이너 IP 확인
sudo docker network inspect app_default
```

## 7. 문제 해결

### Backend 컨테이너가 시작되지 않는 경우

```bash
# 로그 확인
sudo docker-compose logs backend

# DB 연결 확인
sudo docker-compose exec backend python manage.py dbshell

# 환경 변수 확인
sudo docker-compose exec backend env | grep DB_
```

### Prometheus가 메트릭을 수집하지 못하는 경우

```bash
# Backend 메트릭 엔드포인트 확인
curl http://localhost:8000/metrics/

# Prometheus 설정 확인
cat ~/app/prometheus/prometheus.yml

# Prometheus 로그 확인
sudo docker-compose logs prometheus

# Prometheus 재시작
sudo docker-compose restart prometheus
```

### Grafana가 Prometheus에 연결되지 않는 경우

```bash
# Grafana에서 Prometheus 접근 테스트
sudo docker-compose exec grafana curl http://prometheus:9090/api/v1/status/config

# Grafana 로그 확인
sudo docker-compose logs grafana
```

## 8. 성능 최적화 팁

### Prometheus 데이터 보관 기간 설정

`docker-compose.yml`의 prometheus 서비스에 추가:

```yaml
command:
  - '--storage.tsdb.retention.time=30d'  # 30일간 데이터 보관
```

### Grafana 알림 설정

1. Grafana → **Alerting** → **Notification channels**
2. Slack, Email 등 알림 채널 추가
3. 대시보드 패널에서 Alert 설정

## 9. 보안 권장사항

### Grafana 비밀번호 변경

```bash
# docker-compose.yml에서 환경 변수 변경
GF_SECURITY_ADMIN_PASSWORD=your-strong-password
```

### 방화벽 설정

```bash
# Prometheus와 Grafana는 내부 네트워크만 접근하도록 설정
# docker-compose.yml에서 ports를 expose로 변경
```

### Nginx 리버스 프록시 추가 (선택)

Nginx를 통해 Prometheus와 Grafana에 접근하고, 기본 인증 추가:

```nginx
location /prometheus/ {
    auth_basic "Prometheus";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://prometheus:9090/;
}

location /grafana/ {
    proxy_pass http://grafana:3000/;
}
```

## 10. 프로덕션 체크리스트

배포 전 확인사항:
- [ ] EC2 보안 그룹 포트 오픈 (8000, 9090, 3000)
- [ ] Docker Compose 설치 완료
- [ ] GitHub Secrets 모두 설정 완료 (DB_ROOT_PASSWORD 포함)
- [ ] .env 파일 EC2에 생성 완료
- [ ] CI 파이프라인 통과
- [ ] CD 파이프라인 통과
- [ ] 헬스체크 정상 응답 (http://ec2-ip:8000/health/)
- [ ] Prometheus 메트릭 수집 중 (http://ec2-ip:9090/targets)
- [ ] Grafana 접속 및 데이터 소스 연결 완료
- [ ] Grafana 기본 비밀번호 변경
- [ ] 대시보드 생성 완료

---

배포가 완료되면 실시간으로 애플리케이션 상태를 모니터링할 수 있습니다! 🎉
