from rest_framework import serializers
from .models import AuditLog, SecurityEvent

class AuditLogSerializer(serializers.ModelSerializer):
    # إحضار البريد الإلكتروني للمستخدم بدلاً من مجرد عرض الـ ID الخاص به
    user_email = serializers.CharField(source='user.email', read_only=True, default="نظام أو مستخدم محذوف")

    class Meta:
        model = AuditLog
        fields = '__all__'
        
    def get_fields(self):
        """
        تجاوز ديناميكي لقفل جميع الحقول!
        هذا يضمن أن كل حقل في هذا السيريالايزر هو للقراءة فقط (Read-Only)
        ويستحيل برمجياً حقن أي بيانات مزورة عبر الـ API.
        """
        fields = super().get_fields()
        for field_name in fields:
            fields[field_name].read_only = True
        return fields


class SecurityEventSerializer(serializers.ModelSerializer):
    user_email = serializers.CharField(source='user.email', read_only=True, default="غير محدد")

    class Meta:
        model = SecurityEvent
        fields = '__all__'

    def get_fields(self):
        """
        قفل جميع الحقول باستثناء حقل 'resolved' 
        للسماح للأدمن بتحديد أن الخطر الأمني قد تمت معالجته.
        """
        fields = super().get_fields()
        for field_name in fields:
            if field_name != 'resolved':
                fields[field_name].read_only = True
        return fields