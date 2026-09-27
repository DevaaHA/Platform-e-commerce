import logging
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.db.models import Sum
from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.apps import apps  # الحل الهندسي لجلب النماذج ديناميكياً وفك الارتباط

from .models import Payment, PaymentMethod, Transaction, Invoice, Refund, Commission
from .serializers import (
    PaymentSerializer, PaymentMethodSerializer, TransactionSerializer, 
    InvoiceSerializer, RefundSerializer, CommissionSerializer
)
from .services import FinancialService
from .invoice_service import InvoiceService

logger = logging.getLogger(__name__)

class PaymentMethodViewSet(viewsets.ReadOnlyModelViewSet):
    """جلب طرق الدفع المتاحة للعميل بكفاءة عالية"""
    queryset = PaymentMethod.objects.filter(enabled=True)
    serializer_class = PaymentMethodSerializer
    permission_classes = [permissions.IsAuthenticated]


class CustomerPaymentViewSet(viewsets.ModelViewSet):
    """واجهة دفع العميل مع التحقق الشامل وتحسينات الأداء"""
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Payment.objects.filter(user=self.request.user).select_related('method').order_by('-created_at')

    @action(detail=False, methods=['post'])
    def process(self, request):
        """نقطة النهاية لبدء عملية الدفع الفعلية عبر المحرك المالي الآمن"""
        order_id = request.data.get('order_id')
        method_id = request.data.get('method_id')

        if not order_id or not method_id:
            return Response({"error": "يرجى توفير معرف الطلب (order_id) وطريقة الدفع (method_id)."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # استدعاء نموذج الطلبات ديناميكياً لتجنب مشاكل الاستيراد الثابت (Import Errors)
            Order = apps.get_model('orders', 'Order')
            order = Order.objects.get(id=order_id, user=request.user)
        except LookupError:
            return Response({"error": "تطبيق الطلبات غير مسجل في النظام."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception:
            return Response({"error": "الطلب غير موجود أو ليس لديك صلاحية الوصول إليه."}, status=status.HTTP_404_NOT_FOUND)

        try:
            method = PaymentMethod.objects.get(id=method_id, enabled=True)
        except PaymentMethod.DoesNotExist:
            return Response({"error": "طريقة الدفع المحددة غير متوفرة أو معطلة."}, status=status.HTTP_400_BAD_REQUEST)

        # استدعاء محرك المعالجة المالي الذكي
        success, payment = FinancialService.process_order_payment(order, request.user, method, request.data)
        
        if success:
            return Response(PaymentSerializer(payment).data, status=status.HTTP_201_CREATED)
        
        return Response({"error": "فشلت عملية الدفع. يرجى التحقق من المدخلات أو المحاولة لاحقاً."}, status=status.HTTP_400_BAD_REQUEST)


class InvoiceViewSet(viewsets.ReadOnlyModelViewSet):
    """عرض الفواتير وتحميلها مع تحسين الاستعلامات"""
    serializer_class = InvoiceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff:
            return Invoice.objects.all()
        return Invoice.objects.filter(order__user=self.request.user)


class RefundViewSet(viewsets.ModelViewSet):
    """إدارة الاسترجاعات المالية والطلبات"""
    serializer_class = RefundSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff:
            return Refund.objects.all().select_related('payment')
        return Refund.objects.filter(payment__user=self.request.user).select_related('payment')

    @action(detail=True, methods=['patch'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        """للأدمن فقط: الموافقة على الاسترجاع المالي"""
        refund = self.get_object()
        if refund.status == Refund.RefundStatus.APPROVED:
            return Response({"message": "تمت الموافقة مسبقاً على هذا الطلب."}, status=status.HTTP_400_BAD_REQUEST)
        
        refund.status = Refund.RefundStatus.APPROVED
        refund.save()
        return Response({"message": "تمت الموافقة على الاسترجاع المالي بنجاح."})


class AdminFinanceViewSet(viewsets.ViewSet):
    """لوحة تحكم الإدارة المالية (ملخصات وأرباح سريعة ومجمعة)"""
    permission_classes = [permissions.IsAdminUser]

    def list(self, request):
        total_revenue = Payment.objects.filter(status='completed').aggregate(Sum('amount'))['amount__sum'] or 0
        total_commissions = Commission.objects.aggregate(Sum('amount'))['amount__sum'] or 0
        total_refunds = Refund.objects.filter(status='processed').aggregate(Sum('amount'))['amount__sum'] or 0

        data = {
            "total_revenue": total_revenue,
            "platform_profit": total_commissions,
            "total_refunds": total_refunds,
            "pending_payouts": total_revenue - total_commissions - total_refunds,
        }
        return Response(data, status=status.HTTP_200_OK)


@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def payment_webhook(request):
    """نقطة استقبال إشعارات بوابات الدفع الخارجية وتأكيد المعاملات آلياً"""
    payload = request.body
    try:
        import json
        event = json.loads(payload)
        
        if event.get('type') == 'payment_intent.succeeded':
            data = event.get('data', {}).get('object', {})
            gateway_ref = data.get('id')
            
            payment = Payment.objects.filter(gateway_reference=gateway_ref, status=Payment.PaymentStatus.PENDING).first()
            if payment:
                payment.status = Payment.PaymentStatus.COMPLETED
                payment.save()
                
                Transaction.objects.create(
                    payment=payment,
                    transaction_type=Transaction.TransactionType.CHARGE,
                    amount=payment.amount,
                    response_data=data
                )
                
                InvoiceService.generate_invoice_for_payment(payment)
                logger.info(f"Webhook successfully processed for payment {payment.id}")
                
        return HttpResponse(status=200)
    except Exception as e:
        logger.error(f"Webhook error: {str(e)}")
        return HttpResponse(status=400)