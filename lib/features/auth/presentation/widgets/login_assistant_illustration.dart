import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
/// Friendly assistant character for the login hero (cap + branded t-shirt).
class LoginAssistantIllustration extends StatelessWidget {
  final double width;
  final double height;

  const LoginAssistantIllustration({
    super.key,
    this.width = 148,
    this.height = 172,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            right: -6,
            bottom: 12,
            child: Container(
              width: width * 0.72,
              height: width * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: Size(width * 0.92, height * 0.88),
              painter: _AssistantPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w * 0.5;

    // Shadow
    final shadow = Paint()..color = AppColors.navy.withValues(alpha: 0.08);
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, h * 0.96), width: w * 0.55, height: h * 0.08), shadow);

    // Legs
    final legPaint = Paint()..color = const Color(0xFF2D3748);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - w * 0.14, h * 0.72, w * 0.11, h * 0.2), const Radius.circular(8)),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX + w * 0.03, h * 0.72, w * 0.11, h * 0.2), const Radius.circular(8)),
      legPaint,
    );

    // T-shirt
    final shirt = Paint()..color = AppColors.primary;
    final shirtPath = Path()
      ..moveTo(centerX - w * 0.22, h * 0.48)
      ..lineTo(centerX + w * 0.22, h * 0.48)
      ..lineTo(centerX + w * 0.2, h * 0.74)
      ..lineTo(centerX - w * 0.2, h * 0.74)
      ..close();
    canvas.drawPath(shirtPath, shirt);

    // Logo on shirt (white L mark)
    final logoPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, h * 0.58), width: w * 0.14, height: w * 0.14),
        const Radius.circular(4),
      ),
      logoPaint,
    );
    final lPaint = Paint()..color = AppColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - w * 0.04, h * 0.52, w * 0.025, h * 0.1), const Radius.circular(2)),
      lPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - w * 0.04, h * 0.58, w * 0.07, h * 0.025), const Radius.circular(2)),
      lPaint,
    );

    // Arms
    final armPaint = Paint()
      ..color = const Color(0xFFFFD8B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(centerX - w * 0.24, h * 0.52), Offset(centerX - w * 0.34, h * 0.64), armPaint);
    canvas.drawLine(Offset(centerX + w * 0.24, h * 0.52), Offset(centerX + w * 0.36, h * 0.6), armPaint);

    // Shopping bag in hand
    final bagPaint = Paint()..color = AppColors.navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX + w * 0.3, h * 0.56, w * 0.12, h * 0.14), const Radius.circular(4)),
      bagPaint,
    );

    // Neck / face
    final skin = Paint()..color = const Color(0xFFFFD8B8);
    canvas.drawCircle(Offset(centerX, h * 0.38), w * 0.13, skin);

    // Smile
    final smile = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(centerX, h * 0.4), width: w * 0.1, height: h * 0.05),
      0.15,
      2.9,
      false,
      smile,
    );

    // Eyes
    final eye = Paint()..color = AppColors.navy;
    canvas.drawCircle(Offset(centerX - w * 0.045, h * 0.36), w * 0.018, eye);
    canvas.drawCircle(Offset(centerX + w * 0.045, h * 0.36), w * 0.018, eye);

    // Cap
    final cap = Paint()..color = AppColors.navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - w * 0.17, h * 0.2, w * 0.34, h * 0.12), const Radius.circular(6)),
      cap,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - w * 0.2, h * 0.28, w * 0.4, h * 0.04), const Radius.circular(3)),
      cap,
    );
    final brim = Paint()..color = AppColors.navy.withValues(alpha: 0.85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(centerX - w * 0.22, h * 0.3, w * 0.44, h * 0.035), const Radius.circular(4)),
      brim,
    );

    // Pink cap logo accent
    final accent = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(centerX, h * 0.25), w * 0.028, accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
