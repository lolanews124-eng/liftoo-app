import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../models/booking_tracking_model.dart';

/// Swiggy-style live map: customer pin, assistant pin, route line, ETA strip.
class LiveTrackingMap extends StatelessWidget {
  final BookingTrackingModel tracking;
  final double height;

  const LiveTrackingMap({super.key, required this.tracking, this.height = 240});

  @override
  Widget build(BuildContext context) {
    final assistant = tracking.assistant;
    final customer = tracking.customer;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _TrackingMapPainter(
                    customerLat: customer.lat,
                    customerLng: customer.lng,
                    assistantLat: assistant?.lat,
                    assistantLng: assistant?.lng,
                    progress: tracking.progress,
                  ),
                ),
                if (assistant != null)
                  Positioned(
                    left: 16,
                    top: 16,
                    child: _FloatingChip(
                      icon: Icons.delivery_dining,
                      label: assistant.name ?? 'Assistant',
                      color: AppColors.primary,
                    ),
                  ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _FloatingChip(
                    icon: Icons.home_rounded,
                    label: customer.label ?? 'You',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracking.statusMessage,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      if (customer.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          customer.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                if (tracking.distanceKm != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${tracking.distanceKm} km',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      if (tracking.etaMinutes != null)
                        Text(
                          '~${tracking.etaMinutes} min',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FloatingChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  final double customerLat;
  final double customerLng;
  final double? assistantLat;
  final double? assistantLng;
  final double progress;

  _TrackingMapPainter({
    required this.customerLat,
    required this.customerLng,
    this.assistantLat,
    this.assistantLng,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8F4EA);
    canvas.drawRect(Offset.zero & size, bg);

    _drawGrid(canvas, size);

    final customer = _project(customerLat, customerLng, size);
    final assistant = assistantLat != null && assistantLng != null
        ? _project(assistantLat!, assistantLng!, size)
        : Offset(size.width * 0.2, size.height * 0.25);

    final routePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.55)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(assistant.dx, assistant.dy)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.15,
        customer.dx,
        customer.dy,
      );
    canvas.drawPath(path, routePaint);

    final traveledPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      final len = metric.length * progress.clamp(0.05, 1.0);
      canvas.drawPath(metric.extractPath(0, len), traveledPaint);
    }

    _drawPulse(canvas, assistant, AppColors.primary);
    _drawPin(canvas, customer, AppColors.success, Icons.home_rounded);
    _drawPin(canvas, assistant, AppColors.primary, Icons.two_wheeler);
  }

  Offset _project(double lat, double lng, Size size) {
    final allLats = [customerLat, if (assistantLat != null) assistantLat!];
    final allLngs = [customerLng, if (assistantLng != null) assistantLng!];
    final minLat = allLats.reduce(math.min);
    final maxLat = allLats.reduce(math.max);
    final minLng = allLngs.reduce(math.min);
    final maxLng = allLngs.reduce(math.max);
    final pad = 0.08;
    final latSpan = (maxLat - minLat).abs().clamp(0.002, 999.0);
    final lngSpan = (maxLng - minLng).abs().clamp(0.002, 999.0);
    final nx = (lng - minLng) / lngSpan;
    final ny = 1 - (lat - minLat) / latSpan;
    return Offset(
      size.width * (pad + nx * (1 - 2 * pad)),
      size.height * (pad + ny * (1 - 2 * pad)),
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  void _drawPulse(Canvas canvas, Offset center, Color color) {
    final pulse = Paint()..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(center, 22, pulse);
    canvas.drawCircle(center, 14, pulse..color = color.withValues(alpha: 0.28));
  }

  void _drawPin(Canvas canvas, Offset center, Color color, IconData iconData) {
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 18,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TrackingMapPainter old) =>
      old.customerLat != customerLat ||
      old.customerLng != customerLng ||
      old.assistantLat != assistantLat ||
      old.assistantLng != assistantLng ||
      old.progress != progress;
}
