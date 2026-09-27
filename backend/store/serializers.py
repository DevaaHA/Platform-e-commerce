from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from .models import (
    User, UserProfile, Product, ProductVariant, Cart, CartItem, Order, OrderItem, Wishlist, WishlistItem, SavedItem,
    Role, PermissionModel, Store, StoreSettings, 
    StoreHours, StoreEmployees, StoreSubscription,
    Warehouse, Inventory, InventoryTransaction, InventoryAlert,
    StoreOrder, OrderStatusHistory, Invoice, Return,
    Coupon, Promotion, PromotionItem
)
# استيراد النماذج المفصولة من تطبيقاتها المستقلة مع استخدام Alias دقيق
from payments.models import Payment, Transaction as PaymentTransaction, Wallet
from audit_monitor.models import AuditLog

from .services import PricingService

# ==========================================
# 1. المصادقة والمستخدمين والملف الشخصي
# ==========================================

class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    first_name = serializers.CharField(required=True)
    last_name = serializers.CharField(required=True)
    role = serializers.CharField(required=False, default='customer')

    class Meta:
        model = User
        fields = ['username', 'email', 'phone', 'password', 'first_name', 'last_name', 'role']

    def validate_role(self, value):
        """
        🚀 حماية أمنية: منع إنشاء حسابات إدارية من خلال الـ API العام
        """
        forbidden_roles = ['admin', 'supervisor']
        if value in forbidden_roles:
            raise ValidationError("غير مسموح بإنشاء حسابات إدارية من هذه الواجهة.")
        
        # التاجر والدرايفر مسموح يسجلوا، بس المفروض يكون حسابهم "غير مفعل" للعمل حتى يوافق الإدمن
        allowed_roles = ['customer', 'store_admin', 'driver']
        if value not in allowed_roles:
            return 'customer' # القيمة الافتراضية
            
        return value

    def create(self, validated_data):
        role_val = validated_data.pop('role', 'customer')
        password = validated_data.pop('password')
        
        # إنشاء المستخدم باستخدام مدير المستخدمين المخصص وحفظ كلمة المرور مشفرة
        user = User.objects.create_user(password=password, **validated_data)
        user.role = role_val
        user.save()
        return user

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'role', 'phone', 'store']

# 🚀 السيريلايزر الجديد الخاص بشاشة البروفايل (يدمج User و UserProfile)
class UserProfileSerializer(serializers.ModelSerializer):
    # سحب الحقول من جدول User
    first_name = serializers.CharField(source='user.first_name', required=False)
    last_name = serializers.CharField(source='user.last_name', required=False)
    email = serializers.EmailField(source='user.email', read_only=True)
    phone = serializers.CharField(source='user.phone', required=False)
    role = serializers.CharField(source='user.role', read_only=True)
    avatar = serializers.ImageField(source='user.avatar', required=False)

    class Meta:
        model = UserProfile
        fields = [
            'first_name', 'last_name', 'email', 'phone', 'role', 'avatar',
            'city', 'major', 'wallet_balance', 'points', 'coupons_count'
        ]
        # حماية الحقول المالية من التعديل اليدوي من التطبيق
        read_only_fields = ['wallet_balance', 'points', 'coupons_count', 'role', 'email']

    def update(self, instance, validated_data):
        # 1. تحديث بيانات User
        user_data = validated_data.pop('user', {})
        user = instance.user

        if 'first_name' in user_data:
            user.first_name = user_data['first_name']
        if 'last_name' in user_data:
            user.last_name = user_data['last_name']
        if 'phone' in user_data:
            user.phone = user_data['phone']
        if 'avatar' in user_data:
            user.avatar = user_data['avatar']
        
        user.save()

        # 2. تحديث بيانات UserProfile
        instance.city = validated_data.get('city', instance.city)
        instance.major = validated_data.get('major', instance.major)
        instance.save()

        return instance


# ==========================================
# 2. الأدوار والصلاحيات وسجل العمليات
# ==========================================
class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = '__all__'

class PermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PermissionModel
        fields = '__all__'

class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = '__all__'


# ==========================================
# 3. المنتجات، النسخ، والمخزون
# ==========================================
class ProductVariantSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariant
        fields = '__all__'

class ProductSerializer(serializers.ModelSerializer):
    variants = ProductVariantSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        fields = '__all__'

class WarehouseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Warehouse
        fields = '__all__'

class InventorySerializer(serializers.ModelSerializer):
    available_quantity = serializers.ReadOnlyField()
    product_name = serializers.ReadOnlyField(source='product.name')
    sku = serializers.ReadOnlyField(source='variant.sku')

    class Meta:
        model = Inventory
        fields = '__all__'

class InventoryTransactionSerializer(serializers.ModelSerializer):
    created_by_name = serializers.ReadOnlyField(source='created_by.first_name')

    class Meta:
        model = InventoryTransaction
        fields = '__all__'

class InventoryAlertSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='inventory.product.name')

    class Meta:
        model = InventoryAlert
        fields = '__all__'


# ==========================================
# 4. السلة، الطلبات، المتاجر المتعددة، والمفضلة
# ==========================================
class CartItemSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')
    store_name = serializers.ReadOnlyField(source='store.name_ar')

    class Meta:
        model = CartItem
        fields = [
            'id', 'cart', 'product', 'product_name', 'variant', 
            'store', 'store_name', 'quantity', 'unit_price', 
            'discount', 'subtotal', 'created_at'
        ]
        read_only_fields = ['subtotal', 'unit_price', 'store']

class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    totals = serializers.SerializerMethodField()

    class Meta:
        model = Cart
        fields = ['id', 'user', 'session_id', 'status', 'items', 'totals', 'created_at', 'updated_at']

    def get_totals(self, obj):
        return PricingService.calculate_cart_totals(obj)

class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')

    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'product_name', 'variant', 'quantity', 'price', 'subtotal']

class StoreOrderSerializer(serializers.ModelSerializer):
    store_name = serializers.ReadOnlyField(source='store.name_ar')
    
    class Meta:
        model = StoreOrder
        fields = ['id', 'order', 'store', 'store_name', 'status', 'subtotal', 'commission', 'store_amount', 'created_at']

class OrderStatusHistorySerializer(serializers.ModelSerializer):
    changed_by_name = serializers.ReadOnlyField(source='changed_by.first_name')

    class Meta:
        model = OrderStatusHistory
        fields = ['id', 'order', 'old_status', 'new_status', 'changed_by_name', 'notes', 'created_at']

class InvoiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Invoice
        fields = ['id', 'order', 'invoice_number', 'pdf_file', 'amount', 'created_at']

class ReturnSerializer(serializers.ModelSerializer):
    customer_name = serializers.ReadOnlyField(source='customer.first_name')

    class Meta:
        model = Return
        fields = ['id', 'order', 'customer', 'customer_name', 'reason', 'status', 'approved_by', 'created_at']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    store_orders = StoreOrderSerializer(many=True, read_only=True)
    status_history = OrderStatusHistorySerializer(many=True, read_only=True)
    invoice = InvoiceSerializer(read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'customer', 'status', 'payment_status',
            'subtotal', 'discount', 'tax', 'delivery_fee', 'total',
            'address_id', 'items', 'store_orders', 'status_history', 'invoice', 'created_at'
        ]

class WishlistItemSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')
    product_price = serializers.ReadOnlyField(source='product.price')

    class Meta:
        model = WishlistItem
        fields = ['id', 'product', 'product_name', 'product_price', 'created_at']

class WishlistSerializer(serializers.ModelSerializer):
    items = WishlistItemSerializer(many=True, read_only=True)

    class Meta:
        model = Wishlist
        fields = ['id', 'user', 'items', 'created_at']

class SavedItemSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')

    class Meta:
        model = SavedItem
        fields = ['id', 'product', 'product_name', 'created_at']


# ==========================================
# 5. المتاجر وإعداداتها
# ==========================================
class StoreSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreSettings
        fields = '__all__'
        read_only_fields = ['store']

class StoreHoursSerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreHours
        fields = '__all__'
        read_only_fields = ['store']

class StoreSubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreSubscription
        fields = '__all__'
        read_only_fields = ['store']

class StoreSerializer(serializers.ModelSerializer):
    settings = StoreSettingsSerializer(read_only=True)
    hours = StoreHoursSerializer(many=True, read_only=True)
    subscription = StoreSubscriptionSerializer(read_only=True)

    class Meta:
        model = Store
        fields = '__all__'
        read_only_fields = ['owner', 'status', 'created_at']


# ==========================================
# 6. المدفوعات والمحافظ (نظام الدفع الآمن)
# ==========================================
class PaymentTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentTransaction
        fields = '__all__'

class PaymentSerializer(serializers.ModelSerializer):
    transactions = PaymentTransactionSerializer(many=True, read_only=True)
    
    class Meta:
        model = Payment
        fields = '__all__'

class WalletSerializer(serializers.ModelSerializer):
    user = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = Wallet
        fields = ['id', 'user', 'balance']


# ==========================================
# 7. الكوبونات والخصومات
# ==========================================
class CouponSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coupon
        fields = '__all__'
        read_only_fields = ['id', 'used_count', 'created_at']

class ApplyCouponSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=50)

class PromotionItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromotionItem
        fields = '__all__'

class PromotionSerializer(serializers.ModelSerializer):
    items = PromotionItemSerializer(many=True, read_only=True)
    
    class Meta:
        model = Promotion
        fields = '__all__'