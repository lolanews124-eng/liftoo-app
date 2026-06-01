import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/app_config.dart';
import 'maps_placeholder.dart';

/// Map display (Google Maps SDK). Geocoding/search uses backend APIs only.
class LiftooMapView extends StatelessWidget {
  final double lat;
  final double lng;
  final double height;
  final String title;
  final String? subtitle;
  final bool showMyLocation;

  const LiftooMapView({
    super.key,
    required this.lat,
    required this.lng,
    this.height = 200,
    this.title = 'Location',
    this.subtitle,
    this.showMyLocation = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasGoogleMapsKey) {
      return MapsPlaceholder(
        title: title,
        subtitle: subtitle ?? 'Add googleMapsApiKey in app_config.dart + native config',
        height: height,
      );
    }

    final target = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: target, zoom: 15),
          markers: {
            Marker(
              markerId: const MarkerId('pickup'),
              position: target,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
          },
          myLocationEnabled: showMyLocation,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
        ),
      ),
    );
  }
}
