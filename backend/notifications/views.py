import logging
from rest_framework import viewsets, status, permissions, mixins
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction

from .models import Notification, UserNotificationSetting, DeviceToken, BroadcastCampaign
from .serializers import (
    NotificationSerializer, 
    UserNotificationSettingSerializer, 
    DeviceTokenSerializer, 
    BroadcastCampaignSerializer
)
from .services import BroadcastService

logger = logging.getLogger(__name__)

class NotificationViewSet(
    mixins.ListModelMixin, 
    mixins.RetrieveModelMixin, 
    mixins.DestroyModelMixin, 
    viewsets.GenericViewSet
):
    """
    مركز إشعارات المستخدم.
    استخدمنا GenericViewSet مع Mixins محددة لمنع المستخدم من إنشاء (POST) أو تعديل (PUT) الإشعارات بشكل مباشر،
    مما يغلق ثغرات التلاعب بالبيانات (Data Tampering).
    """
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # المستخدم يرى إشعاراته فقط
        return Notification.objects.filter(user=self.request.user)

    @action(detail=True, methods=['patch'])
    def mark_read(self, request, pk=None):
        """تحديد إشعار معين كمقروء"""
        notification = self.get_object()
        if not notification.is_read:
            notification.is_read = True
            # التحديث باستخدام update_fields لتحسين أداء قاعدة البيانات
            notification.save(update_fields=['is_read'])
        return Response({'status': 'تم التحديد كمقروء'}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['patch'])
    def mark_all_read(self, request):
        """تحديد كافة الإشعارات كمقروءة دفعة واحدة (Bulk Update)"""
        updated_count = self.get_queryset().filter(is_read=False).update(is_read=True)
        return Response({
            'status': 'تم تحديث كافة الإشعارات', 
            'updated_count': updated_count
        }, status=status.HTTP_200_OK)


class UserNotificationSettingViewSet(viewsets.ViewSet):
    """
    إدارة إعدادات الإشعارات للمستخدم ككيان وحيد (Singleton Pattern).
    لا نستخدم ModelViewSet هنا لأن المستخدم يمتلك سجل إعدادات واحد فقط لا غير.
    """
    permission_classes = [permissions.IsAuthenticated]

    def list(self, request):
        """عرض الإعدادات الحالية أو إنشائها إن لم تكن موجودة"""
        settings, _ = UserNotificationSetting.objects.get_or_create(user=request.user)
        serializer = UserNotificationSettingSerializer(settings)
        return Response(serializer.data)

    def create(self, request):
        """تحديث الإعدادات (تعمل كـ PATCH/PUT)"""
        settings, _ = UserNotificationSetting.objects.get_or_create(user=request.user)
        serializer = UserNotificationSettingSerializer(settings, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class DeviceTokenViewSet(mixins.CreateModelMixin, mixins.DestroyModelMixin, viewsets.GenericViewSet):
    """
    إدارة معرفات الأجهزة (Device Tokens) الخاصة بخدمة الـ Push Notifications.
    """
    serializer_class = DeviceTokenSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return DeviceToken.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        # استخدام المعاملات الذرية لضمان حذف التوكن القديم وتسجيل الجديد بأمان
        with transaction.atomic():
            token_val = serializer.validated_data.get('device_token')
            # إزالة التوكن إذا كان مرتبطاً بحساب آخر (لتجنب إرسال إشعارات لمستخدم سجل خروجه)
            DeviceToken.objects.filter(device_token=token_val).delete()
            serializer.save(user=self.request.user)


class AdminBroadcastViewSet(viewsets.ModelViewSet):
    """
    لوحة تحكم الأدمن لإنشاء وإدارة الحملات الإعلانية (Broadcast Campaigns).
    """
    queryset = BroadcastCampaign.objects.all().order_by('-created_at')
    serializer_class = BroadcastCampaignSerializer
    permission_classes = [permissions.IsAdminUser]

    @action(detail=False, methods=['post'])
    def send_broadcast(self, request):
        """
        إطلاق حملة تسويقية ضخمة. يتم إنشاء السجل هنا وترحيل الإرسال للخلفية لضمان الأداء.
        """
        title = request.data.get('title')
        message = request.data.get('message')
        audience_filters = request.data.get('audience', {}) # يستقبل JSON كفلاتر
        image_url = request.data.get('image_url')
        scheduled_at = request.data.get('scheduled_at')

        if not title or not message:
            return Response({'error': 'Title and message are required'}, status=status.HTTP_400_BAD_REQUEST)

        # 1. إنشاء الحملة في قاعدة البيانات (حالتها: قيد المعالجة أو مجدولة)
        status_val = 'scheduled' if scheduled_at else 'processing'
        
        campaign = BroadcastCampaign.objects.create(
            title=title,
            message=message,
            audience=audience_filters,
            image=image_url,
            scheduled_at=scheduled_at,
            status=status_val
        )

        # 2. ترحيل المعالجة الثقيلة فوراً إلى Celery عبر BroadcastService 
        # (لا نستخدم أي حلقات Loop هنا إطلاقاً)
        if not scheduled_at:
            BroadcastService.launch_campaign(str(campaign.id))

        return Response({
            'status': 'Broadcast campaign queued successfully', 
            'campaign_id': str(campaign.id)
        }, status=status.HTTP_202_ACCEPTED)