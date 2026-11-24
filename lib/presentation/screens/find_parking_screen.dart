import 'dart:async';
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
import 'package:park_locator/presentation/widgets/bottom_sheet_handle.dart';
import 'package:park_locator/presentation/widgets/primary_button.dart';
import 'package:park_locator/presentation/widgets/user_location_dot.dart';
import 'package:park_locator/presentation/widgets/you_are_here_bubble.dart';

class FindParkingScreen extends StatefulWidget {
  const FindParkingScreen({super.key});

  @override
  State<FindParkingScreen> createState() => _FindParkingScreenState();
}

class _FindParkingScreenState extends State<FindParkingScreen> {
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
        // Turn off heading mode and reset to True North
        _isHeadingMode = false;
        _mapRotation = 0.0;
        _mapController.rotate(0);
      } else {
        // Activate heading mode
        _isHeadingMode = true;
        if (_deviceHeading != null) {
          _mapRotation = _deviceHeading!;
          _mapController.rotate(-_deviceHeading!);
        } else {
          // Fallback if sensor not ready or on simulator: reset to North
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
        if (state.status == ParkingStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'An error occurred'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        if (state.hasLocation) {
          _mapController.move(
            LatLng(state.currentLat!, state.currentLng!),
            AppConstants.defaultZoom,
          );
        }
      },
      builder: (context, state) {
        final centerPoint = LatLng(
          state.currentLat ?? AppConstants.defaultLat,
          state.currentLng ?? AppConstants.defaultLng,
        );

        return Scaffold(
          backgroundColor: AppTheme.surfaceWhite,
          body: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                fontFamily: 'SF Pro Display',
                              ),
                              children: [
                                TextSpan(
                                  text: 'PARK',
                                  style: TextStyle(
                                    color: AppTheme.logoNavy,
                                  ),
                                ),
                                TextSpan(
                                  text: 'ROUTE',
                                  style: TextStyle(
                                    color: AppTheme.logoCyan,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Find My Parking',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.primaryBlue,
                            size: 26,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to mark your spot',
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
                        initialCenter: centerPoint,
                        initialZoom: AppConstants.defaultZoom,
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
                                // If user rotated manually with gestures, turn off auto-follow
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
                        if (state.hasLocation)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  state.currentLat!,
                                  state.currentLng!,
                                ),
                                width: 140,
                                height: 110,
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    YouAreHereBubble(),
                                    SizedBox(height: 6),
                                    UserLocationDot(),
                                  ],
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

                    // Loading overlay
                    if (state.status == ParkingStatus.locating)
                      Positioned.fill(
                        child: Container(
                          color: const Color.fromRGBO(255, 255, 255, 0.6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryBlue,
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
                        onTap: _onCompassTapped,
                      ),
                    ),

                    // Map bottom-right: locate me
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: MapActionButton(
                        icon: Icons.my_location_rounded,
                        onTap: () {
                          if (state.hasLocation) {
                            _mapController.move(
                              LatLng(state.currentLat!, state.currentLng!),
                              AppConstants.defaultZoom,
                            );
                          } else {
                            context
                                .read<ParkingBloc>()
                                .add(const LocationRefreshed());
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom Sheet ─────────────────────────────────────────────
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
                    const BottomSheetHandle(),
                    const Text(
                      'Never lose your spot again.',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Save your location and a photo for later.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'SAVE PARKING & PHOTO',
                      icon: Icons.camera_alt_outlined,
                      isLoading: state.status == ParkingStatus.saving,
                      onTap: state.hasLocation
                          ? () => context
                              .read<ParkingBloc>()
                              .add(const ParkingSaved())
                          : null,
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
