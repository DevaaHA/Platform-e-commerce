import json
import uuid
from decimal import Decimal
from datetime import timedelta
from django.utils import timezone
from django.db import transaction
from django.core.exceptions import ValidationError

# 1. استيراد نماذج المتجر الأساسية
from .models import (
    Store, StoreSettings, StoreSubscription, 
    Inventory, InventoryTransaction, InventoryAlert,
    Cart, CartItem, Order, StoreOrder, OrderItem,
    OrderStatusHistory, Invoice, Return,
    Coupon, CouponUsage, Promotion, PromotionItem, DiscountRule
)

# 2. استيراد نماذج المدفوعات والتدقيق من تطبيقاتها المستقلة (Microservices)
from payments.models import Payment, Transaction as PaymentTransaction, Wallet
from audit_monitor.models import AuditLog


# --- خدمة سجل العمليات (Audit Log Service) ---
def log_action(user, module, action, entity_type, entity_id, old_values=None, new_values=None, request=None):
    ip_address = request.META.get('REMOTE_ADDR') if request else '0.0.0.0'
    user_agent = request.META.get('HTTP_USER_AGENT', '') if request else 'Unknown'
    
    AuditLog.objects.create(
        user=user,
        module=module,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        old_values=old_values,
        new_values=new_values,
        ip_address=ip_address,
        user_agent=user_agent
    )


# --- خدمات إدارة المتاجر (Store Services) ---
class StoreService:
    @staticmethod
    def create_store(user, data, request=None):
        store = Store.objects.create(owner=user, **data)
        
        StoreSettings.objects.create(
            store=store,
            minimum_order=5.00,
            delivery_fee=2.00,
            preparation_time=30
        )
        
        start_date = timezone.now().date()
        end_date = start_date + timedelta(days=14)
        StoreSubscription.objects.create(
            store=store,
            plan_name='Trial',
            start_date=start_date,
            end_date=end_date,
            commission=5.00,
            max_products=100,
            max_staff=5
        )
        
        if request:
            log_action(user, 'Stores', 'Create', 'Store', store.id, new_values=data, request=request)
            
        return store

    @staticmethod
    def approve_store(store, admin_user, request=None):
        store.status = 'Active'
        store.save()
        if request:
            log_action(admin_user, 'Stores', 'Approve', 'Store', store.id, request=request)
        return store

    @staticmethod
    def suspend_store(store, admin_user, request=None):
        store.status = 'Suspended'
        store.save()
        if request:
            log_action(admin_user, 'Stores', 'Suspend', 'Store', store.id, request=request)
        return store


# --- خدمات إدارة المخزون (Inventory Services) ---
class InventoryService:
    @staticmethod
    def _check_and_create_alert(inventory):
        if inventory.available_quantity <= 0:
            InventoryAlert.objects.create(
                inventory=inventory, 
                alert_type='OUT_OF_STOCK', 
                message='المنتج نفد من المخزون.'
            )
        elif inventory.available_quantity <= inventory.minimum_quantity:
            InventoryAlert.objects.create(
                inventory=inventory, 
                alert_type='LOW_STOCK', 
                message=f'مخزون منخفض ({inventory.available_quantity} متبقي).'
            )

    @staticmethod
    @transaction.atomic
    def adjust_stock(inventory_id, amount, user, action_type, reason="", ref_type=None, ref_id=None):
        inventory = Inventory.objects.select_for_update().get(id=inventory_id)
        old_quantity = inventory.quantity

        if action_type == 'ADD':
            inventory.quantity += amount
            diff = amount
            trans_type = 'ADD'
        elif action_type == 'DEDUCT':
            if inventory.available_quantity < amount:
                raise ValidationError("الكمية المتاحة لا تكفي.")
            inventory.quantity -= amount
            diff = -amount
            trans_type = 'DEDUCT'
        elif action_type == 'SET':
            if amount < 0: 
                raise ValidationError("الكمية لا يمكن أن تكون سالبة.")
            diff = amount - old_quantity
            inventory.quantity = amount
            trans_type = 'ADJUST'

        inventory.save()
        if diff != 0:
            InventoryTransaction.objects.create(
                inventory=inventory, 
                transaction_type=trans_type,
                previous_quantity=old_quantity, 
                new_quantity=inventory.quantity,
                difference=diff, 
                reference_type=ref_type, 
                reference_id=ref_id,
                reason=reason, 
                created_by=user
            )
        InventoryService._check_and_create_alert(inventory)
        return inventory

    @staticmethod
    @transaction.atomic
    def process_reservation(inventory_id, amount, action='RESERVE', ref_type="ORDER", ref_id=None):
        inventory = Inventory.objects.select_for_update().get(id=inventory_id)
        old_reserved = inventory.reserved_quantity

        if action == 'RESERVE':
            if inventory.available_quantity < amount: 
                raise ValidationError("الكمية المتاحة لا تكفي للحجز.")
            inventory.reserved_quantity += amount
            diff = amount
        elif action == 'RELEASE':
            if inventory.reserved_quantity < amount: 
                raise ValidationError("الكمية المحجوزة أقل من المطلوب تحريره.")
            inventory.reserved_quantity -= amount
            diff = -amount

        inventory.save()
        InventoryTransaction.objects.create(
            inventory=inventory, 
            transaction_type=action,
            previous_quantity=old_reserved, 
            new_quantity=inventory.reserved_quantity,
            difference=diff, 
            reference_type=ref_type, 
            reference_id=ref_id, 
            reason=f"{action} عملية حجز"
        )
        return inventory


# ==========================================
# 7. خدمات السلة والتسعير (Cart & Pricing Services)
# ==========================================

class PricingService:
    @staticmethod
    def calculate_cart_totals(cart):
        items = cart.items.all()
        
        subtotal = sum(item.unit_price * item.quantity for item in items)
        total_discount = sum(item.discount * item.quantity for item in items)
        
        net_products = subtotal - total_discount
        tax_rate = Decimal('0.05')
        taxes = net_products * tax_rate
        
        shipping_fee = Decimal('3.00') if items.exists() else Decimal('0.00')
        grand_total = net_products + taxes + shipping_fee
        
        return {
            'subtotal': round(subtotal, 2),
            'discount': round(total_discount, 2),
            'taxes': round(taxes, 2),
            'shipping_fee': round(shipping_fee, 2),
            'grand_total': round(grand_total, 2)
        }

class CartService:
    @staticmethod
    @transaction.atomic
    def merge_guest_cart(session_id, user):
        try:
            guest_cart = Cart.objects.get(session_id=session_id, status='active', user__isnull=True)
            user_cart, created = Cart.objects.get_or_create(user=user, status='active')
            
            for item in guest_cart.items.all():
                existing_item = user_cart.items.filter(product=item.product, variant=item.variant).first()
                
                if existing_item:
                    existing_item.quantity += item.quantity
                    existing_item.save()
                else:
                    item.cart = user_cart
                    item.save()
            
            guest_cart.delete()
            return user_cart
            
        except Cart.DoesNotExist:
            return None


# ==========================================
# 8. خدمات الطلبات وإدارة دورة الحياة
# ==========================================

class OrderWorkflowEngine:
    VALID_TRANSITIONS = {
        'Pending': ['Confirmed', 'Cancelled'],
        'Confirmed': ['Preparing', 'Cancelled'],
        'Preparing': ['Ready For Pickup', 'Cancelled'],
        'Ready For Pickup': ['Driver Assigned'],
        'Driver Assigned': ['Picked Up'],
        'Picked Up': ['On The Way'],
        'On The Way': ['Delivered'],
        'Delivered': ['Returned'],
        'Cancelled': [],
        'Returned': []
    }

    @staticmethod
    def can_transition(current_status, new_status):
        return new_status in OrderWorkflowEngine.VALID_TRANSITIONS.get(current_status, [])

class InvoiceService:
    @staticmethod
    def generate_invoice(order):
        invoice_number = f"INV-{order.order_number}"
        invoice, created = Invoice.objects.get_or_create(
            order=order,
            defaults={
                'invoice_number': invoice_number,
                'amount': order.total,
                'pdf_file': f"invoices/{invoice_number}.pdf"
            }
        )
        return invoice

class OrderService:
    @staticmethod
    @transaction.atomic
    def create_order_from_cart(user, cart, address_id=None):
        items = cart.items.all()
        if not items.exists():
            raise ValidationError("السلة فارغة.")

        for item in items:
            inventory = Inventory.objects.filter(product=item.product).first()
            if not inventory or inventory.available_quantity < item.quantity:
                raise ValidationError(f"الكمية غير متوفرة للمنتج: {item.product.name}")

        totals = PricingService.calculate_cart_totals(cart)
        order_number = f"ORD-{uuid.uuid4().hex[:8].upper()}"

        order = Order.objects.create(
            order_number=order_number,
            customer=user,
            status='Pending',
            payment_status='Pending',
            subtotal=totals['subtotal'],
            discount=totals['discount'],
            tax=totals['taxes'],
            delivery_fee=totals['shipping_fee'],
            total=totals['grand_total'],
            address_id=address_id
        )

        store_items_map = {}
        for item in items:
            store_id = item.store_id
            if store_id not in store_items_map:
                store_items_map[store_id] = []
            store_items_map[store_id].append(item)

        for store_id, store_cart_items in store_items_map.items():
            store_subtotal = sum(i.subtotal for i in store_cart_items)
            commission = store_subtotal * Decimal('0.05')
            store_amount = store_subtotal - commission

            StoreOrder.objects.create(
                order=order,
                store_id=store_id,
                status='Pending',
                subtotal=store_subtotal,
                commission=commission,
                store_amount=store_amount
            )

            for item in store_cart_items:
                OrderItem.objects.create(
                    order=order,
                    product=item.product,
                    variant=item.variant,
                    quantity=item.quantity,
                    price=item.unit_price,
                    subtotal=item.subtotal
                )

                inventory = Inventory.objects.filter(product=item.product).first()
                if inventory:
                    InventoryService.adjust_stock(
                        inventory_id=inventory.id,
                        amount=item.quantity,
                        user=user,
                        action_type='DEDUCT',
                        reason=f"إتمام طلب رقم {order.order_number}",
                        ref_type='ORDER',
                        ref_id=order.id
                    )

        OrderStatusHistory.objects.create(
            order=order,
            old_status=None,
            new_status='Pending',
            changed_by=user,
            notes='تم إنشاء الطلب بنجاح'
        )

        InvoiceService.generate_invoice(order)

        cart.status = 'converted'
        cart.save()

        return order

    @staticmethod
    @transaction.atomic
    def update_order_status(order, new_status, user, notes=""):
        old_status = order.status
        if not OrderWorkflowEngine.can_transition(old_status, new_status):
            raise ValidationError(f"غير مسموح الانتقال من الحالة {old_status} إلى {new_status}")

        order.status = new_status
        order.save()

        OrderStatusHistory.objects.create(
            order=order,
            old_status=old_status,
            new_status=new_status,
            changed_by=user,
            notes=notes
        )

        if new_status == 'Cancelled':
            for item in order.items.all():
                inventory = Inventory.objects.filter(product=item.product).first()
                if inventory:
                    InventoryService.adjust_stock(
                        inventory_id=inventory.id,
                        amount=item.quantity,
                        user=user,
                        action_type='ADD',
                        reason=f"إلغاء طلب رقم {order.order_number}",
                        ref_type='ORDER_CANCEL',
                        ref_id=order.id
                    )

        return order

class ReturnService:
    @staticmethod
    @transaction.atomic
    def request_return(order, customer, reason):
        if order.status != 'Delivered':
            raise ValidationError("لا يمكن طلب إسترجاع إلا للطلبات المسلمة فقط.")
        
        return_obj, created = Return.objects.get_or_create(
            order=order,
            customer=customer,
            defaults={'reason': reason, 'status': 'Pending'}
        )
        if not created:
            raise ValidationError("يوجد طلب استرجاع مسبق لهذا الطلب.")
        return return_obj

    @staticmethod
    @transaction.atomic
    def process_return(return_obj, action, admin_user):
        if action == 'APPROVE':
            return_obj.status = 'Approved'
            return_obj.approved_by = admin_user
            return_obj.save()

            order = return_obj.order
            order.status = 'Returned'
            order.save()

            for item in order.items.all():
                inventory = Inventory.objects.filter(product=item.product).first()
                if inventory:
                    InventoryService.adjust_stock(
                        inventory_id=inventory.id,
                        amount=item.quantity,
                        user=admin_user,
                        action_type='ADD',
                        reason=f"قبول استرجاع طلب رقم {order.order_number}",
                        ref_type='RETURN',
                        ref_id=return_obj.id
                    )
        elif action == 'REJECT':
            return_obj.status = 'Rejected'
            return_obj.approved_by = admin_user
            return_obj.save()
        else:
            raise ValidationError("إجراء غير صالح.")
        
        return return_obj


# ==========================================
# 9. خدمات الدفع والمحافظ (Payment & Wallet Services)
# ==========================================

class PaymentService:
    @staticmethod
    @transaction.atomic
    def process_payment(order, payment_method_code, amount=None, token=None):
        amount_to_pay = amount if amount is not None else order.total
        
        payment = Payment.objects.create(
            order=order,
            amount=amount_to_pay,
            payment_method_code=payment_method_code,
            status='PENDING'
        )

        gateway_response = PaymentService._call_gateway_adapter(payment_method_code, amount_to_pay, token)

        PaymentTransaction.objects.create(
            payment=payment,
            transaction_id=gateway_response.get('transaction_id', str(uuid.uuid4())),
            gateway=payment_method_code,
            amount=amount_to_pay,
            status=gateway_response.get('status', 'FAILED'),
            response_message=gateway_response.get('message', '')
        )

        if gateway_response.get('status') == 'SUCCESS':
            payment.status = 'COMPLETED'
            payment.save()
            
            order.payment_status = 'Paid'
            order.save()
            
            return payment, True
        else:
            payment.status = 'FAILED'
            payment.save()
            raise ValidationError(f"فشل عملية الدفع: {gateway_response.get('message', 'خطأ غير معروف')}")

    @staticmethod
    def _call_gateway_adapter(method_code, amount, token):
        if method_code == 'COD':
            return {'status': 'SUCCESS', 'transaction_id': f"COD-{uuid.uuid4().hex[:8]}", 'message': 'تم تسجيل الطلب للدفع عند الاستلام'}
        elif method_code in ['STRIPE', 'PAYPAL', 'CREDIT_CARD']:
            if token == 'invalid_token':
                return {'status': 'FAILED', 'message': 'رمز الدفع غير صالح أو منتهي الصلاحية'}
            return {'status': 'SUCCESS', 'transaction_id': f"GW-{uuid.uuid4().hex[:10]}", 'message': 'تمت عملية الدفع الكترونياً بنجاح'}
        elif method_code == 'WALLET':
            return {'status': 'SUCCESS', 'transaction_id': f"WAL-{uuid.uuid4().hex[:8]}", 'message': 'تم خصم المبلغ من المحفظة بنجاح'}
        return {'status': 'FAILED', 'message': 'طريقة دفع غير مدعومة'}


class WalletService:
    @staticmethod
    def get_or_create_wallet(user):
        wallet, _ = Wallet.objects.get_or_create(user=user)
        return wallet

    @staticmethod
    @transaction.atomic
    def deposit(user, amount, description="إيداع رصيد"):
        amount = Decimal(str(amount))
        if amount <= 0:
            raise ValidationError("مبلغ الإيداع يجب أن يكون أكبر من صفر.")
        wallet = WalletService.get_or_create_wallet(user)
        wallet.balance += amount
        wallet.save()
        return wallet

    @staticmethod
    @transaction.atomic
    def withdraw(user, amount, description="سحب رصيد"):
        amount = Decimal(str(amount))
        if amount <= 0:
            raise ValidationError("مبلغ السحب يجب أن يكون أكبر من صفر.")
        wallet = WalletService.get_or_create_wallet(user)
        if wallet.balance < amount:
            raise ValidationError("رصيد المحفظة غير كافٍ لإتمام العملية.")
        wallet.balance -= amount
        wallet.save()
        return wallet


# ==========================================
# 10. محرك الخصومات وإدارة الكوبونات
# ==========================================

class DiscountEngine:
    @staticmethod
    def calculate_discount(amount, coupon):
        discount = Decimal('0.00')
        amount_decimal = Decimal(str(amount))
        
        if coupon.type == 'FIXED':
            discount = Decimal(str(coupon.value))
        elif coupon.type == 'PERCENTAGE':
            discount = (amount_decimal * Decimal(str(coupon.value))) / Decimal('100.00')
            if coupon.max_discount:
                discount = min(discount, Decimal(str(coupon.max_discount)))
        elif coupon.type == 'FREE_DELIVERY':
            pass 
            
        return min(discount, amount_decimal)


class CouponService:
    @staticmethod
    def validate_coupon(code, user, cart_subtotal):
        try:
            coupon = Coupon.objects.get(code__iexact=code, status='ACTIVE')
        except Coupon.DoesNotExist:
            raise ValidationError("الكوبون غير صحيح أو غير فعال.")

        now = timezone.now()
        if coupon.start_date > now or coupon.end_date < now:
            raise ValidationError("الكوبون منتهي الصلاحية أو لم يبدأ بعد.")

        if Decimal(str(cart_subtotal)) < Decimal(str(coupon.minimum_order)):
            raise ValidationError(f"يجب أن تكون قيمة الطلب على الأقل {coupon.minimum_order} لتطبيق هذا الكوبون.")

        if coupon.usage_limit and coupon.used_count >= coupon.usage_limit:
            raise ValidationError("عذراً، تم تجاوز الحد الأقصى لاستخدام هذا الكوبون من قبل المستخدمين.")

        user_usage_count = CouponUsage.objects.filter(coupon=coupon, user=user).count()
        if user_usage_count >= coupon.usage_limit_per_user:
            raise ValidationError("لقد قمت باستخدام هذا الكوبون الحد الأقصى من المرات المسموحة لك.")

        return coupon

    @staticmethod
    def apply_coupon(cart, code, user):
        subtotal = sum(item.unit_price * item.quantity for item in cart.items.all())
        coupon = CouponService.validate_coupon(code, user, subtotal)
        discount_amount = DiscountEngine.calculate_discount(subtotal, coupon)
        
        return {
            "coupon_id": coupon.id,
            "coupon_code": coupon.code,
            "type": coupon.type,
            "subtotal": round(subtotal, 2),
            "discount_amount": round(discount_amount, 2),
            "new_total": round(Decimal(str(subtotal)) - discount_amount, 2)
        }

    @staticmethod
    def record_usage(coupon_id, user, order, discount_amount):
        with transaction.atomic():
            coupon = Coupon.objects.select_for_update().get(id=coupon_id)
            CouponUsage.objects.create(
                coupon=coupon,
                user=user,
                order=order,
                discount_amount=discount_amount
            )
            coupon.used_count += 1
            coupon.save()