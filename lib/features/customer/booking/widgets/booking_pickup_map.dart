import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/nearby_assistant_model.dart';
import '../../../../shared/widgets/map/map_marker_factory.dart';
import '../../../../shared/widgets/maps_placeholder.dart';

/// Pickup + Liftoo assistant availability map (Uber-style cluster at pickup).
class BookingPickupMap extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupTitle;
  final List<NearbyAssistantModel> assistants;
  final double height;

  const BookingPickupMap({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupTitle,
    required this.assistants,
    this.height = 300,
  });

  @override
  State<BookingPickupMap> createState() => _BookingPickupMapState();
}

class _BookingPickupMapState extends State<BookingPickupMap> {
  GoogleMapController? _mapController;
  Timer? _fitDebounce;
  Set<Marker> _markers = {};
  bool _iconsReady = false;
  double _zoom = 15.5;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void dispose() {
    _fitDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BookingPickupMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved = oldWidget.pickupLat != widget.pickupLat || oldWidget.pickupLng != widget.pickupLng;
    final assistantsChanged = oldWidget.assistants.length != widget.assistants.length ||
        oldWidget.assistants.map((e) => e.id).join() != widget.assistants.map((e) => e.id).join();
    if (moved || assistantsChanged) {
      _loadMarkers();
      _scheduleFitCamera();
    }
  }

  Future<void> _loadMarkers() async {
    if (!AppConfig.hasGoogleMapsKey) return;

    try {
      final pickupIcon = await MapMarkerFactory.pickup();
      final assistantIcon = await MapMarkerFactory.assistant();
      final spread = MapMarkerFactory.spreadAroundPickup(
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        assistants: widget.assistants,
      );

      final markers = <Marker>{
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat, widget.pickupLng),
          icon: pickupIcon,
          anchor: const Offset(0.5, 0.88),
          zIndex: 2,
          infoWindow: InfoWindow(title: widget.pickupTitle, snippet: 'Your pickup location'),
        ),
        for (final p in spread)
          Marker(
            markerId: MarkerId('asst-${p.model.id}'),
            position: LatLng(p.lat, p.lng),
            icon: assistantIcon,
            anchor: const Offset(0.5, 0.92),
            zIndex: 1,
            infoWindow: InfoWindow(
              title: p.model.name,
              snippet: p.model.distanceKm != null
                  ? '${p.model.distanceKm!.toStringAsFixed(1)} km • ★ ${p.model.rating.toStringAsFixed(1)}'
                  : 'Liftoo assistant • Online',
            ),
          ),
      };

      if (mounted) {
        setState(() {
          _markers = markers;
          _iconsReady = true;
        });
        _scheduleFitCamera();
      }
    } catch (_) {
      if (mounted) setState(() => _iconsReady = true);
    }
  }

  void _scheduleFitCamera() {
    _fitDebounce?.cancel();
    _fitDebounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) _fitCamera();
    });
  }

  Future<void> _fitCamera() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[LatLng(widget.pickupLat, widget.pickupLng)];
    for (final a in widget.assistants) {
      if (a.hasCoordinates) points.add(LatLng(a.lat!, a.lng!));
    }
    final spread = MapMarkerFactory.spreadAroundPickup(
      pickupLat: widget.pickupLat,
      pickupLng: widget.pickupLng,
      assistants: widget.assistants,
    );
    for (final p in spread) {
      points.add(LatLng(p.lat, p.lng));
    }

    try {
      if (points.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: points.first, zoom: 15.5)),
        );
        return;
      }

      var minLat = points.first.latitude;
      var maxLat = points.first.latitude;
      var minLng = points.first.longitude;
      var maxLng = points.first.longitude;
      for (final p in points) {
        minLat = math.min(minLat, p.latitude);
        maxLat = math.max(maxLat, p.latitude);
        minLng = math.min(minLng, p.longitude);
        maxLng = math.max(maxLng, p.longitude);
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
    } catch (_) {}
  }

  Future<void> _recenter() async {
    await _fitCamera();
  }

  Future<void> _zoomBy(double delta) async {
    final controller = _mapController;
    if (controller == null) return;
    _zoom = (_zoom + delta).clamp(10.0, 20.0);
    await controller.animateCamera(CameraUpdate.zoomTo(_zoom));
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasGoogleMapsKey) {
      return _LiftooPlaceholderMap(
        height: widget.height,
        pickupTitle: widget.pickupTitle,
        assistants: widget.assistants,
      );
    }

    final target = LatLng(widget.pickupLat, widget.pickupLng);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: Stack(
            children: [
              GoogleMap(
                key: ValueKey('map-${widget.pickupLat.toStringAsFixed(4)}-${widget.pickupLng.toStringAsFixed(4)}'),
                initialCameraPosition: CameraPosition(target: target, zoom: 15.5),
                markers: _iconsReady ? _markers : {},
                onMapCreated: (c) {
                  _mapController = c;
                  _scheduleFitCamera();
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                buildingsEnabled: true,
                trafficEnabled: false,
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: _MapLocationChip(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: widget.pickupTitle,
                  subtitle: 'Pickup location',
                ),
              ),
              if (widget.assistants.isNotEmpty)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: _MapLegendChip(count: widget.assistants.length),
                ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapCircleButton(icon: Icons.add, onTap: () => _zoomBy(1)),
                    const SizedBox(height: 8),
                    _MapCircleButton(icon: Icons.remove, onTap: () => _zoomBy(-1)),
                    const SizedBox(height: 8),
                    _MapCircleButton(icon: Icons.my_location, onTap: _recenter),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }
}

class _MapLocationChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;

  const _MapLocationChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLegendChip extends StatelessWidget {
  final int count;

  const _MapLegendChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              '$count assistant${count == 1 ? '' : 's'} nearby',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiftooPlaceholderMap extends StatelessWidget {
  final double height;
  final String pickupTitle;
  final List<NearbyAssistantModel> assistants;

  const _LiftooPlaceholderMap({
    required this.height,
    required this.pickupTitle,
    required this.assistants,
  });

  @override
  Widget build(BuildContext context) {
    final n = assistants.length.clamp(0, 8);

    return Stack(
      children: [
        MapsPlaceholder(
          title: pickupTitle,
          subtitle: assistants.isEmpty
              ? 'No assistants online nearby'
              : '$n Liftoo assistant${n == 1 ? '' : 's'} near your pickup',
          height: height,
          showComingSoonBadge: false,
        ),
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: _MapLocationChip(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF10B981),
            label: pickupTitle,
            subtitle: 'Pickup location',
          ),
        ),
        if (n > 0)
          ...List.generate(n, (i) {
            final angle = (2 * math.pi * i) / n - math.pi / 2;
            return Positioned.fill(
              child: Align(
                alignment: Alignment(0.55 * math.cos(angle), -0.05 + 0.35 * math.sin(angle)),
                child: _AssistantPin(name: assistants[i].name),
              ),
            );
          }),
        if (n > 0)
          Positioned(
            bottom: 12,
            left: 12,
            child: _MapLegendChip(count: n),
          ),
      ],
    );
  }
}

class _AssistantPin extends StatelessWidget {
  final String name;

  const _AssistantPin({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('L', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
