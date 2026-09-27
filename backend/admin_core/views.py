from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from .models import Role, Permission, AdminAction, SystemSession, SystemSetting
from .serializers import RoleSerializer, AdminActionSerializer, SystemSettingSerializer

User = get_user_model()

class AdminUserManagementViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by('-date_joined')
    permission_classes = [permissions.IsAdminUser]

    @action(detail=True, methods=['patch'])
    def toggle_status(self, request, pk=None):
        user = self.get_object()
        user.is_active = not user.is_active
        user.save(update_fields=['is_active'])
        AdminAction.objects.create(
            admin=request.user, 
            action=f"Toggle user status to {user.is_active}", 
            entity="User", 
            entity_id=user.id
        )
        return Response({'status': f'User active status is now {user.is_active}'}, status=status.HTTP_200_OK)

class AdminAuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    سجل العمليات والتدقيق (Audit Logs) لضمان مراقبة كافة تحركات المشرفين
    """
    queryset = AdminAction.objects.all()
    serializer_class = AdminActionSerializer
    permission_classes = [permissions.IsAdminUser]

class AdminSystemSettingViewSet(viewsets.ModelViewSet):
    queryset = SystemSetting.objects.all()
    serializer_class = SystemSettingSerializer
    permission_classes = [permissions.IsAdminUser]