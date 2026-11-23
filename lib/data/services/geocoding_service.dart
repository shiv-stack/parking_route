import 'package:geocoding/geocoding.dart';

class GeocodingService {
  final _geocoding = Geocoding();

  /// Reverse-geocodes a [lat]/[lng] pair into a human-readable address.
  Future<Map<String, String>> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return {
          'address': 'Unknown Location',
          'city': '',
        };
      }

      final place = placemarks.first;
      final street = [
        place.subThoroughfare,
        place.thoroughfare,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      final city = [
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      return {
        'address': street.isNotEmpty ? street : 'Unknown Street',
        'city': city,
      };
    } catch (_) {
      return {
        'address': 'Unknown Location',
        'city': '',
      };
    }
  }
}
