import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:park_locator/core/constants/app_constants.dart';
import 'package:park_locator/core/theme/app_theme.dart';
import 'package:park_locator/presentation/blocs/parking/parking_bloc.dart';
import 'package:park_locator/presentation/blocs/parking/parking_event.dart';
import 'package:park_locator/presentation/blocs/parking/parking_state.dart';
import 'package:park_locator/presentation/widgets/compass_button.dart';
import 'package:park_locator/presentation/widgets/map_action_button.dart';
import 'package:park_locator/presentation/widgets/parking_marker_widget.dart';
import 'package:park_locator/presentation/widgets/bottom_sheet_handle.dart';
import 'package:park_locator/presentation/widgets/primary_button.dart';

class ParkingDetailsScreen extends StatefulWidget {
  const ParkingDetailsScreen({super.key});

  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
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

  void _onCompassTapped() {
    setState(() {
      if (_isHeadingMode) {
        _isHeadingMode = false;
        _mapRotation = 0.0;
        _mapController.rotate(0);
      } else {
        _isHeadingMode = true;
        if (_deviceHeading != null) {
          _mapRotation = _deviceHeading!;
          _mapController.rotate(-_deviceHeading!);
        } else {
          _mapRotation = 0.0;
          _mapController.rotate(0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParkingBloc, ParkingState>(
      builder: (context, state) {
        final spot = state.savedSpot;
        if (spot == null) return const SizedBox.shrink();

        final savedTime = DateFormat('h:mm a').format(spot.savedAt);
        final isToday = DateTime.now().difference(spot.savedAt).inDays == 0;
        final dateLabel =
            isToday ? 'Today' : DateFormat('MMM d').format(spot.savedAt);
        final spotPoint = LatLng(spot.latitude, spot.longitude);

        return Scaffold(
          backgroundColor: AppTheme.surfaceWhite,
          body: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────
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
                        'Parking Details',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A little reminder. Right where you left it.',
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

              // ── OpenStreetMap ─────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: spotPoint,
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
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: spotPoint,
                              width: 130,
                              height: 100,
                              alignment: Alignment.bottomCenter,
                              child: const ParkingMarkerWidget(
                                showCallout: true,
                              ),
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

                    // Map top-right: Working Compass Button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CompassButton(
                        rotation: _mapRotation,
                        isHeadingMode: _isHeadingMode,
                        onTap: _onCompassTapped,
                      ),
                    ),

                    // Map bottom-right: re-center on spot
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: MapActionButton(
                        icon: Icons.my_location_rounded,
                        onTap: () {
                          _mapController.move(
                            spotPoint,
                            AppConstants.detailZoom,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom Sheet ──────────────────────────────────────────
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
                  children: [
                    const BottomSheetHandle(),

                    // Status row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(52, 199, 89, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.successGreen,
                                size: 14,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'SPOT SAVED',
                                style: TextStyle(
                                  color: AppTheme.successGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$dateLabel, $savedTime',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Address card
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: spot.photoPath != null
                              ? Image.file(
                                  File(spot.photoPath!),
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: AppTheme.backgroundGray,
                                  child: const Icon(
                                    Icons.local_parking_rounded,
                                    color: AppTheme.textTertiary,
                                    size: 32,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spot.address,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                spot.city,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    color: AppTheme.textTertiary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    spot.photoPath != null
                                        ? '1 photo attached'
                                        : 'No photo',
                                    style: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: 'FIND MY CAR',
                      icon: Icons.directions_walk_rounded,
                      onTap: () => context
                          .read<ParkingBloc>()
                          .add(const NavigationStarted()),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => _showCancelConfirmation(context),
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.backgroundGray,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel Parking',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Cancel Parking?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: const Text(
          'This will remove your saved parking spot.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ParkingBloc>().add(const ParkingCancelled());
            },
            child: const Text(
              'Cancel Parking',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
