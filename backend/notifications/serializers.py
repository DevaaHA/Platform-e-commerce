from rest_framework import serializers
from django.utils.timesince import timesince
from django.utils.translation import gettext as _
from .models import (
    Notification, 
    NotificationTemplate, 
    UserNotificationSetting, 
    DeviceToken, 
    NotificationLog, 
    BroadcastCampaign,
    PlatformType
)

class NotificationSerializer(serializers.ModelSerializer):
    # حقل ديناميكي مهيأ مسبقاً للواجهة الأمامية (Flutter) لتقليل المعالجة
    time_since = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = (
            'id', 'type', 'title', 'message', 'image', 'action_url', 
            'reference_type', 'reference_id', 'is_read', 'created_at', 'time_since'
        )
        # حماية صارمة: المستخدم يستطيع فقط تعديل حالة القراءة (is_read)
        read_only_fields = (
            'id', 'type', 'title', 'message', 'image', 'action_url', 
            'reference_type', 'reference_id', 'created_at'
        )

    def get_time_since(self, obj):
        return f"منذ {timesince(obj.created_at)}"


class NotificationTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationTemplate
        fields = '__all__'
        read_only_fields = ('id',)


class UserNotificationSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserNotificationSetting
        # استبعاد حقل user و id كلياً لمنع التلاعب (IDOR Vulnerability Prevention)
        fields = (
            'push_enabled', 'email_enabled', 
            'sms_enabled', 'marketing_enabled'
        )


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ('device_token', 'platform')

    def validate_platform(self, value):
        """التحقق من صحة المنصة قبل حفظها لضمان توافقها مع خدمات الـ Push"""
        valid_platforms = [choice[0] for choice in PlatformType.choices]
        if value not in valid_platforms:
            raise serializers.ValidationError(_("المنصة المحددة غير مدعومة في المنظومة."))
        return value


class NotificationLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationLog
        fields = '__all__'
        read_only_fields = ('id', 'sent_at', 'status', 'response')


class BroadcastCampaignSerializer(serializers.ModelSerializer):
    class Meta:
        model = BroadcastCampaign
        fields = '__all__'
        # حالة الحملة وتاريخ إنشائها تُدار من قبل الباك إند فقط
        read_only_fields = ('id', 'created_at', 'status')