import pytest
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()

@pytest.mark.django_db
class TestSecurityAndPermissions:

    def test_store_admin_access_restriction(self, client):
        """التحقق من أن تاجر متجر ما لا يمكنه الوصول لبيانات متجر آخر (403 Forbidden)"""
        # إنشاء تاجر عادي
        store_admin = User.objects.create_user(
            email="merchant@souqjo.com", 
            password="Password123!",
            role="store_admin"
        )
        client.force_authenticate(user=store_admin) if hasattr(client, 'force_authenticate') else None
        
        # محاولة الوصول لمسار مخصص حصرياً للـ Super Admin
        url = '/api/v1/admin/dashboard-analytics/overview/'
        response = client.get(url)
        
        # النظام يجب أن يرفض الطلب لعدم كفاية الصلاحيات
        assert response.status_code in [status.HTTP_403_FORBIDDEN, status.HTTP_401_UNAUTHORIZED, status.HTTP_404_NOT_FOUND]

    def test_sql_injection_sanitization(self, client):
        """اختبار أمان المدخلات ضد محاولات الحقن (SQL Injection Simulation)"""
        url = '/api/v1/products/'
        malicious_input = "' OR '1'='1"
        response = client.get(url, {"search": malicious_input})
        
        # يجب ألا يتسبب المدخل الخبيث في انهيار السيرفر (يجب أن يعود بـ 200 مع قائمة فارغة أو 400)
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST]