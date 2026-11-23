import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Slim drag-handle indicator at the top of bottom sheets.
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppTheme.borderLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
