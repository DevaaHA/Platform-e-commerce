from django.shortcuts import get_object_or_404
from rest_framework import status, generics, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes, action
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from django.db import transaction 
from django.core.exceptions import ValidationError 

from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

# 1. استيراد نماذج المتجر الأساسية
from .models import (
    Product, Cart, CartItem, Order, OrderItem, Wishlist, WishlistItem, 
    SavedItem, User, UserProfile, Role, PermissionModel, Store, StoreSettings, 
    StoreSubscription, Inventory, InventoryTransaction, StoreOrder, Return,
    Coupon, Promotion
)

# 2. استيراد النماذج المالية من تطبيق payments المستقل
from payments.models import Payment, Wallet, Transaction as PaymentTransaction

# 3. استيراد الـ Serializers المحدثة
from .serializers import (
    RegisterSerializer, UserProfileSerializer, ProductSerializer, CartSerializer, CartItemSerializer, 
    OrderSerializer, StoreOrderSerializer, InvoiceSerializer, ReturnSerializer,
    WishlistSerializer, WishlistItemSerializer, SavedItemSerializer, UserSerializer,
    RoleSerializer, PermissionSerializer, StoreSerializer, StoreSettingsSerializer,
    StoreSubscriptionSerializer, InventorySerializer, InventoryTransactionSerializer,
    PaymentSerializer, WalletSerializer, CouponSerializer, ApplyCouponSerializer, PromotionSerializer
)

from .filters import ProductFilter

# 🚀 4. استيراد حراس الصلاحيات الأمنية (Role Guards)
from .permissions import (
    HasPermission, IsMerchant, IsDriver, IsSupervisor, IsAdmin, IsCustomer, IsAdminOrSupervisor
)

from .services import (
    log_action, StoreService, InventoryService, CartService, OrderService, 
    ReturnService, InvoiceService, PaymentService, WalletService, CouponService
)

# ==========================================
# 1. المصادقة، تسجيل الدخول، وتحديث الملف الشخصي
# ==========================================
class RegisterView(APIView):
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

    @transaction.atomic
    def post(self, request):
        serializer = self.serializer_class(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                "message": "تم إنشاء الحساب بنجاح", 
                "user_id": user.id,
                "email": user.email,
                "role": user.role # 🚀 الـ Role بيرجع للفرونت إند فوراً
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = 'email' 

    def validate(self, attrs):
        email = attrs.get("email") or attrs.get("username")
        if email:
            attrs['username'] = email 
        data = super().validate(attrs)
        
        # التوجيه الذكي: جلب الدور الفعلي للمستخدم وإرساله في الاستجابة للفرونت إند (مهم للـ RoleRouter)
        user_role = 'customer'
        if self.user:
            user_role = getattr(self.user, 'role', None) or 'customer'
        
        data['role'] = user_role
        data['email'] = self.user.email
        data['first_name'] = getattr(self.user, 'first_name', '')
        data['last_name'] = getattr(self.user, 'last_name', '')
        return data


class CustomLoginView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer
    permission_classes = [AllowAny]


class UserProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_object(self):
        profile, created = UserProfile.objects.get_or_create(user=self.request.user)
        return profile


# ==========================================
# 2. المنتجات والبحث
# ==========================================
class ProductListCreateView(generics.ListCreateAPIView):
    queryset = Product.objects.filter(is_active=True).select_related('store') if hasattr(Product, 'is_active') else Product.objects.all()
    serializer_class = ProductSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_class = ProductFilter
    
    # 🚀 حماية ذكية: السماح للجميع برؤية المنتجات، لكن الإضافة حصراً للتجار
    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsMerchant()]
        return [AllowAny()]


# ==========================================
# 3. إدارة السلة والزوار (Cart & Guest Sessions)
# ==========================================
class CartAPIView(APIView):
    permission_classes = [AllowAny]
    serializer_class = CartSerializer

    def get_cart(self, request):
        if request.user.is_authenticated:
            cart, _ = Cart.objects.prefetch_related('items__product').get_or_create(user=request.user, status='active')
            return cart
        else:
            session_id = request.headers.get('X-Session-ID') or request.session.session_key
            if not session_id:
                request.session.create()
                session_id = request.session.session_key
            cart, _ = Cart.objects.prefetch_related('items__product').get_or_create(session_id=session_id, status='active', user=None)
            return cart

    def get(self, request):
        cart = self.get_cart(request)
        return Response(self.serializer_class(cart).data)

    @transaction.atomic
    def delete(self, request):
        cart = self.get_cart(request)
        cart.items.all().delete()
        return Response({"message": "تم تفريغ السلة بنجاح"}, status=status.HTTP_204_NO_CONTENT)


class CartItemAPIView(APIView):
    permission_classes = [AllowAny]
    # ... (باقي دوال السلة كما هي بدون تغيير لأنها تدعم الزوار) ...
    def get_cart(self, request):
        if request.user.is_authenticated:
            cart, _ = Cart.objects.get_or_create(user=request.user, status='active')
            return cart
        else:
            session_id = request.headers.get('X-Session-ID') or request.session.session_key
            if not session_id:
                request.session.create()
                session_id = request.session.session_key
            cart, _ = Cart.objects.get_or_create(session_id=session_id, status='active', user=None)
            return cart

    @transaction.atomic
    def post(self, request):
        cart = self.get_cart(request)
        product_id = request.data.get('product_id') or request.data.get('product')
        quantity = int(request.data.get('quantity', 1))
        variant_id = request.data.get('variant_id') or request.data.get('variant')

        if quantity < 1:
            return Response({"error": "الكمية يجب أن تكون 1 على الأقل"}, status=status.HTTP_400_BAD_REQUEST)

        product = get_object_or_404(Product, id=product_id)
        inventory = Inventory.objects.filter(product=product).first()
        
        if not inventory or inventory.available_quantity < quantity:
            available = inventory.available_quantity if inventory else 0
            return Response({"error": f"الكمية المطلوبة غير متوفرة. المتاح: {available}"}, status=status.HTTP_400_BAD_REQUEST)

        cart_item, created = CartItem.objects.get_or_create(
            cart=cart, product=product, variant_id=variant_id,
            defaults={'store': product.store, 'unit_price': product.price, 'quantity': quantity}
        )

        if not created:
            new_quantity = cart_item.quantity + quantity
            if inventory.available_quantity < new_quantity:
                return Response({"error": "لا يوجد مخزون كافي."}, status=status.HTTP_400_BAD_REQUEST)
            cart_item.quantity = new_quantity
            cart_item.save()

        return Response(CartSerializer(cart).data, status=status.HTTP_201_CREATED)

    @transaction.atomic
    def patch(self, request, item_id):
        item = get_object_or_404(CartItem, id=item_id)
        quantity = int(request.data.get('quantity', 1))
        inventory = Inventory.objects.filter(product=item.product).first()
        if inventory and inventory.available_quantity < quantity:
            return Response({"error": "الكمية لا تكفي"}, status=status.HTTP_400_BAD_REQUEST)
        item.quantity = quantity
        item.save()
        return Response(CartItemSerializer(item).data)

    @transaction.atomic
    def delete(self, request, item_id):
        item = get_object_or_404(CartItem, id=item_id)
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class CartMergeAPIView(APIView):
    permission_classes = [IsAuthenticated]
    @transaction.atomic
    def post(self, request):
        session_id = request.data.get('session_id')
        if not session_id: return Response({"error": "session_id مطلوب"}, status=status.HTTP_400_BAD_REQUEST)
        merged_cart = CartService.merge_guest_cart(session_id, request.user)
        if merged_cart: return Response({"message": "تم الدمج", "cart": CartSerializer(merged_cart).data})
        return Response({"message": "لا توجد سلة ضيف"}, status=status.HTTP_200_OK)


# ==========================================
# 4. الطلبات، الدفع، والفواتير
# ==========================================
class CustomerOrderViewSet(viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated] # أي مستخدم مسجل يمكنه الشراء

    def get_queryset(self):
        return Order.objects.filter(customer=self.request.user).prefetch_related('items__product').order_by('-created_at')

    # ... (دوال create, cancel, request_return, invoice, pay كما هي) ...

class StoreOrderViewSet(viewsets.ModelViewSet):
    serializer_class = StoreOrderSerializer
    # 🚀 حماية: فقط التاجر يستطيع الوصول لطلبات المتجر وإدارتها
    permission_classes = [IsMerchant]

    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'store') and user.store:
            return StoreOrder.objects.filter(store=user.store).order_by('-created_at')
        return StoreOrder.objects.none()

    @action(detail=True, methods=['patch'])
    @transaction.atomic
    def update_status(self, request, pk=None):
        store_order = self.get_object()
        new_status = request.data.get('status')
        notes = request.data.get('notes', '')
        try:
            OrderService.update_order_status(store_order.order, new_status, request.user, notes)
            store_order.status = new_status
            store_order.save()
            return Response(StoreOrderSerializer(store_order).data)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class ReturnManagementViewSet(viewsets.ModelViewSet):
    serializer_class = ReturnSerializer
    permission_classes = [IsAuthenticated] # العميل يشوف طلبات الاسترجاع الخاصة فيه

    def get_queryset(self):
        return Return.objects.filter(customer=self.request.user).order_by('-created_at')

    # 🚀 حماية: الموافقة أو الرفض فقط للتاجر
    @action(detail=True, methods=['patch'], permission_classes=[IsMerchant])
    @transaction.atomic
    def approve(self, request, pk=None):
        return_obj = self.get_object()
        try:
            processed = ReturnService.process_return(return_obj, 'APPROVE', request.user)
            return Response(ReturnSerializer(processed).data)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=True, methods=['patch'], permission_classes=[IsMerchant])
    @transaction.atomic
    def reject(self, request, pk=None):
        return_obj = self.get_object()
        try:
            processed = ReturnService.process_return(return_obj, 'REJECT', request.user)
            return Response(ReturnSerializer(processed).data)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


# ==========================================
# 5. المفضلة (Wishlist) والمحافظ (Wallets)
# ==========================================
class WishlistView(APIView):
    permission_classes = [IsAuthenticated]
    # ... (كما هي) ...

class WalletAPIView(APIView):
    permission_classes = [IsAuthenticated]
    # ... (كما هي) ...


# ==========================================
# 6. إدارة المتاجر
# ==========================================
class StoreViewSet(viewsets.ModelViewSet):
    queryset = Store.objects.all().order_by('-created_at')
    serializer_class = StoreSerializer
    
    # 🚀 حماية: الجميع يمكنه استعراض المتاجر، لكن الإنشاء والتعديل للتجار
    def get_permissions(self):
        if self.request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            return [IsMerchant()]
        return [AllowAny()]

    def get_queryset(self):
        if self.request.method == 'GET' and 'pk' not in self.kwargs:
            return Store.objects.all() # الزوار والعملاء بيشوفوا كل المتاجر
        return Store.objects.filter(owner=self.request.user) # التاجر بيدير متجره بس

    @transaction.atomic
    def perform_create(self, serializer):
        StoreService.create_store(user=self.request.user, data=serializer.validated_data, request=self.request)


# ==========================================
# 7. إدارة المخزون (Inventory)
# ==========================================
class InventoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Inventory.objects.all()
    serializer_class = InventorySerializer
    permission_classes = [IsMerchant] # 🚀 حماية: المخزون سري للتاجر فقط

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def adjust(self, request, pk=None):
        try:
            inventory = InventoryService.adjust_stock(
                inventory_id=self.get_object().id,
                amount=int(request.data.get('amount', 0)),
                user=request.user,
                action_type=request.data.get('action_type'), 
                reason=request.data.get('reason', '')
            )
            return Response({"message": "تم تعديل المخزون بنجاح", "new_quantity": inventory.quantity})
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class InventoryTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = InventoryTransaction.objects.all().order_by('-created_at')
    serializer_class = InventoryTransactionSerializer
    permission_classes = [IsMerchant] # 🚀 حماية: التاجر فقط يرى حركات المخزون


# ==========================================
# 8. إعدادات النظام والمساعدة
# ==========================================
class StoreSettingsView(generics.RetrieveUpdateAPIView):
    queryset = StoreSettings.objects.all()
    serializer_class = StoreSettingsSerializer
    permission_classes = [IsMerchant] # 🚀 حماية
    lookup_field = 'store_id'


class StoreSubscriptionView(generics.RetrieveAPIView):
    queryset = StoreSubscription.objects.all()
    serializer_class = StoreSubscriptionSerializer
    permission_classes = [IsMerchant] # 🚀 حماية
    lookup_field = 'store_id'


# ==========================================
# 9. الكوبونات والخصومات
# ==========================================
class CouponViewSet(viewsets.ModelViewSet):
    serializer_class = CouponSerializer
    
    # 🚀 حماية: العملاء بيقدروا يشوفوا الكوبونات المتاحة، بس التاجر هو اللي بيضيفها
    def get_permissions(self):
        if self.request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            return [IsMerchant()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'store') and user.store:
            return Coupon.objects.filter(store=user.store).order_by('-created_at')
        return Coupon.objects.filter(status='ACTIVE') # العميل بيشوف الفعّال فقط

    def perform_create(self, serializer):
        store = self.request.user.store if not self.request.user.is_superuser else serializer.validated_data.get('store')
        serializer.save(store=store)


class ApplyCouponView(APIView):
    permission_classes = [IsAuthenticated] # أي مشتري بيقدر يطبق الكوبون
    # ... (نفس الكود) ...

class PromotionViewSet(viewsets.ModelViewSet):
    serializer_class = PromotionSerializer
    
    # 🚀 حماية الإعلانات والعروض
    def get_permissions(self):
        if self.request.method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            return [IsMerchant()]
        return [AllowAny()]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'store') and user.store:
            return Promotion.objects.filter(store=user.store)
        return Promotion.objects.filter(status='ACTIVE')