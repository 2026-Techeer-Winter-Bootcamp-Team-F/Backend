"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
"""
from django.urls import path, include
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularRedocView, SpectacularSwaggerView
from .views import health_check, readiness_check, liveness_check

urlpatterns = [
    #path('admin/', admin.site.urls),

    # [추가] 루트 접속 시 Swagger 문서로 리다이렉트
    path('', RedirectView.as_view(url='/api/v1/docs/', permanent=False)),

    # 헬스체크 및 모니터링 엔드포인트
    path('health/', health_check, name='health-check'),
    path('health/ready/', readiness_check, name='readiness-check'),
    path('health/live/', liveness_check, name='liveness-check'),
    path('metrics/', include('django_prometheus.urls')),  # Prometheus 메트릭 엔드포인트

    # [변경] 모든 API 경로에 v1 버전 적용
    path('api/v1/users/', include('users.urls')),      # 예: /api/v1/users/login/
    path('api/v1/expense/', include('expense.urls')),  # 예: /api/v1/expense/analysis/
    path('api/v1/', include('expense.urls')),          # 예: /api/v1/transactions/accumulated (홈화면용)
    path('api/v1/chat/', include('chat.urls')),        # 예: /api/v1/chat/make_room/
    path('api/v1/cards/', include('cards.urls')),      # 예: /api/v1/cards/recommend/
    path('api/v1/category/', include('category.urls')),# 예: /api/v1/category/categories/
    path('api/v1/codef/', include('codef.urls')),      # 예: /api/v1/codef/connected-id/create/

    # drf-spectacular 스웨거 및 레독 문서화 경로
    path('api/v1/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/v1/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/v1/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]
