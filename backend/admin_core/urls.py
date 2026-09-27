from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AdminUserManagementViewSet, 
    AdminRoleViewSet, 
    AdminAuditLogViewSet, 
    AdminSystemSettingViewSet
)

router = DefaultRouter()
router.register(r'admin/users', AdminUserManagementViewSet, basename='admin-user')
router.register(r'admin/roles', AdminRoleViewSet, basename='admin-role')
router.register(r'admin/audit-logs', AdminAuditLogViewSet, basename='admin-audit-log')
router.register(r'admin/settings', AdminSystemSettingViewSet, basename='admin-setting')

urlpatterns = [
    path('', include(router.urls)),
]