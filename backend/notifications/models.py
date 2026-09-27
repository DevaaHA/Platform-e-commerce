import uuid
from django.db import models
from django.conf import settings

class NotificationType(models.TextChoices):
    ORDER = 'order', 'الطلبات'
    PAYMENT = 'payment', 'الدفع'
    INVENTORY = 'inventory', 'المخزون'
    MARKETING = 'marketing', 'التسويق'
    SYSTEM = 'system', 'النظام'

class PlatformType(models.TextChoices):
    ANDROID = 'android', 'Android'
    IOS = 'ios', 'iOS'
    WEB = 'web', 'Web'

class ChannelType(models.TextChoices):
    PUSH = 'push', 'Push Notification (FCM)'
    EMAIL = 'email', 'البريد الإلكتروني'
    SMS = 'sms', 'الرسائل النصية'
    IN_APP = 'in_app', 'داخل التطبيق'

class StatusType(models.TextChoices):
    SUCCESS = 'success', 'نجاح'
    FAILED = 'failed', 'فشل'
    PENDING = 'pending', 'قيد الانتظار'

class CampaignStatus(models.TextChoices):
    DRAFT = 'draft', 'مسودة'
    SCHEDULED = 'scheduled', 'مجدولة'
    PROCESSING = 'processing', 'جاري الإرسال'
    COMPLETED = 'completed', 'مكتملة'
    FAILED = 'failed', 'فشلت'


class Notification(models.Model):
    """سجل الإشعارات الفردية داخل التطبيق مع دعم التوجيه العميق (Deep Linking)"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    type = models.CharField(max_length=50, choices=NotificationType.choices, db_index=True)
    title = models.CharField(max_length=255)
    message = models.TextField()
    image = models.URLField(max_length=500, blank=True, null=True, help_text="رابط صورة للإشعارات الغنية")
    action_url = models.CharField(max_length=255, blank=True, null=True, help_text="رابط التوجيه عند النقر (مثال: /product/123)")
    reference_type = models.CharField(max_length=100, blank=True, null=True, help_text="نوع الكيان المرتبط (مثال: Order)")
    reference_id = models.UUIDField(blank=True, null=True, db_index=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "إشعار"
        verbose_name_plural = "الإشعارات"
        ordering = ['-created_at']
        indexes = [
            # فهرس مركب فائق السرعة لجلب عدد الإشعارات غير المقروءة للمستخدم
            models.Index(fields=['user', 'is_read', '-created_at']),
        ]

    def __str__(self):
        return f"{self.title} - {self.user.email}"


class NotificationTemplate(models.Model):
    """قوالب الإشعارات الديناميكية المتوافقة مع قنوات الإرسال المتعددة"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, unique=True, db_index=True)
    type = models.CharField(max_length=50, choices=NotificationType.choices)
    channel = models.CharField(max_length=20, choices=ChannelType.choices, default=ChannelType.IN_APP)
    title_template = models.CharField(max_length=255)
    body_template = models.TextField(help_text="يدعم المتغيرات مثل {user_name} أو {order_id}")
    status = models.BooleanField(default=True, db_index=True)

    class Meta:
        verbose_name = "قالب إشعار"
        verbose_name_plural = "قوالب الإشعارات"

    def __str__(self):
        return f"{self.name} ({self.get_channel_display()})"


class UserNotificationSetting(models.Model):
    """مركز تحكم المستخدم في تفضيلات الاتصال"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notification_settings')
    push_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=False) # افتراضياً مغلق لتوفير تكلفة الـ SMS
    marketing_enabled = models.BooleanField(default=True)

    class Meta:
        verbose_name = "إعدادات إشعارات المستخدم"
        verbose_name_plural = "إعدادات إشعارات المستخدمين"

    def __str__(self):
        return f"Settings for {self.user.email}"


class DeviceToken(models.Model):
    """إدارة معرفات أجهزة المستخدمين لخدمة Firebase Cloud Messaging"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='device_tokens')
    device_token = models.TextField(unique=True)
    platform = models.CharField(max_length=20, choices=PlatformType.choices, db_index=True)
    last_active = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "معرف الجهاز (Token)"
        verbose_name_plural = "معرفات الأجهزة"
        indexes = [
            models.Index(fields=['user', 'platform']),
        ]

    def __str__(self):
        return f"{self.platform} Token for {self.user.email}"


class NotificationLog(models.Model):
    """سجل تتبع دقيق لنجاح أو فشل عمليات الإرسال للتدقيق التقني"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    notification = models.ForeignKey(Notification, on_delete=models.CASCADE, related_name='logs', null=True, blank=True)
    channel = models.CharField(max_length=20, choices=ChannelType.choices, db_index=True)
    status = models.CharField(max_length=20, choices=StatusType.choices, default=StatusType.PENDING, db_index=True)
    response = models.JSONField(blank=True, null=True, help_text="استجابة مزود الخدمة (مثل Firebase أو SendGrid)")
    error_message = models.TextField(blank=True, null=True)
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "سجل الإرسال"
        verbose_name_plural = "سجلات الإرسال"

    def __str__(self):
        return f"Log {self.channel} - {self.status}"


class BroadcastCampaign(models.Model):
    """نظام إدارة حملات الإشعارات التسويقية الضخمة المجدولة"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    audience = models.JSONField(default=dict, help_text="قواعد استهداف الجمهور (مثال: {'role': 'customer', 'city': 'Amman'})")
    message = models.TextField()
    image = models.URLField(max_length=500, blank=True, null=True)
    scheduled_at = models.DateTimeField(blank=True, null=True, db_index=True)
    status = models.CharField(max_length=20, choices=CampaignStatus.choices, default=CampaignStatus.DRAFT, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "حملة إعلانية"
        verbose_name_plural = "الحملات الإعلانية"

    def __str__(self):
        return self.title