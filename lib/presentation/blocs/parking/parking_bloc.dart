import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:park_locator/data/repositories/parking_repository.dart';
import 'package:park_locator/presentation/blocs/parking/parking_event.dart';
import 'package:park_locator/presentation/blocs/parking/parking_state.dart';

class ParkingBloc extends Bloc<ParkingEvent, ParkingState> {
  final ParkingRepository _repository;
  StreamSubscription<Position>? _positionSubscription;

  ParkingBloc({required ParkingRepository repository})
      : _repository = repository,
        super(const ParkingState()) {    on<ParkingInitialized>(_onInitialized);
    on<LocationRefreshed>(_onLocationRefreshed);
    on<ParkingSaved>(_onParkingSaved);
    on<NavigationStarted>(_onNavigationStarted);
    on<UserPositionUpdated>(_onUserPositionUpdated);
    on<ParkingCancelled>(_onParkingCancelled);
    on<BackToHome>(_onBackToHome);
  }

  // ─── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onInitialized(
    ParkingInitialized event,
    Emitter<ParkingState> emit,
  ) async {
    emit(state.copyWith(status: ParkingStatus.locating));
    try {
      // Check for previously saved spot
      final saved = await _repository.loadSavedParking();
      final position = await _repository.getCurrentPosition();

      if (saved != null && saved.isActive) {
        final distance = _repository.distanceBetween(
          position.latitude,
          position.longitude,
          saved.latitude,
          saved.longitude,
        );
        emit(state.copyWith(
          status: ParkingStatus.details,
          currentLat: position.latitude,
          currentLng: position.longitude,
          savedSpot: saved,
          distanceToSpot: distance,
          etaMinutes: _distanceToEta(distance),
        ));
      } else {
        emit(state.copyWith(
          status: ParkingStatus.idle,
          currentLat: position.latitude,
          currentLng: position.longitude,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ParkingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLocationRefreshed(
    LocationRefreshed event,
    Emitter<ParkingState> emit,
  ) async {
    emit(state.copyWith(status: ParkingStatus.locating));
    try {
      final position = await _repository.getCurrentPosition();
      emit(state.copyWith(
        status: ParkingStatus.idle,
        currentLat: position.latitude,
        currentLng: position.longitude,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ParkingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onParkingSaved(
    ParkingSaved event,
    Emitter<ParkingState> emit,
  ) async {
    if (state.currentLat == null || state.currentLng == null) return;

    emit(state.copyWith(status: ParkingStatus.saving));
    try {
      final photoPath = await _repository.capturePhoto();
      final spot = await _repository.saveParking(
        latitude: state.currentLat!,
        longitude: state.currentLng!,
        photoPath: photoPath,
      );

      emit(state.copyWith(
        status: ParkingStatus.details,
        savedSpot: spot,
        distanceToSpot: 0,
        etaMinutes: 0,
        capturedPhotoPath: photoPath,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ParkingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onNavigationStarted(
    NavigationStarted event,
    Emitter<ParkingState> emit,
  ) async {
    if (state.savedSpot == null) return;

    emit(state.copyWith(status: ParkingStatus.navigating));

    // Start listening to position updates
    await _positionSubscription?.cancel();
    _positionSubscription =
        _repository.getPositionStream().listen((position) {
      add(UserPositionUpdated(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    });
  }

  void _onUserPositionUpdated(
    UserPositionUpdated event,
    Emitter<ParkingState> emit,
  ) {
    if (state.savedSpot == null) return;

    final distance = _repository.distanceBetween(
      event.latitude,
      event.longitude,
      state.savedSpot!.latitude,
      state.savedSpot!.longitude,
    );

    emit(state.copyWith(
      currentLat: event.latitude,
      currentLng: event.longitude,
      distanceToSpot: distance,
      etaMinutes: _distanceToEta(distance),
    ));
  }

  Future<void> _onParkingCancelled(
    ParkingCancelled event,
    Emitter<ParkingState> emit,
  ) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _repository.clearParking();

    final lat = state.currentLat;
    final lng = state.currentLng;

    emit(ParkingState(
      status: ParkingStatus.idle,
      currentLat: lat,
      currentLng: lng,
    ));
  }

  void _onBackToHome(
    BackToHome event,
    Emitter<ParkingState> emit,
  ) {
    if (state.hasSavedSpot) {
      emit(state.copyWith(status: ParkingStatus.details));
    } else {
      emit(state.copyWith(status: ParkingStatus.idle));
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Rough walking ETA: 1.4 m/s average walking speed.
  int _distanceToEta(double metres) => (metres / 1.4 / 60).ceil();

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    return super.close();
  }
}
