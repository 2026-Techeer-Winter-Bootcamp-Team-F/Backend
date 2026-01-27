FROM python:3.13-slim

WORKDIR /app

# MySQL 관련 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 패키지 설치
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# 소스 코드 복사 
COPY . .

# 실행 명령어 (docker-compose에서 override 되지만 기본값으로 설정)
CMD ["uvicorn", "config.asgi:application", "--host", "0.0.0.0", "--port", "8000"]