from rest_framework import serializers
from .models import UserPreferences, UserActivity, Recommendation

class UserPreferencesSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserPreferences
        fields = ['categories', 'brands', 'price_range']

class UserActivitySerializer(serializers.ModelSerializer):
    class Meta:
        model = UserActivity
        fields = ['activity_type', 'product_id', 'metadata']

    def validate_activity_type(self, value):
        valid_types = [choice[0] for choice in UserActivity.ActivityType.choices]
        if value not in valid_types:
            raise serializers.ValidationError("نوع النشاط غير صالح.")
        return value

class RecommendationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recommendation
        fields = ['product_id', 'recommendation_type', 'score']