import pytest
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()

@pytest.mark.django_db
class TestAuthentication:
    """
    مجموعة اختبارات المصادقة والأمان لمنصة SouqJo
    تضمن سلامة عمليات التسجيل، الدخول، وإدارة رموز التوثيق (Tokens).
    """

    def test_user_registration(self, client):
        """اختبار تسجيل مستخدم جديد بنجاح عبر نقطة النهاية (API)"""
        url = '/api/v1/auth/register/'
        data = {
            "email": "hosam.yasein@souqjo.com",
            "password": "SecurePassword123!",
            "phone_number": "+962790000000",
            "first_name": "حسام",
            "last_name": "ياسين"
        }
        response = client.post(url, data, format='json')
        
        # التأكد من إنشاء الحساب بنجاح (201 Created أو 200 OK حسب إعدادات الـ Serializer)
        assert response.status_code in [status.HTTP_201_CREATED, status.HTTP_200_OK]

    def test_user_login_success(self, client):
        """اختبار تسجيل الدخول لمستخدم مسجل مسبقاً والتحقق من صحة الاستجابة"""
        # 1. إنشاء مستخدم تجريبي بصورة مباشرة في قاعدة البيانات المؤقتة للاختبار
        user = User.objects.create_user(
            email="testuser@souqjo.com", 
            password="Password123!"
        )
        
        url = '/api/v1/auth/login/'
        data = {
            "email": "testuser@souqjo.com",
            "password": "Password123!"
        }
        response = client.post(url, data, format='json')
        
        # التأكد من نجاح عملية المصادقة
        assert response.status_code == status.HTTP_200_OK

    def test_login_with_wrong_password_fails(self, client):
        """اختبار الحماية: التأكد من فشل تسجيل الدخول عند استخدام كلمة مرور خاطئة"""
        User.objects.create_user(
            email="secureuser@souqjo.com", 
            password="CorrectPassword123!"
        )
        
        url = '/api/v1/auth/login/'
        data = {
            "email": "secureuser@souqjo.com",
            "password": "WrongPassword999!"
        }
        response = client.post(url, data, format='json')
        
        # يجب أن يرفض النظام الطلب بـ 400 Bad Request أو 401 Unauthorized
        assert response.status_code in [status.HTTP_400_BAD_REQUEST, status.HTTP_401_UNAUTHORIZED]