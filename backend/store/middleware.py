from django.http import JsonResponse
from .models import Store
import uuid

class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # نبحث عن معرف المتجر في الهيدر باسم 'X-Store-ID'
        store_id = request.headers.get('X-Store-ID')
        
        if store_id:
            try:
                # التحقق من صحة الـ UUID
                uuid_obj = uuid.UUID(store_id)
                # جلب المتجر وإرفاقه بالطلب
                store = Store.objects.get(id=uuid_obj)
                request.store = store
            except (ValueError, Store.DoesNotExist):
                return JsonResponse({
                    'error': 'Invalid Store ID or Store does not exist.'
                }, status=400)
        else:
            # إذا لم يتم إرسال معرف المتجر، نجعل القيمة None
            request.store = None

        response = self.get_response(request)
        return response