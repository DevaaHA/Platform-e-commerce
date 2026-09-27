import uuid
from django.db import models
from django.conf import settings

class AuditLog(models.Model):
    class ActionTypes(models.TextChoices):
        CREATE = 'create', 'إنشاء'
        UPDATE = 'update', 'تعديل'
        DELETE = 'delete', 'حذف'
        LOGIN = 'login', 'تسجيل دخول'
        EXPORT = 'export', 'تصدير بيانات'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, related_name='audit_logs')
    action = models.CharField(max_length=50, choices=ActionTypes.choices, db_index=True)
    module = models.CharField(max_length=100, db_index=True) # e.g., Products, Orders, Settings
    entity_id = models.CharField(max_length=255, blank=True, null=True) # ID of the modified record
    old_values = models.JSONField(blank=True, null=True)
    new_values = models.JSONField(blank=True, null=True)
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    user_agent = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        # الفهارس ضرورية جداً هنا لسرعة البحث في ملايين السجلات
        indexes = [
            models.Index(fields=['user', 'action']),
            models.Index(fields=['created_at', 'module']),
        ]

    def __str__(self):
        return f"{self.user} - {self.action} - {self.created_at}"

class SecurityEvent(models.Model):
    class SeverityLevels(models.TextChoices):
        LOW = 'low', 'منخفض'
        MEDIUM = 'medium', 'متوسط'
        HIGH = 'high', 'عالي'
        CRITICAL = 'critical', 'حرج'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type = models.CharField(max_length=100) # e.g., FAILED_LOGIN, UNAUTHORIZED_ACCESS
    severity = models.CharField(max_length=20, choices=SeverityLevels.choices)
    description = models.TextField()
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    ip_address = models.GenericIPAddressField(blank=True, null=True)
    resolved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']