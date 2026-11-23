import 'dart:convert';

class ParkingSpot {
  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final DateTime savedAt;
  final String? photoPath;
  final bool isActive;

  const ParkingSpot({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.savedAt,
    this.photoPath,
    this.isActive = true,
  });

  ParkingSpot copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    DateTime? savedAt,
    String? photoPath,
    bool? isActive,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      savedAt: savedAt ?? this.savedAt,
      photoPath: photoPath ?? this.photoPath,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'savedAt': savedAt.toIso8601String(),
      'photoPath': photoPath,
      'isActive': isActive,
    };
  }

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      city: json['city'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      photoPath: json['photoPath'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory ParkingSpot.fromJsonString(String source) =>
      ParkingSpot.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
