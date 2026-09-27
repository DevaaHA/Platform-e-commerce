import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from .models import Driver, LocationHistory

# إعداد الـ Logger لتتبع الأخطاء في بيئة الإنتاج (Production)
logger = logging.getLogger(__name__)

class DriverLocationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.driver_id = self.scope['url_route']['kwargs']['driver_id']
        self.group_name = f'driver_{self.driver_id}_tracking'

        # الانضمام لمجموعة البث الخاصة بالكابتن
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        logger.info(f"Driver {self.driver_id} connected to WebSocket.")

    async def disconnect(self, close_code):
        # الخروج من المجموعة عند انقطاع الاتصال
        await self.channel_layer.group_discard(self.group_name, self.channel_name)
        logger.info(f"Driver {self.driver_id} disconnected.")

    # استقبال الإحداثيات اللحظية من تطبيق الكابتن
    async def receive(self, text_data):
        try:
            data = json.loads(text_data)
            latitude = data.get('latitude')
            longitude = data.get('longitude')
            speed = data.get('speed', 0.0)       # استخراج سرعة الكابتن إذا توفرت
            accuracy = data.get('accuracy', 0.0) # استخراج دقة الـ GPS
            eta = data.get('eta', 'Unknown')

            # حماية: تجاهل الطلب إذا كانت الإحداثيات مفقودة
            if latitude is None or longitude is None:
                return

            # 1. بث الموقع فوراً عبر الذاكرة السريعة (Redis) لأي عميل أو أدمن يراقب الكابتن
            await self.channel_layer.group_send(
                self.group_name,
                {
                    'type': 'location_update',
                    'latitude': latitude,
                    'longitude': longitude,
                    'speed': speed,
                    'eta': eta
                }
            )

            # 2. حفظ الإحداثيات في قاعدة البيانات بشكل غير متزامن لتغذية نماذج الـ AI لاحقاً
            await self.save_location_history(latitude, longitude, speed, accuracy)

        except json.JSONDecodeError:
            logger.warning("Received invalid JSON format from driver app.")
        except Exception as e:
            logger.error(f"Error processing location update: {str(e)}")

    # إرسال التحديث للعميل عبر الـ WebSocket
    async def location_update(self, event):
        await self.send(text_data=json.dumps({
            'latitude': event['latitude'],
            'longitude': event['longitude'],
            'speed': event.get('speed'),
            'eta': event.get('eta')
        }))

    # دالة غير متزامنة للتعامل مع قاعدة البيانات (Django ORM) بدون حجب الـ Event Loop
    @database_sync_to_async
    def save_location_history(self, lat, lng, speed, accuracy):
        try:
            driver = Driver.objects.get(id=self.driver_id)
            LocationHistory.objects.create(
                driver=driver,
                latitude=lat,
                longitude=lng,
                speed=speed,
                accuracy=accuracy
            )
        except Driver.DoesNotExist:
            logger.error(f"Driver with id {self.driver_id} not found in DB.")