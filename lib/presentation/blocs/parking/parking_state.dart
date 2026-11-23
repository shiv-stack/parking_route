import 'package:equatable/equatable.dart';
import 'package:park_locator/data/models/parking_spot.dart';

enum ParkingStatus {
  initial,
  locating,
  idle,         // Location found, no parking saved
  saving,       // Capturing photo + saving
  details,      // Parking saved — details screen
  navigating,   // Active navigation to saved spot
  error,
}

class ParkingState extends Equatable {
  final ParkingStatus status;
  final double? currentLat;
  final double? currentLng;
  final ParkingSpot? savedSpot;
  final double? distanceToSpot;   // metres
  final int? etaMinutes;
  final String? errorMessage;
  final String? capturedPhotoPath;

  const ParkingState({
    this.status = ParkingStatus.initial,
    this.currentLat,
    this.currentLng,
    this.savedSpot,
    this.distanceToSpot,
    this.etaMinutes,
    this.errorMessage,
    this.capturedPhotoPath,
  });

  ParkingState copyWith({
    ParkingStatus? status,
    double? currentLat,
    double? currentLng,
    ParkingSpot? savedSpot,
    double? distanceToSpot,
    int? etaMinutes,
    String? errorMessage,
    String? capturedPhotoPath,
    bool clearPhoto = false,
    bool clearSpot = false,
    bool clearError = false,
  }) {
    return ParkingState(
      status: status ?? this.status,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      savedSpot: clearSpot ? null : (savedSpot ?? this.savedSpot),
      distanceToSpot: distanceToSpot ?? this.distanceToSpot,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      capturedPhotoPath:
          clearPhoto ? null : (capturedPhotoPath ?? this.capturedPhotoPath),
    );
  }

  bool get hasLocation => currentLat != null && currentLng != null;
  bool get hasSavedSpot => savedSpot != null;

  @override
  List<Object?> get props => [
        status,
        currentLat,
        currentLng,
        savedSpot,
        distanceToSpot,
        etaMinutes,
        errorMessage,
        capturedPhotoPath,
      ];
}
