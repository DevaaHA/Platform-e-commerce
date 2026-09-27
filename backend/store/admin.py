from django.contrib import admin
from .models import (
    Product, Category, Store, Inventory
)

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'store', 'created_at')
    search_fields = ('name', 'sku')

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'store')

@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    list_display = ('name_ar', 'status', 'owner')

@admin.register(Inventory)
class InventoryAdmin(admin.ModelAdmin):
    list_display = ('product', 'quantity', 'reserved_quantity', 'available_quantity')