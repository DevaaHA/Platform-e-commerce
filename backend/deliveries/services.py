import math
from decimal import Decimal
from django.utils import timezone
from .models import Driver, DeliveryOrder, DriverEarnings

class DeliveryMatchingEngine:
    @staticmethod
    def find_best_driver(store_lat, store_lng):
        """
        خوارزمية مطابقة الكباتن:
        تبحث عن الكباتن المتاحين وتختار الأفضل بناءً على المسافة والتقييم.
        """
        available_drivers = Driver.objects.filter(
            status=Driver.DriverStatus.AVAILABLE,
            current_lat__isnull=False,
            current_lng__isnull=False
        )

        if not available_drivers.exists():
            return None

        best_driver = None
        min_score = float('inf')

        for driver in available_drivers:
            # حساب المسافة التقريبية باستخدام قانون هافرساين (Haversine Formula)
            distance = DeliveryMatchingEngine._calculate_distance(
                float(store_lat), float(store_lng), 
                float(driver.current_lat), float(driver.current_lng)
            )

            # المعادلة التنافسية: نوزن المسافة مع التقييم (المسافة الأقصر والتقييم الأعلى يفوزان)
            # Score = Distance (km) - (Rating * 0.5)
            score = distance - (float(driver.rating) * 0.5)

            if score < min_score:
                min_score = score
                best_driver = driver

        return best_driver

    @staticmethod
    def _calculate_distance(lat1, lon1, lat2, lon2):
        """حساب المسافة بالكيلومتر بين نقطتين جغرافيتين"""
        R = 6371.0  # نصف قطر الأرض بالكم
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
        c = 2 * math.asin(math.sqrt(a))
        return R * c

class DeliveryService:
    @staticmethod
    def assign_order_to_driver(order, store_lat, store_lng):
        """تعيين الطلب تلقائياً لأفضل كابتن متاح"""
        driver = DeliveryMatchingEngine.find_best_driver(store_lat, store_lng)
        
        if not driver:
            # يبقى الطلب في حالة البحث لحين توفر كابتن
            return None

        delivery, created = DeliveryOrder.objects.get_or_create(
            order=order,
            defaults={
                'driver': driver,
                'status': DeliveryOrder.DeliveryStatus.ASSIGNED,
                'assigned_at': timezone.now()
            }
        )

        if not created and delivery.status == DeliveryOrder.DeliveryStatus.FINDING:
            delivery.driver = driver
            delivery.status = DeliveryOrder.DeliveryStatus.ASSIGNED
            delivery.assigned_at = timezone.now()
            delivery.save()

        # تحويل حالة الكابتن إلى مشغول
        driver.status = Driver.DriverStatus.BUSY
        driver.save()

        return delivery

    @staticmethod
    def complete_delivery(delivery_order):
        """إنهاء رحلة التوصيل وحساب أرباح الكابتن"""
        delivery_order.status = DeliveryOrder.DeliveryStatus.DELIVERED
        delivery_order.delivered_at = timezone.now()
        delivery_order.save()

        # تحرير الكابتن ليصبح متاحاً لطلب جديد
        driver = delivery_order.driver
        if driver:
            driver.status = Driver.DriverStatus.AVAILABLE
            driver.save()

            # تسجيل أرباح التوصيل للكابتن (مثال: 3.50 JOD ثابتة أو حسب المسافة)
            DriverEarnings.objects.create(
                driver=driver,
                order=delivery_order.order,
                amount=Decimal('3.50'),
                status=DriverEarnings.EarningStatus.PENDING
            )

        return True