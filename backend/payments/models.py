import uuid
from decimal import Decimal
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError

class PaymentMethod(models.Model):
    class MethodTypes(models.TextChoices):
        COD = 'cod', 'الدفع عند الاستلام'
        CARD = 'card', 'بطاقة ائتمان/خصم'
        WALLET = 'wallet', 'محفظة إلكترونية'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, verbose_name="اسم الطريقة")
    type = models.CharField(max_length=50, choices=MethodTypes.choices, db_index=True)
    provider = models.CharField(max_length=100, blank=True, null=True, verbose_name="مزود الخدمة") 
    enabled = models.BooleanField(default=True, db_index=True)

    class Meta:
        verbose_name = "طريقة دفع"
        verbose_name_plural = "طرق الدفع"

    def __str__(self):
        return self.name

class Wallet(models.Model):
    class WalletStatus(models.TextChoices):
        ACTIVE = 'active', 'نشطة'
        FROZEN = 'frozen', 'مجمدة'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='wallet')
    balance = models.DecimalField(
        max_digits=10, decimal_places=2, 
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="الرصيد"
    )
    status = models.CharField(max_length=20, choices=WalletStatus.choices, default=WalletStatus.ACTIVE, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "محفظة"
        verbose_name_plural = "المحافظ"

    def __str__(self):
        return f"Wallet - {self.user.email} (Balance: {self.balance} JOD)"

class Payment(models.Model):
    class PaymentStatus(models.TextChoices):
        PENDING = 'pending', 'قيد الانتظار'
        PROCESSING = 'processing', 'جاري المعالجة'
        COMPLETED = 'completed', 'مكتمل'
        FAILED = 'failed', 'فاشل'
        REFUNDED = 'refunded', 'مسترجع'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey('store.Order', on_delete=models.PROTECT, related_name='order_payments')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name='user_payment_history')
    method = models.ForeignKey(PaymentMethod, on_delete=models.PROTECT)
    amount = models.DecimalField(
        max_digits=10, decimal_places=2, 
        validators=[MinValueValidator(Decimal('0.00'))],
        verbose_name="المبلغ"
    )
    currency = models.CharField(max_length=10, default='JOD')
    status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING, db_index=True)
    gateway_reference = models.CharField(max_length=255, blank=True, null=True, db_index=True)
    paid_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "عملية دفع"
        verbose_name_plural = "عمليات الدفع"
        indexes = [
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['user', 'status']),
        ]

    def __str__(self):
        return f"Payment {self.id} - {self.get_status_display()}"

class Transaction(models.Model):
    class TransactionType(models.TextChoices):
        CHARGE = 'charge', 'خصم'
        REFUND = 'refund', 'استرجاع'
        PAYOUT = 'payout', 'تحويل للمتجر'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment = models.ForeignKey(Payment, on_delete=models.PROTECT, related_name='transactions')
    transaction_type = models.CharField(max_length=20, choices=TransactionType.choices, db_index=True)
    amount = models.DecimalField(
        max_digits=10, decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    status = models.CharField(max_length=20, default='success', db_index=True)
    response_data = models.JSONField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "حركة مالية"
        verbose_name_plural = "الحركات المالية"
        indexes = [models.Index(fields=['transaction_type', 'created_at'])]

class Commission(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey('store.Order', on_delete=models.PROTECT, related_name='platform_commissions')
    store = models.ForeignKey('store.Store', on_delete=models.PROTECT, related_name='commissions')
    percentage = models.DecimalField(
        max_digits=5, decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    amount = models.DecimalField(
        max_digits=10, decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "عمولة المنصة"
        verbose_name_plural = "عمولات المنصة"

class Invoice(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey('store.Order', on_delete=models.PROTECT, related_name='invoices')
    invoice_number = models.CharField(max_length=100, unique=True, db_index=True)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))])
    tax = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'), validators=[MinValueValidator(Decimal('0.00'))])
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'), validators=[MinValueValidator(Decimal('0.00'))])
    total = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))])
    pdf_url = models.URLField(max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "فاتورة"
        verbose_name_plural = "الفواتير"

    def clean(self):
        expected_total = self.subtotal + self.tax - self.discount
        if abs(self.total - expected_total) > Decimal('0.01'):
            raise ValidationError("المجموع النهائي لا يتطابق مع الحسبة المالية (الفرعي + الضريبة - الخصم).")

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Invoice {self.invoice_number}"

class Refund(models.Model):
    class RefundStatus(models.TextChoices):
        PENDING = 'pending', 'قيد المراجعة'
        APPROVED = 'approved', 'مقبول'
        REJECTED = 'rejected', 'مرفوض'
        PROCESSED = 'processed', 'تم التحويل'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment = models.ForeignKey(Payment, on_delete=models.PROTECT, related_name='refunds')
    amount = models.DecimalField(
        max_digits=10, decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    reason = models.TextField()
    status = models.CharField(max_length=20, choices=RefundStatus.choices, default=RefundStatus.PENDING, db_index=True)
    processed_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "استرجاع مالي"
        verbose_name_plural = "الاسترجاعات المالية"

    def clean(self):
        if self.amount > self.payment.amount:
            raise ValidationError("مبلغ الاسترجاع لا يمكن أن يتجاوز مبلغ الدفع الأصلي.")

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)