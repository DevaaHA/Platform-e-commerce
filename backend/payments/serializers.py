from decimal import Decimal
from rest_framework import serializers
from .models import PaymentMethod, Payment, Transaction, Commission, Invoice, Refund

class PaymentMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentMethod
        fields = '__all__'
        read_only_fields = ['id']

class PaymentSerializer(serializers.ModelSerializer):
    # تضمين تفاصيل طريقة الدفع مباشرة لجلبها في طلب واحد (تحسين الأداء - Performance Optimization)
    method_details = PaymentMethodSerializer(source='method', read_only=True)

    class Meta:
        model = Payment
        fields = '__all__'
        read_only_fields = ['id', 'status', 'gateway_reference', 'paid_at', 'created_at']

    def validate_amount(self, value):
        """التحقق من أن مبلغ الدفع موجباً تماماً"""
        if value <= Decimal('0.00'):
            raise serializers.ValidationError("مبلغ الدفع يجب أن يكون قيمة موجبة أكبر من الصفر.")
        return value

class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = '__all__'
        read_only_fields = ['id', 'created_at']

class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = '__all__'
        read_only_fields = ['id', 'invoice_number', 'created_at']

class RefundSerializer(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = '__all__'
        read_only_fields = ['id', 'status', 'processed_at', 'created_at']

    def validate(self, data):
        """حماية محاسبية صارمة: التحقق من حالة الدفع ومبلغ الاسترجاع"""
        payment = data.get('payment')
        amount = data.get('amount')
        
        if payment:
            # منع طلب استرجاع لعملية دفع لم تكتمل أو فشلت
            if payment.status != 'completed':
                raise serializers.ValidationError("لا يمكن طلب استرجاع مالي لعملية دفع غير مكتملة.")
            
            if amount and amount > payment.amount:
                raise serializers.ValidationError("خطأ مالي: مبلغ الاسترجاع لا يمكن أن يتجاوز مبلغ الدفع الأصلي.")
                
        return data

class CommissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Commission
        fields = '__all__'
        read_only_fields = ['id', 'created_at']

    def validate_percentage(self, value):
        """التحقق من أن نسبة العمولة ضمن النطاق المئوي الصحيح"""
        if value < Decimal('0.00') or value > Decimal('100.00'):
            raise serializers.ValidationError("نسبة عمولة المنصة يجب أن تكون بين 0% و 100%.")
        return value