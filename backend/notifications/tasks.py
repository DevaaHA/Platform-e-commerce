import logging
from celery import shared_task
from django.contrib.auth import get_user_model
from django.db import transaction
from .models import (
    Notification, NotificationLog, DeviceToken, 
    ChannelType, StatusType
)

User = get_user_model()
logger = logging.getLogger(__name__)

@shared_task(bind=True, max_retries=3)
def send_notification_task(self, notification_id):
    """
    مهمة خلفية تعمل عبر Celery لمعالجة وإرسال الإشعار عبر القنوات المفعلة للمستخدم.
    تتضمن آلية Exponential Backoff لإعادة المحاولة عند فشل الاتصال بمزود الخدمة.
    """
    try:
        # استخدام select_related لتقليل استعلامات قاعدة البيانات
        notification = Notification.objects.select_related('user').get(id=notification_id)
        user = notification.user
        
        # جلب إعدادات المستخدم للتأكد من القنوات المفعلة
        settings, _ = user.notification_settings.get_or_create(user=user)
        
        # 1. إرسال Push Notification (عبر Firebase Cloud Messaging - FCM)
        if settings.push_enabled:
            _dispatch_push_notification(notification)
            
        # 2. إرسال البريد الإلكتروني (Email)
        # تحديد الإشعارات التي تستحق الإرسال عبر الإيميل لتقليل الـ Spam
        if settings.email_enabled and notification.type in ['order', 'payment', 'system']:
            _dispatch_email_notification(notification)
            
        # 3. إرسال رسائل نصية قصيرة (SMS) للأحداث الحرجة فقط لتوفير التكلفة
        if settings.sms_enabled and notification.type in ['order', 'payment']:
            _dispatch_sms_notification(notification)

    except Notification.DoesNotExist:
        logger.error(f"❌ Notification with id {notification_id} not found.")
    except Exception as exc:
        logger.error(f"⚠️ Error processing notification task: {str(exc)}")
        # إعادة المحاولة بأسلوب Exponential Backoff (60s, 120s, 240s...)
        backoff_time = 60 * (2 ** self.request.retries)
        raise self.retry(exc=exc, countdown=backoff_time)


def _dispatch_push_notification(notification):
    """
    منطق إرسال الـ Push عبر Firebase Device Tokens بأعلى كفاءة
    """
    tokens = DeviceToken.objects.filter(user=notification.user)
    if not tokens.exists():
        return

    logs_to_create = []
    
    for token_obj in tokens:
        try:
            # TODO: دمج حزمة firebase_admin هنا
            # message = messaging.Message(
            #     notification=messaging.Notification(title=notification.title, body=notification.message),
            #     token=token_obj.device_token
            # )
            # response = messaging.send(message)
            
            # تجهيز السجل للإنشاء الجماعي
            logs_to_create.append(
                NotificationLog(
                    notification=notification,
                    channel=ChannelType.PUSH,
                    status=StatusType.SUCCESS,
                    response={"token": f"{token_obj.device_token[:15]}...", "status": "sent"}
                )
            )
        except Exception as e:
            logger.warning(f"Failed to push to token {token_obj.id}: {str(e)}")
            logs_to_create.append(
                NotificationLog(
                    notification=notification,
                    channel=ChannelType.PUSH,
                    status=StatusType.FAILED,
                    error_message=str(e)
                )
            )
            
    # تنفيذ Bulk Create لكتابة جميع السجلات في استعلام واحد فقط (أداء فائق)
    if logs_to_create:
        NotificationLog.objects.bulk_create(logs_to_create)


def _dispatch_email_notification(notification):
    """
    منطق إرسال البريد الإلكتروني وربطه بقوالب SendGrid أو Django Mail
    """
    try:
        # TODO: send_mail(notification.title, notification.message, 'noreply@souqjo.com', [notification.user.email])
        
        NotificationLog.objects.create(
            notification=notification,
            channel=ChannelType.EMAIL,
            status=StatusType.SUCCESS,
            response={"recipient": notification.user.email}
        )
    except Exception as e:
        NotificationLog.objects.create(
            notification=notification,
            channel=ChannelType.EMAIL,
            status=StatusType.FAILED,
            error_message=str(e)
        )


def _dispatch_sms_notification(notification):
    """
    منطق إرسال الـ SMS عبر المزود المعتمد (Zain/Orange/Twilio)
    """
    try:
        # TODO: إرسال طلب HTTP لمزود خدمة الـ SMS
        
        NotificationLog.objects.create(
            notification=notification,
            channel=ChannelType.SMS,
            status=StatusType.SUCCESS,
            response={"phone": "sent_successfully"}
        )
    except Exception as e:
        NotificationLog.objects.create(
            notification=notification,
            channel=ChannelType.SMS,
            status=StatusType.FAILED,
            error_message=str(e)
        )