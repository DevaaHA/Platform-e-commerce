from django.urls import re_path
from . import consumers

websocket_urlpatterns = [
    re_path(r'ws/api/tracking/driver/(?P<driver_id>\w+)/$', consumers.DriverLocationConsumer.as_asgi()),
]