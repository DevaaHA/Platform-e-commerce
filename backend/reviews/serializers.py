from rest_framework import serializers
from .models import Review, ReviewImage, RatingsSummary, ReviewReport

class ReviewImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewImage
        fields = ['id', 'image_url']

class ReviewSerializer(serializers.ModelSerializer):
    images = ReviewImageSerializer(many=True, read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = Review
        fields = [
            'id', 'user', 'user_email', 'type', 'product_id', 'store_id', 
            'driver_id', 'order_id', 'rating', 'comment', 'status', 
            'verified_purchase', 'created_at', 'images'
        ]
        read_only_fields = ('id', 'user', 'status', 'verified_purchase', 'created_at')

class RatingsSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = RatingsSummary
        fields = '__all__'

class ReviewReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReviewReport
        fields = '__all__'
        read_only_fields = ('id', 'user', 'status', 'created_at')