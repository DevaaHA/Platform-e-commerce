import uuid
from decimal import Decimal
from .models import Invoice, Payment

class InvoiceService:
    @staticmethod
    def generate_invoice_for_payment(payment: Payment) -> Invoice:
        """
        تقوم هذه الدالة بحساب الضرائب وتوليد الفاتورة بعد نجاح الدفع
        """
        # حسابات مبدئية (يمكن جلبها من إعدادات الضرائب لاحقاً)
        tax_rate = Decimal('0.16') # ضريبة 16%
        subtotal = payment.amount / (Decimal('1') + tax_rate)
        tax_amount = payment.amount - subtotal

        # إنشاء سجل الفاتورة في قاعدة البيانات
        invoice = Invoice.objects.create(
            order=payment.order,
            invoice_number=f"INV-{uuid.uuid4().hex[:8].upper()}",
            subtotal=round(subtotal, 2),
            tax=round(tax_amount, 2),
            discount=Decimal('0.00'),
            total=payment.amount,
        )

        # هنا يتم استدعاء مكتبة توليد الـ PDF (مثل WeasyPrint)
        # وسنضع رابطاً وهمياً مؤقتاً يحاكي رفع الملف إلى AWS S3 أو السيرفر
        pdf_path = f"/media/invoices/{invoice.invoice_number}.pdf"
        invoice.pdf_url = pdf_path
        invoice.save()

        # يمكن هنا إضافة كود إرسال الفاتورة عبر البريد الإلكتروني للعميل
        
        return invoice