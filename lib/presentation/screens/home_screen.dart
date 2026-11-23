import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:park_locator/presentation/blocs/parking/parking_state.dart';
import 'package:park_locator/presentation/blocs/parking/parking_bloc.dart';
import 'package:park_locator/presentation/blocs/parking/parking_event.dart';
import 'package:park_locator/core/theme/app_theme.dart';
import 'package:park_locator/presentation/screens/splash_screen.dart';
import 'package:park_locator/presentation/screens/find_parking_screen.dart';
import 'package:park_locator/presentation/screens/parking_details_screen.dart';
import 'package:park_locator/presentation/screens/navigate_to_car_screen.dart';

/// Root screen that manages the initial animated splash screen
/// and swaps between the three main views with animated transitions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _splashCompleted = false;

  @override
  void initState() {
    super.initState();
    // Kick off location fetch and stored-spot check
    context.read<ParkingBloc>().add(const ParkingInitialized());

    // Ensure animated splash screen is displayed for at least 2.2 seconds
    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _splashCompleted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParkingBloc, ParkingState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
          child: _buildScreen(state),
        );
      },
    );
  }

  Widget _buildScreen(ParkingState state) {
    if (!_splashCompleted ||
        state.status == ParkingStatus.initial ||
        state.status == ParkingStatus.locating) {
      return const SplashScreen(key: ValueKey('splash'));
    }

    switch (state.status) {
      case ParkingStatus.initial:
      case ParkingStatus.locating:
        return const SplashScreen(key: ValueKey('splash'));

      case ParkingStatus.idle:
      case ParkingStatus.saving:
        return const FindParkingScreen(key: ValueKey('find'));

      case ParkingStatus.details:
        return const ParkingDetailsScreen(key: ValueKey('details'));

      case ParkingStatus.navigating:
        return const NavigateToCarScreen(key: ValueKey('navigate'));

      case ParkingStatus.error:
        return _ErrorScreen(
          key: const ValueKey('error'),
          message: state.errorMessage ?? 'Something went wrong',
          onRetry: () =>
              context.read<ParkingBloc>().add(const ParkingInitialized()),
        );
    }
  }
}

// ── Error screen ────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off_rounded,
                color: AppTheme.textTertiary,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                'Location Unavailable',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
