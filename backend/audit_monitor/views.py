from rest_framework import viewsets, permissions
from .models import AuditLog, SecurityEvent
from .serializers import AuditLogSerializer, SecurityEventSerializer

class AdminAuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    متحكم سجلات التدقيق: للقراءة فقط! يمنع الحذف أو التعديل برمجياً.
    """
    queryset = AuditLog.objects.all().select_related('user')
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAdminUser]
    
    # يمكن إضافة django-filter هنا لعمل فلترة متقدمة حسب الـ Date والـ Module

class AdminSecurityEventViewSet(viewsets.ReadOnlyModelViewSet):
    """
    متحكم الأحداث الأمنية: يسمح بالقراءة فقط
    """
    queryset = SecurityEvent.objects.all().select_related('user')
    serializer_class = SecurityEventSerializer
    permission_classes = [permissions.IsAdminUser]