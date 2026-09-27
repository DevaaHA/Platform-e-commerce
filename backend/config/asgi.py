"""
ASGI config for config project (Souq JO Platform).
Production-Ready & High-Performance Version (Amazon/Temu Grade)
"""

import os
from django.core.asgi import get_asgi_application

# 1. تهيئة إعدادات جانغو أولاً قبل استدعاء أي مكتبات أخرى لتجنب أخطاء التحميل
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# 2. تهيئة تطبيق HTTP الأساسي (الطلبات العادية السريعة)
django_asgi_app = get_asgi_application()

# 3. استدعاء مكتبات الـ Channels ومسارات التتبع بعد تأمين بيئة جانغو
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from delivery.routing import websocket_urlpatterns

# 4. توجيه الطلبات (Routing) بذكاء بناءً على نوع البروتوكول
application = ProtocolTypeRouter({
    # توجيه الطلبات العادية (REST APIs, واجهات الإدارة)
    "http": django_asgi_app,
    
    # توجيه طلبات الاتصال المباشر (Real-Time WebSockets) للتتبع اللحظي للكباتن
    "websocket": AuthMiddlewareStack(
        URLRouter(
            websocket_urlpatterns
        )
    ),
})