import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/parking_spot.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/storage_service.dart';
import '../services/photo_service.dart';

class ParkingRepository {
  final LocationService _locationService;
  final GeocodingService _geocodingService;
  final StorageService _storageService;
  final PhotoService _photoService;
  final _uuid = const Uuid();

  ParkingRepository({
    LocationService? locationService,
    GeocodingService? geocodingService,
    StorageService? storageService,
    PhotoService? photoService,
  })  : _locationService = locationService ?? LocationService(),
        _geocodingService = geocodingService ?? GeocodingService(),
        _storageService = storageService ?? StorageService(),
        _photoService = photoService ?? PhotoService();

  Future<Position> getCurrentPosition() =>
      _locationService.getCurrentPosition();

  Stream<Position> getPositionStream() => _locationService.getPositionStream();

  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) =>
      _locationService.distanceBetween(startLat, startLng, endLat, endLng);

  Future<Map<String, String>> getAddress(double lat, double lng) =>
      _geocodingService.getAddressFromCoordinates(lat, lng);

  Future<String?> capturePhoto() => _photoService.capturePhoto();

  Future<String?> pickFromGallery() => _photoService.pickFromGallery();

  Future<ParkingSpot> saveParking({
    required double latitude,
    required double longitude,
    String? photoPath,
  }) async {
    final addressData = await _geocodingService.getAddressFromCoordinates(
      latitude,
      longitude,
    );
    final spot = ParkingSpot(
      id: _uuid.v4(),
      latitude: latitude,
      longitude: longitude,
      address: addressData['address'] ?? 'Unknown Location',
      city: addressData['city'] ?? '',
      savedAt: DateTime.now(),
      photoPath: photoPath,
      isActive: true,
    );
    await _storageService.saveParkingSpot(spot);
    return spot;
  }

  Future<ParkingSpot?> loadSavedParking() => _storageService.loadParkingSpot();

  Future<void> clearParking() => _storageService.clearParkingSpot();
}
