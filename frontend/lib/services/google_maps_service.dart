import 'package:dio/dio.dart';

class GoogleMapsService {
  final Dio _dio = Dio();
  final String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // حساب المسافة والوقت المتوقع للوصول (ETA) بين نقطتين
  Future<Map<String, dynamic>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&key=$_apiKey';

      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if ((data['routes'] as List).isNotEmpty) {
          final leg = data['routes'][0]['legs'][0];
          return {
            'distance': leg['distance']['text'], // مثال: "5.4 كم"
            'duration': leg['duration']['text'], // مثال: "15 دقيقة"
            'polyline':
                data['routes'][0]['overview_polyline']['points'], // نقاط رسم الخط على الخريطة
          };
        }
      }
    } catch (e) {
      // التعامل مع الخطأ أو إرجاع قيم افتراضية
    }
    return {'distance': 'N/A', 'duration': 'N/A', 'polyline': ''};
  }
}
