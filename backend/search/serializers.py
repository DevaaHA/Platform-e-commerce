from rest_framework import serializers
from .models import SearchHistory, SearchLog, SearchFilterConfig

class SearchHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SearchHistory
        fields = '__all__'
        read_only_fields = ['id', 'user', 'created_at']

class SearchFilterConfigSerializer(serializers.ModelSerializer):
    class Meta:
        model = SearchFilterConfig
        fields = '__all__'