import logging
from decimal import Decimal
from django.utils import timezone
from django.db import transaction as db_transaction
from .models import Payment, Transaction, Commission

logger = logging.getLogger(__name__)

class PaymentGatewayInterface:
    def process_payment(self, payment: Payment, payment_data: dict) -> dict:
        raise NotImplementedError

class StripeGateway(PaymentGatewayInterface):
    def process_payment(self, payment: Payment, payment_data: dict) -> dict:
        """محاكاة الربط مع بوابة دفع إلكترونية (Stripe / PayTabs)"""
        try:
            # هنا يتم استدعاء الـ API الفعلي للبوابة
            # مثال لنتيجة ناجحة:
            return {
                "status": "success", 
                "transaction_id": f"ch_{uuid_gen()}", 
                "data": {"gateway": "stripe", "fee": 0.50}
            }
        except Exception as e:
            logger.error(f"❌ Stripe Gateway Error: {str(e)}")
            return {"status": "failed", "error": str(e)}

class WalletGateway(PaymentGatewayInterface):
    def process_payment(self, payment: Payment, payment_data: dict) -> dict:
        """معالجة الدفع عبر رصيد محفظة المستخدم"""
        user = payment.user
        # افتراض وجود حقل balance في نموذج المستخدم أو المحفظة
        if hasattr(user, 'wallet') and user.wallet.balance >= payment.amount:
            user.wallet.balance -= payment.amount
            user.wallet.save()
            return {
                "status": "success",
                "transaction_id": f"WAL_{payment.id}",
                "data": {"method": "wallet_balance"}
            }
        return {"status": "failed", "error": "رصيد المحفظة غير كافٍ."}

class CODPayment(PaymentGatewayInterface):
    def process_payment(self, payment: Payment, payment_data: dict) -> dict:
        """الدفع عند الاستلام لا خصم فوري فيه، حالته معلقة لحين التوصيل"""
        return {
            "status": "pending", 
            "transaction_id": f"COD_{payment.id}", 
            "data": {"method": "Cash On Delivery"}
        }

class PaymentFactory:
    @staticmethod
    def get_gateway(method_type: str) -> PaymentGatewayInterface:
        if method_type == 'card':
            return StripeGateway()
        elif method_type == 'wallet':
            return WalletGateway()
        elif method_type == 'cod':
            return CODPayment()
        raise ValueError(f"طريقة الدفع غير مدعومة: {method_type}")

class FinancialService:
    @staticmethod
    @db_transaction.atomic
    def process_order_payment(order, user, method, payment_data):
        """
        محرك المعالجة المالي الذكي:
        يتعامل مع الحالات الثلاث (نجاح، قيد الانتظار، فشل) ضمن معاملة قاعدة بيانات ذرية آمنة.
        """
        # 1. إنشاء سجل الدفع المبدئي
        payment = Payment.objects.create(
            order=order,
            user=user,
            method=method,
            amount=order.total_amount,
            status=Payment.PaymentStatus.PROCESSING
        )
        
        try:
            # 2. جلب البوابة المناسبة عبر نمط المصنع (Factory Pattern)
            gateway = PaymentFactory.get_gateway(method.type)
            result = gateway.process_payment(payment, payment_data)
            
            gateway_status = result.get('status')
            
            if gateway_status == 'success':
                # حالة النجاح الفوري (بطاقات أو محفظة)
                payment.status = Payment.PaymentStatus.COMPLETED
                payment.gateway_reference = result.get('transaction_id')
                payment.paid_at = timezone.now()
                payment.save()
                
                Transaction.objects.create(
                    payment=payment,
                    transaction_type=Transaction.TransactionType.CHARGE,
                    amount=payment.amount,
                    response_data=result.get('data', {})
                )
                
                # حساب عمولة المنصة تلقائياً (مثال: 10%)
                commission_percentage = Decimal('10.00')
                commission_amount = payment.amount * (commission_percentage / Decimal('100.00'))
                
                Commission.objects.create(
                    order=order,
                    store=order.store,
                    percentage=commission_percentage,
                    amount=commission_amount
                )
                
                logger.info(f"✅ Payment SUCCESS for Order #{order.id}")
                return True, payment

            elif gateway_status == 'pending':
                # حالة الانتظار (الدفع عند الاستلام COD)
                payment.status = Payment.PaymentStatus.PENDING
                payment.gateway_reference = result.get('transaction_id')
                payment.save()
                
                logger.info(f"⏳ Payment PENDING (COD) for Order #{order.id}")
                return True, payment
                
            else:
                # حالة الفشل
                payment.status = Payment.PaymentStatus.FAILED
                payment.save()
                
                logger.warning(f"❌ Payment FAILED for Order #{order.id}: {result.get('error')}")
                return False, payment

        except Exception as e:
            # معالجة أي انهيار مفاجئ لضمان عدم تلف بيانات الـ Database
            payment.status = Payment.PaymentStatus.FAILED
            payment.save()
            logger.error(f"🔥 Critical Financial Exception: {str(e)}")
            return False, payment

def uuid_gen():
    import uuid
    return uuid.uuid4().hex[:10]