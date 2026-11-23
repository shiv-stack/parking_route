import 'package:shared_preferences/shared_preferences.dart';
import '../models/parking_spot.dart';

class StorageService {
  static const String _key = 'active_parking_spot';

  /// Persists a [ParkingSpot] locally.
  Future<void> saveParkingSpot(ParkingSpot spot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, spot.toJsonString());
  }

  /// Loads the last saved [ParkingSpot], or null if none exists.
  Future<ParkingSpot?> loadParkingSpot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return ParkingSpot.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  /// Clears the saved parking spot.
  Future<void> clearParkingSpot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
