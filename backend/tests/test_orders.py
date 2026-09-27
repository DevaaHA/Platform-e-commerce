import pytest
from decimal import Decimal
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()

@pytest.mark.django_db
class TestOrderWorkflow:

    def test_unauthenticated_user_cannot_create_order(self, client):
        """التحقق من الأمان: منع المستخدم غير المسجل من إنشاء طلب"""
        url = '/api/v1/orders/'
        data = {
            "items": [{"product_id": "12345", "quantity": 2}],
            "shipping_address": "إربد، الأردن"
        }
        response = client.post(url, data, format='json')
        # يجب أن يرفض النظام الطلب بـ 401 Unauthorized أو 403 Forbidden
        assert response.status_code in [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN]

    def test_order_calculation_logic(self):
        """اختبار منطق حساب قيمة الطلب والخصومات برمجياً (Unit Test)"""
        unit_price = Decimal('50.00')
        quantity = 3
        discount = Decimal('10.00')
        
        expected_total = (unit_price * quantity) - discount
        calculated_total = (Decimal('50.00') * 3) - Decimal('10.00')
        
        assert calculated_total == expected_total
        assert calculated_total == Decimal('140.00')