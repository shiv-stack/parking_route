import 'package:equatable/equatable.dart';

abstract class ParkingEvent extends Equatable {
  const ParkingEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered on app start to fetch current location and check for saved spots.
class ParkingInitialized extends ParkingEvent {
  const ParkingInitialized();
}

/// User requests to refresh their current GPS position.
class LocationRefreshed extends ParkingEvent {
  const LocationRefreshed();
}

/// User taps "Save Parking & Photo" - captures photo and saves location.
class ParkingSaved extends ParkingEvent {
  const ParkingSaved();
}

/// User taps "Find My Car" - transitions to navigation mode.
class NavigationStarted extends ParkingEvent {
  const NavigationStarted();
}

/// Real-time user position update during navigation.
class UserPositionUpdated extends ParkingEvent {
  final double latitude;
  final double longitude;

  const UserPositionUpdated({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

/// User cancels / clears the saved parking spot.
class ParkingCancelled extends ParkingEvent {
  const ParkingCancelled();
}

/// User navigates back from details to home.
class BackToHome extends ParkingEvent {
  const BackToHome();
}
