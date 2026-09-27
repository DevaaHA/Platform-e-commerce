from rest_framework import viewsets, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from .models import SearchHistory, SearchFilterConfig
from .serializers import SearchHistorySerializer, SearchFilterConfigSerializer
from .services import SearchService

@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def search_products(request):
    """نقطة النهاية الأساسية للبحث عن المنتجات"""
    keyword = request.GET.get('q', '').strip()
    sort_by = request.GET.get('sort', 'relevant')
    
    if not keyword:
        return Response({"error": "يجب إدخال كلمة مفتاحية للبحث."}, status=status.HTTP_400_BAD_REQUEST)

    user = request.user if request.user.is_authenticated else None
    results = SearchService.process_search(keyword, user=user, sort_by=sort_by)
    return Response(results, status=status.HTTP_200_OK)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def autocomplete_search(request):
    """نقطة نهاية الإقترحات السريعة أثناء الكتابة (Autocomplete)"""
    query = request.GET.get('q', '').strip()
    suggestions = SearchService.get_autocomplete_suggestions(query)
    return Response({"suggestions": suggestions}, status=status.HTTP_200_OK)


class SearchHistoryViewSet(viewsets.ModelViewSet):
    """إدارة سجل بحث المستخدم وحذفه"""
    serializer_class = SearchHistorySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SearchHistory.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class AdminSearchAnalyticsViewSet(viewsets.ViewSet):
    """لوحة تحكم الأدمن لتحليلات البحث والكلمات الأكثر طلباً"""
    permission_classes = [permissions.IsAdminUser]

    def list(self, request):
        data = {
            "top_keywords": ["iPhone", "Samsung", "Laptops", "Headphones"],
            "zero_result_keywords": ["UnknownBrandX", "OutOfStockItem"],
            "total_searches_today": 14280
        }
        return Response(data, status=status.HTTP_200_OK)