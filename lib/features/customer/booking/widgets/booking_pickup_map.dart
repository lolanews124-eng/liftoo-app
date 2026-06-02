import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/nearby_assistant_model.dart';
import '../../../../shared/widgets/maps_placeholder.dart';

/// Pickup pin + online assistant pins (Rapido-style booking map).
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
    this.height = 280,
  });

  @override
  State<BookingPickupMap> createState() => _BookingPickupMapState();
}

class _BookingPickupMapState extends State<BookingPickupMap> {
  GoogleMapController? _mapController;
  Timer? _fitDebounce;
  Set<Marker>? _cachedMarkers;

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
    final assistantsChanged = oldWidget.assistants.length != widget.assistants.length;
    if (moved || assistantsChanged) {
      _cachedMarkers = null;
      _scheduleFitCamera();
    }
  }

  void _scheduleFitCamera() {
    _fitDebounce?.cancel();
    _fitDebounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) _fitCamera();
    });
  }

  Set<Marker> _buildMarkers() {
    return _cachedMarkers ??= {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
        infoWindow: InfoWindow(title: widget.pickupTitle, snippet: 'Pickup'),
      ),
      for (final a in widget.assistants)
        if (a.hasCoordinates)
          Marker(
            markerId: MarkerId('asst-${a.id}'),
            position: LatLng(a.lat!, a.lng!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: a.name,
              snippet: a.distanceKm != null
                  ? '${a.distanceKm!.toStringAsFixed(1)} km • ★ ${a.rating.toStringAsFixed(1)}'
                  : 'Online',
            ),
          ),
    };
  }

  Future<void> _fitCamera() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[LatLng(widget.pickupLat, widget.pickupLng)];
    for (final a in widget.assistants) {
      if (a.hasCoordinates) points.add(LatLng(a.lat!, a.lng!));
    }

    try {
      if (points.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: points.first, zoom: 15)),
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
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasGoogleMapsKey) {
      return _PlaceholderMap(
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
          child: GoogleMap(
            key: ValueKey('map-${widget.pickupLat.toStringAsFixed(4)}-${widget.pickupLng.toStringAsFixed(4)}'),
            initialCameraPosition: CameraPosition(target: target, zoom: 15),
            markers: _buildMarkers(),
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
        ),
      ),
    );
  }
}

class _PlaceholderMap extends StatelessWidget {
  final double height;
  final String pickupTitle;
  final List<NearbyAssistantModel> assistants;

  const _PlaceholderMap({
    required this.height,
    required this.pickupTitle,
    required this.assistants,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapsPlaceholder(
          title: pickupTitle,
          subtitle: assistants.isEmpty
              ? 'No assistants online nearby'
              : '${assistants.length} assistant${assistants.length == 1 ? '' : 's'} online near you',
          height: height,
          showComingSoonBadge: false,
        ),
        if (assistants.isNotEmpty)
          ...assistants.take(6).toList().asMap().entries.map((e) {
            final i = e.key;
            final a = e.value;
            return Positioned(
              left: 24.0 + (i * 36) % (height * 0.5),
              top: 48.0 + (i * 22) % (height * 0.35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        a.name.isNotEmpty ? a.name[0].toUpperCase() : 'A',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (a.distanceKm != null)
                    Text(
                      '${a.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
