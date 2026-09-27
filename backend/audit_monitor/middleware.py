import json
from django.utils.deprecation import MiddlewareMixin
from .models import AuditLog

class AuditLogMiddleware(MiddlewareMixin):
    def process_response(self, request, response):
        # تسجيل العمليات التي تقوم بتغيير البيانات فقط (POST, PUT, PATCH, DELETE)
        if request.method in ['POST', 'PUT', 'PATCH', 'DELETE'] and request.user.is_authenticated:
            # في بيئة الإنتاج، يتم إرسال هذه المهمة إلى Celery لتنفذ Async ولا تبطئ استجابة السيرفر
            action_map = {
                'POST': 'create',
                'PUT': 'update',
                'PATCH': 'update',
                'DELETE': 'delete'
            }
            
            AuditLog.objects.create(
                user=request.user,
                action=action_map.get(request.method),
                module=request.path.split('/')[2] if len(request.path.split('/')) > 2 else 'General',
                ip_address=self.get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', '')
            )
        return response

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip