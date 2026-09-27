import django_filters
from .models import Product

class ProductFilter(django_filters.FilterSet):
    min_price = django_filters.NumberFilter(field_name="price", lookup_expr='gte')
    max_price = django_filters.NumberFilter(field_name="price", lookup_expr='lte')
    name = django_filters.CharFilter(lookup_expr='icontains') # بحث بالاسم

    class Meta:
        model = Product
        fields = ['category', 'min_price', 'max_price', 'name']