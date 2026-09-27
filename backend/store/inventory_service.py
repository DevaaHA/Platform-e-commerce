from django.db import transaction
from django.core.exceptions import ValidationError
from .models import Inventory, InventoryTransaction, InventoryAlert

class InventoryService:
    @staticmethod
    def adjust_stock(inventory_id, quantity, transaction_type, reason, user):
        """
        تعديل المخزون (إضافة، خصم، أو جرد يدوي).
        نستخدم `transaction.atomic` لضمان عدم حدوث خطأ جزئي في قاعدة البيانات.
        """
        with transaction.atomic():
            # استخدام select_for_update لقفل السجل ومنع التعارض عند التحديث المتزامن (Row Locking)
            inventory = Inventory.objects.select_for_update().get(id=inventory_id)
            
            previous_quantity = inventory.quantity
            
            if transaction_type == 'ADD':
                new_quantity = previous_quantity + quantity
                difference = quantity
            elif transaction_type == 'DEDUCT':
                if previous_quantity < quantity:
                    raise ValidationError("الكمية المطلوبة للخصم غير متوفرة في المخزون.")
                new_quantity = previous_quantity - quantity
                difference = -quantity
            elif transaction_type == 'SET':
                new_quantity = quantity
                difference = new_quantity - previous_quantity
            else:
                raise ValidationError("نوع العملية غير صالح.")

            # تحديث الكمية
            inventory.quantity = new_quantity
            inventory.save()

            # تسجيل الحركة في الـ Ledger
            InventoryTransaction.objects.create(
                inventory=inventory,
                transaction_type=transaction_type,
                previous_quantity=previous_quantity,
                new_quantity=new_quantity,
                difference=difference,
                reason=reason,
                created_by=user
            )

            # التحقق من الحد الأدنى وإصدار تنبيه إذا لزم الأمر
            InventoryService.check_alerts(inventory)

            return inventory

    @staticmethod
    def reserve_stock(inventory_id, quantity, reason, user):
        """
        حجز كمية معينة عند بدء عملية الدفع (Checkout).
        """
        with transaction.atomic():
            inventory = Inventory.objects.select_for_update().get(id=inventory_id)
            
            if inventory.available_quantity < quantity:
                raise ValidationError("الكمية المتاحة غير كافية للحجز.")
                
            previous_quantity = inventory.quantity # الكمية الفعلية لا تتغير
            
            inventory.reserved_quantity += quantity
            inventory.save()
            
            InventoryTransaction.objects.create(
                inventory=inventory,
                transaction_type='RESERVE',
                previous_quantity=previous_quantity,
                new_quantity=previous_quantity,
                difference=0, # لا يوجد تغيير في الكمية الفعلية
                reason=f"حجز كمية: {reason}",
                created_by=user
            )
            return inventory

    @staticmethod
    def release_stock(inventory_id, quantity, reason, user):
        """
        تحرير الكمية المحجوزة في حال فشل الدفع أو إلغاء الطلب.
        """
        with transaction.atomic():
            inventory = Inventory.objects.select_for_update().get(id=inventory_id)
            
            if inventory.reserved_quantity < quantity:
                raise ValidationError("الكمية المحجوزة أقل من الكمية المراد تحريرها.")
                
            previous_quantity = inventory.quantity
            
            inventory.reserved_quantity -= quantity
            inventory.save()
            
            InventoryTransaction.objects.create(
                inventory=inventory,
                transaction_type='RELEASE',
                previous_quantity=previous_quantity,
                new_quantity=previous_quantity,
                difference=0,
                reason=f"تحرير كمية محجوزة: {reason}",
                created_by=user
            )
            return inventory

    @staticmethod
    def check_alerts(inventory):
        """
        التحقق مما إذا كان المخزون قد انخفض عن الحد الأدنى لإنشاء تنبيه.
        """
        if inventory.available_quantity <= 0:
            InventoryAlert.objects.get_or_create(
                inventory=inventory,
                alert_type='OUT_OF_STOCK',
                is_resolved=False,
                defaults={'message': f"نفاد المخزون للمنتج {inventory.product.name}"}
            )
        elif inventory.available_quantity <= inventory.minimum_quantity:
            InventoryAlert.objects.get_or_create(
                inventory=inventory,
                alert_type='LOW_STOCK',
                is_resolved=False,
                defaults={'message': f"المخزون منخفض للمنتج {inventory.product.name}. المتاح: {inventory.available_quantity}"}
            )
            