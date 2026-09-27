import logging
from typing import Dict, Any, Optional
from django.contrib.auth import get_user_model
from .models import Notification, NotificationTemplate

User = get_user_model()
logger = logging.getLogger(__name__)

class NotificationEngine:
    """
    المحرك المركزي لإدارة الإشعارات (Enterprise Notification Gateway).
    يقوم بمعالجة القوالب الديناميكية، إنشاء الإشعار محلياً، ثم تفويض الإرسال الخارجي
    (Push, Email, SMS) إلى طوابير Celery لضمان زمن استجابة (Latency) شبه معدوم.
    """

    @staticmethod
    def process_and_send(
        user, # تم إزالة النوع الثابت هنا لتجنب تحذير Pylance InvalidTypeForm
        template_name: str, 
        context_data: Dict[str, Any], 
        reference_type: Optional[str] = None,
        reference_id: Optional[str] = None,
        action_url: Optional[str] = None
    ) -> Optional[Notification]:
        """
        معالجة القالب وإطلاق الإشعار.
        :param user: كائن المستخدم (User instance) المستهدف بالإشعار.
        :param context_data: المتغيرات الديناميكية للقالب (مثال: {"user_name": "أحمد", "order_id": "123"})
        """
        try:
            # 1. جلب قالب الإشعار النشط
            template = NotificationTemplate.objects.filter(name=template_name, status=True).first()
            if not template:
                logger.warning(f"⚠️ Notification template '{template_name}' not found or disabled.")
                return None

            # 2. حقن المتغيرات الديناميكية (Context Injection) بأمان
            title = template.title_template.format(**context_data)
            message = template.body_template.format(**context_data)

            # 3. إنشاء الإشعار داخل التطبيق (In-App) فوراً ليكون متاحاً في مركز الإشعارات
            notification = Notification.objects.create(
                user=user,
                type=template.type,
                title=title,
                message=message,
                reference_type=reference_type,
                reference_id=reference_id,
                action_url=action_url,
                image=context_data.get('image_url', None) # دعم الإشعارات الغنية بصور
            )

            # 4. ترحيل عمليات الإرسال الخارجية لمعالج الخلفية (Asynchronous Dispatch)
            from .tasks import send_notification_task
            send_notification_task.delay(str(notification.id))

            logger.info(f"✅ Notification '{template_name}' processed and queued for user {user.id}")
            return notification

        except KeyError as e:
            # معالجة الخطأ في حال نسيان تمرير متغير مطلوب في القالب
            logger.error(f"❌ Missing context variable for template '{template_name}': {str(e)}")
            return None
        except Exception as e:
            logger.error(f"🔥 Critical error processing notification: {str(e)}")
            return None


class BroadcastService:
    """
    محرك إطلاق الحملات التسويقية الضخمة (Marketing Campaigns Engine).
    مصمم للتعامل مع إرسال ملايين الإشعارات دون التأثير على أداء المتجر.
    """
    
    @staticmethod
    def launch_campaign(campaign_id: str):
        """
        إرسال الحملة إلى طابور مخصص (Dedicated Queue) لمعالجتها.
        """
        try:
            from .tasks import process_broadcast_campaign_task
            process_broadcast_campaign_task.delay(str(campaign_id))
            
            logger.info(f"🚀 Broadcast Campaign {campaign_id} has been queued successfully.")
        except Exception as e:
            logger.error(f"🔥 Failed to launch campaign {campaign_id}: {str(e)}")