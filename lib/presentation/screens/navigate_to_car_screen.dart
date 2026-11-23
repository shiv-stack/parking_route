import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:park_locator/core/constants/app_constants.dart';
import 'package:park_locator/core/theme/app_theme.dart';
import 'package:park_locator/presentation/blocs/parking/parking_bloc.dart';
import 'package:park_locator/presentation/blocs/parking/parking_event.dart';
import 'package:park_locator/presentation/blocs/parking/parking_state.dart';
import 'package:park_locator/presentation/widgets/compass_button.dart';
import 'package:park_locator/presentation/widgets/map_action_button.dart';
import 'package:park_locator/presentation/widgets/parking_marker_widget.dart';
import 'package:park_locator/presentation/widgets/user_location_dot.dart';

class NavigateToCarScreen extends StatefulWidget {
  const NavigateToCarScreen({super.key});

  @override
  State<NavigateToCarScreen> createState() => _NavigateToCarScreenState();
}

class _NavigateToCarScreenState extends State<NavigateToCarScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _mapRotation = 0.0;
  double? _deviceHeading;
  bool _isHeadingMode = false;

  @override
  void initState() {
    super.initState();
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _deviceHeading = event.heading;
          if (_isHeadingMode && event.heading != null) {
            _mapRotation = event.heading!;
            _mapController.rotate(-event.heading!);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Calculates forward azimuth/bearing from user location to the parking spot.
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (pi / 180);
    final lon1 = start.longitude * (pi / 180);
    final lat2 = end.latitude * (pi / 180);
    final lon2 = end.longitude * (pi / 180);
    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final radians = atan2(y, x);
    return (radians * (180 / pi) + 360) % 360;
  }

  void _onCompassTapped(ParkingState state) {
    setState(() {
      if (_isHeadingMode) {
        // Toggle off and reset map to True North (0°)
        _isHeadingMode = false;
        _mapRotation = 0.0;
        _mapController.rotate(0);
      } else {
        // Toggle on Head Direction Mode
        _isHeadingMode = true;

        if (_deviceHeading != null) {
          // If device compass is available, follow real-time head orientation
          _mapRotation = _deviceHeading!;
          _mapController.rotate(-_deviceHeading!);
        } else if (state.hasLocation && state.savedSpot != null) {
          // If no compass sensor (e.g. simulator), align forward toward the car
          final userPoint = LatLng(state.currentLat!, state.currentLng!);
          final spotPoint = LatLng(
            state.savedSpot!.latitude,
            state.savedSpot!.longitude,
          );
          final bearing = _calculateBearing(userPoint, spotPoint);
          _mapRotation = bearing;
          _mapController.rotate(-bearing);
        } else {
          _mapRotation = 0.0;
          _mapController.rotate(0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ParkingBloc, ParkingState>(
      listener: (context, state) {
        if (state.hasLocation && state.savedSpot != null && !_isHeadingMode) {
          final bounds = LatLngBounds(
            LatLng(state.currentLat!, state.currentLng!),
            LatLng(state.savedSpot!.latitude, state.savedSpot!.longitude),
          );
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
            ),
          );
        }
      },
      builder: (context, state) {
        final spot = state.savedSpot;
        if (spot == null) return const SizedBox.shrink();

        final spotPoint = LatLng(spot.latitude, spot.longitude);
        final userPoint = state.hasLocation
            ? LatLng(state.currentLat!, state.currentLng!)
            : null;

        final distanceMetres = state.distanceToSpot ?? 0.0;
        final distanceLabel = distanceMetres < 1000
            ? '${distanceMetres.toInt()}m'
            : '${(distanceMetres / 1000).toStringAsFixed(1)}km';
        final etaLabel = state.etaMinutes != null
            ? '${state.etaMinutes} min${state.etaMinutes == 1 ? '' : 's'}'
            : '—';

        return Scaffold(
          backgroundColor: AppTheme.surfaceWhite,
          body: Column(
            children: [
              // ── Header ───────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context
                            .read<ParkingBloc>()
                            .add(const BackToHome()),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Navigate to Car',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your car is just a short walk away.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── OpenStreetMap with Route ──────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: userPoint ?? spotPoint,
                        initialZoom: AppConstants.detailZoom,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                        onMapEvent: (event) {
                          if (event is MapEventRotate ||
                              event is MapEventMove) {
                            final currentRot =
                                _mapController.camera.rotation;
                            if (mounted && (_mapRotation != currentRot)) {
                              setState(() {
                                _mapRotation = currentRot;
                                if (event.source !=
                                    MapEventSource.mapController) {
                                  _isHeadingMode = false;
                                }
                              });
                            }
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: AppConstants.mapTileUrl,
                          userAgentPackageName: 'com.example.park_locator',
                          maxZoom: 19,
                        ),

                        // Blue navigation route polyline
                        if (userPoint != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [userPoint, spotPoint],
                                color: AppTheme.primaryBlue,
                                strokeWidth: 5.0,
                                strokeCap: StrokeCap.round,
                                strokeJoin: StrokeJoin.round,
                              ),
                            ],
                          ),

                        // Markers: Parking pin and live user location
                        MarkerLayer(
                          markers: [
                            // Parking spot marker
                            Marker(
                              point: spotPoint,
                              width: 130,
                              height: 100,
                              alignment: Alignment.bottomCenter,
                              child: const ParkingMarkerWidget(
                                showCallout: true,
                              ),
                            ),
                            // User live location dot
                            if (userPoint != null)
                              Marker(
                                point: userPoint,
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                child: const UserLocationDot(),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // OpenStreetMap attribution badge
                    Positioned(
                      bottom: 8,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Map data © OpenStreetMap',
                          style: TextStyle(
                            color: Color(0xFF8A9BB0),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Map top-right: Working Compass Button for Head Direction
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CompassButton(
                        rotation: _mapRotation,
                        isHeadingMode: _isHeadingMode,
                        onTap: () => _onCompassTapped(state),
                      ),
                    ),

                    // Map bottom-right: re-center
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: MapActionButton(
                        icon: Icons.my_location_rounded,
                        onTap: () {
                          if (userPoint != null) {
                            _mapController.move(
                              userPoint,
                              AppConstants.detailZoom,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Navigation Bottom Sheet ───────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).padding.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            color: AppTheme.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Walking distance: $distanceLabel',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Follow the blue route to your car.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.primaryBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ETA: $etaLabel',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Walking route',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
