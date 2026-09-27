class LocationModel {
  final double latitude;
  final double longitude;
  final double speed;
  final String timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.timestamp,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      speed: double.tryParse(json['speed']?.toString() ?? '0') ?? 0.0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}
