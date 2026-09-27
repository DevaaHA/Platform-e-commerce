from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Banner, CMSPage, FAQ, HomepageSection, Advertisement
from .serializers import (
    BannerSerializer, CMSPageSerializer, FAQSerializer, 
    HomepageSectionSerializer, AdvertisementSerializer
)

class HomepageViewSet(viewsets.ViewSet):
    permission_classes = [permissions.AllowAny]

    @action(detail=False, methods=['get'])
    def sections(self, request):
        sections = HomepageSection.objects.filter(status=True).order_by('position')
        serializer = HomepageSectionSerializer(sections, many=True)
        return Response(serializer.data)

class BannerViewSet(viewsets.ModelViewSet):
    queryset = Banner.objects.filter(status='active')
    serializer_class = BannerSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

class CMSPageViewSet(viewsets.ModelViewSet):
    queryset = CMSPage.objects.filter(status=True)
    serializer_class = CMSPageSerializer
    lookup_field = 'slug'
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

class FAQViewSet(viewsets.ModelViewSet):
    queryset = FAQ.objects.filter(status=True).order_by('order')
    serializer_class = FAQSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

class AdvertisementViewSet(viewsets.ModelViewSet):
    queryset = Advertisement.objects.all()
    serializer_class = AdvertisementSerializer
    permission_classes = [permissions.IsAuthenticated]