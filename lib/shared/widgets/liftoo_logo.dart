import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Liftoo brand mark — stylized L with assistant + bag (vector style).
class LiftooLogoMark extends StatelessWidget {
  final double size;

  const LiftooLogoMark({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LiftooMarkPainter(),
      ),
    );
  }
}

class LiftooLogo extends StatelessWidget {
  final double fontSize;
  final bool showMark;
  final bool showTagline;
  final bool center;
  final double markSize;

  const LiftooLogo({
    super.key,
    this.fontSize = 32,
    this.showMark = true,
    this.showTagline = false,
    this.center = true,
    this.markSize = 88,
  });

  @override
  Widget build(BuildContext context) {
    final cross = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        if (showMark) ...[
          LiftooLogoMark(size: markSize),
          SizedBox(height: fontSize * 0.55),
        ],
        _Wordmark(fontSize: fontSize, center: center),
        if (showTagline) ...[
          SizedBox(height: fontSize * 0.45),
          _Tagline(fontSize: fontSize * 0.32),
        ],
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  final double fontSize;
  final bool center;

  const _Wordmark({required this.fontSize, required this.center});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        RichText(
          textAlign: center ? TextAlign.center : TextAlign.start,
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1,
            ),
            children: const [
              TextSpan(text: 'Lift', style: TextStyle(color: AppColors.charcoal)),
              TextSpan(text: 'oo', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        SizedBox(
          width: fontSize * 1.05,
          height: fontSize * 0.18,
          child: CustomPaint(
            painter: _SmilePainter(),
          ),
        ),
      ],
    );
  }
}

class _Tagline extends StatelessWidget {
  final double fontSize;

  const _Tagline({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    const text = 'YOUR SHOPPING, OUR ASSISTANCE';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _line(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: fontSize * 0.7),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: AppColors.charcoal.withValues(alpha: 0.75),
            ),
          ),
        ),
        _line(),
      ],
    );
  }

  Widget _line() => Container(
        width: fontSize * 1.8,
        height: 1.2,
        color: AppColors.primary.withValues(alpha: 0.85),
      );
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.55
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.5, size.height * 1.2, size.width, size.height * 0.35);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LiftooMarkPainter extends CustomPainter {
  static const _orange = AppColors.primary;
  static const _orangeDark = AppColors.primaryDark;
  static const _charcoal = AppColors.charcoal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_orange, _orangeDark],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final orangePaint = Paint()..shader = gradient;
    final charcoalPaint = Paint()..color = _charcoal;

    // L — vertical stroke
    final lVertical = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.08, w * 0.2, h * 0.72),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(lVertical, orangePaint);

    // L — horizontal stroke
    final lHorizontal = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.62, w * 0.58, h * 0.2),
      Radius.circular(w * 0.06),
    );
    canvas.drawRRect(lHorizontal, orangePaint);

    // Walking person silhouette
    _drawPerson(canvas, size, charcoalPaint);

    // Shopping bag
    _drawBag(canvas, size, orangePaint);

    // Motion arc
    final arcPaint = Paint()
      ..color = _orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    final arc = Path()
      ..moveTo(w * 0.28, h * 0.16)
      ..quadraticBezierTo(w * 0.52, h * 0.02, w * 0.78, h * 0.22);
    canvas.drawPath(arc, arcPaint);
  }

  void _drawPerson(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    // Head
    canvas.drawCircle(Offset(w * 0.48, h * 0.34), w * 0.055, paint);

    // Body + legs (walking pose)
    final body = Path()
      ..moveTo(w * 0.48, h * 0.395)
      ..lineTo(w * 0.48, h * 0.52)
      ..lineTo(w * 0.38, h * 0.62)
      ..moveTo(w * 0.48, h * 0.52)
      ..lineTo(w * 0.56, h * 0.61);
    canvas.drawPath(
      body,
      paint..style = PaintingStyle.stroke..strokeWidth = w * 0.07..strokeCap = StrokeCap.round,
    );

    // Arm reaching to bag
    final arm = Path()
      ..moveTo(w * 0.48, h * 0.44)
      ..lineTo(w * 0.62, h * 0.42);
    canvas.drawPath(
      arm,
      paint..style = PaintingStyle.stroke..strokeWidth = w * 0.055..strokeCap = StrokeCap.round,
    );
  }

  void _drawBag(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;

    final bagRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.64, h * 0.36, w * 0.18, h * 0.2),
      Radius.circular(w * 0.025),
    );
    canvas.drawRRect(bagRect, paint);

    final handle = Path()
      ..moveTo(w * 0.68, h * 0.36)
      ..quadraticBezierTo(w * 0.73, h * 0.28, w * 0.78, h * 0.36);
    canvas.drawPath(
      handle,
      paint..style = PaintingStyle.stroke..strokeWidth = w * 0.028,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact logo row for app bars.
class LiftooLogoCompact extends StatelessWidget {
  const LiftooLogoCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LiftooLogoMark(size: 32),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              height: 1,
            ),
            children: const [
              TextSpan(text: 'Lift', style: TextStyle(color: AppColors.charcoal)),
              TextSpan(text: 'oo', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}
