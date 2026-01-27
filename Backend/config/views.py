"""
헬스체크 및 모니터링 관련 뷰
"""
from django.http import JsonResponse
from django.db import connection
from django.views.decorators.http import require_GET
import time


@require_GET
def health_check(request):
    """
    애플리케이션 헬스체크 엔드포인트

    응답 형식:
    - status: "healthy" 또는 "unhealthy"
    - timestamp: 현재 시간 (UNIX timestamp)
    - checks: 각 컴포넌트의 상태
    """
    health_status = {
        "status": "healthy",
        "timestamp": time.time(),
        "checks": {}
    }

    # DB 연결 상태 확인
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        health_status["checks"]["database"] = {
            "status": "healthy",
            "message": "Database connection is working"
        }
    except Exception as e:
        health_status["status"] = "unhealthy"
        health_status["checks"]["database"] = {
            "status": "unhealthy",
            "message": f"Database connection failed: {str(e)}"
        }

    # 애플리케이션 상태
    health_status["checks"]["application"] = {
        "status": "healthy",
        "message": "Application is running"
    }

    # 상태에 따라 HTTP 상태 코드 설정
    status_code = 200 if health_status["status"] == "healthy" else 503

    return JsonResponse(health_status, status=status_code)


@require_GET
def readiness_check(request):
    """
    애플리케이션 준비 상태 확인 (Kubernetes readiness probe 용)

    DB 연결이 정상이면 준비 완료로 간주
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return JsonResponse({"status": "ready"}, status=200)
    except Exception as e:
        return JsonResponse(
            {"status": "not ready", "error": str(e)},
            status=503
        )


@require_GET
def liveness_check(request):
    """
    애플리케이션 생존 확인 (Kubernetes liveness probe 용)

    애플리케이션이 실행 중이면 항상 200 반환
    """
    return JsonResponse({"status": "alive"}, status=200)
