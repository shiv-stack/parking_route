class AppConstants {
  static const String appName = 'ParkRoute';
  static const String parkingKey = 'saved_parking';

  // Map defaults (San Francisco Hayes Valley as in Figma design)
  static const double defaultLat = 37.7765;
  static const double defaultLng = -122.4242;
  static const double defaultZoom = 16.5;
  static const double detailZoom = 16.5;

  // Official OpenStreetMap tile server
  // 100% Free, NO watermark, NO API Key needed
  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> mapSubdomains = [];
}
