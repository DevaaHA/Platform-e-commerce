from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AdminAuditLogViewSet, AdminSecurityEventViewSet

# بناء شبكة مسارات نظام المراقبة والتدقيق
router = DefaultRouter()
router.register(r'admin/audit-logs', AdminAuditLogViewSet, basename='admin-audit-log')
router.register(r'admin/security-events', AdminSecurityEventViewSet, basename='admin-security-event')

urlpatterns = [
    path('', include(router.urls)),
]