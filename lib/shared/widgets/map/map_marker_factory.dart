import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../models/nearby_assistant_model.dart';

/// Bitmap markers for Liftoo maps (pickup + assistant availability).
class MapMarkerFactory {
  static BitmapDescriptor? _pickup;
  static BitmapDescriptor? _assistant;

  static Future<BitmapDescriptor> pickup() async {
    _pickup ??= await _fromCanvas(_drawPickup);
    return _pickup!;
  }

  static Future<BitmapDescriptor> assistant() async {
    _assistant ??= await _fromCanvas(_drawAssistant);
    return _assistant!;
  }

  static Future<BitmapDescriptor> _fromCanvas(void Function(Canvas, Size) draw) async {
    const w = 96.0;
    const h = 112.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    draw(canvas, const Size(w, h));
    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), width: 48);
  }

  static void _drawPickup(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    const r = 22.0;

    canvas.drawCircle(Offset(cx, cy), r + 6, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx, cy), r + 3, Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.35));
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(Offset(cx, cy), 7, Paint()..color = Colors.white);

    final stem = Path()
      ..moveTo(cx - 6, cy + r - 2)
      ..lineTo(cx + 6, cy + r - 2)
      ..lineTo(cx, cy + r + 18)
      ..close();
    canvas.drawPath(stem, Paint()..color = const Color(0xFF10B981));
    canvas.drawPath(
      stem,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  static void _drawAssistant(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 6, w - 16, h - 28),
      const Radius.circular(14),
    );

    canvas.drawRRect(
      body.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(body, Paint()..color = AppColors.primary);

    _paintIcon(canvas, Icons.shopping_bag_rounded, Offset(w / 2, h * 0.34), 26, Colors.white);

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h - 16), width: 28, height: 22),
      const Radius.circular(8),
    );
    canvas.drawRRect(badgeRect, Paint()..color = AppColors.navy);
    final tp = TextPainter(
      text: const TextSpan(
        text: 'L',
        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h - 16 - tp.height / 2));
  }

  static void _paintIcon(Canvas canvas, IconData icon, Offset center, double size, Color color) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  /// Spread assistants in a ring around pickup when clustered (visual only).
  static List<({NearbyAssistantModel model, double lat, double lng})> spreadAroundPickup({
    required double pickupLat,
    required double pickupLng,
    required List<NearbyAssistantModel> assistants,
    double ringMeters = 120,
  }) {
    final withCoords = <({NearbyAssistantModel model, double lat, double lng})>[];
    for (final a in assistants) {
      if (!a.hasCoordinates) continue;
      withCoords.add((model: a, lat: a.lat!, lng: a.lng!));
    }
    if (withCoords.length <= 1) return withCoords;

    final allNearPickup = withCoords.every((p) {
      final d = _haversineM(pickupLat, pickupLng, p.lat, p.lng);
      return d < ringMeters * 2;
    });

    if (!allNearPickup) return withCoords;

    final n = withCoords.length;
    final latRad = pickupLat * math.pi / 180;
    final mPerDegLat = 111320.0;
    final mPerDegLng = 111320.0 * math.cos(latRad);
    final radiusDeg = ringMeters / ((mPerDegLat + mPerDegLng) / 2);

    return [
      for (var i = 0; i < n; i++)
        (
          model: withCoords[i].model,
          lat: pickupLat + radiusDeg * math.sin(2 * math.pi * i / n),
          lng: pickupLng + radiusDeg * math.cos(2 * math.pi * i / n),
        ),
    ];
  }

  static double _haversineM(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}
