import 'dart:math';
import 'package:flutter/material.dart';
import 'package:park_locator/core/theme/app_theme.dart';

class CompassButton extends StatelessWidget {
  /// Current map rotation in degrees.
  final double rotation;

  /// Whether heading tracking mode is actively following orientation.
  final bool isHeadingMode;

  /// Callback when tapped.
  final VoidCallback onTap;

  const CompassButton({
    super.key,
    required this.rotation,
    this.isHeadingMode = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: isHeadingMode
              ? Border.all(color: AppTheme.primaryBlue, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isHeadingMode
                  ? AppTheme.primaryBlue.withValues(alpha: 0.25)
                  : const Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: isHeadingMode ? 10 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          // Rotate the needle/compass opposite to map rotation so North needle points to True North
          child: Transform.rotate(
            angle: -rotation * (pi / 180),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _CompassNeedlePainter(
                  isHeadingMode: isHeadingMode,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassNeedlePainter extends CustomPainter {
  final bool isHeadingMode;

  _CompassNeedlePainter({required this.isHeadingMode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final halfW = size.width * 0.22;
    final halfH = size.height * 0.46;

    // North Needle (Red tip)
    final northPath = Path()
      ..moveTo(center.dx, center.dy - halfH)
      ..lineTo(center.dx + halfW, center.dy)
      ..lineTo(center.dx, center.dy - 2)
      ..close();

    final northPaint = Paint()
      ..color = AppTheme.errorRed
      ..style = PaintingStyle.fill;
    canvas.drawPath(northPath, northPaint);

    // North Needle shadow side
    final northShadowPath = Path()
      ..moveTo(center.dx, center.dy - halfH)
      ..lineTo(center.dx - halfW, center.dy)
      ..lineTo(center.dx, center.dy - 2)
      ..close();

    final northShadowPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;
    canvas.drawPath(northShadowPath, northShadowPaint);

    // South Needle (Grey / Blue tip)
    final southPath = Path()
      ..moveTo(center.dx, center.dy + halfH)
      ..lineTo(center.dx + halfW, center.dy)
      ..lineTo(center.dx, center.dy + 2)
      ..close();

    final southPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(southPath, southPaint);

    final southShadowPath = Path()
      ..moveTo(center.dx, center.dy + halfH)
      ..lineTo(center.dx - halfW, center.dy)
      ..lineTo(center.dx, center.dy + 2)
      ..close();

    final southShadowPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.fill;
    canvas.drawPath(southShadowPath, southShadowPaint);

    // Center pivot dot
    final pivotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, pivotPaint);

    final pivotBorder = Paint()
      ..color = const Color(0xFF78909C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 2.5, pivotBorder);
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) {
    return oldDelegate.isHeadingMode != isHeadingMode;
  }
}
