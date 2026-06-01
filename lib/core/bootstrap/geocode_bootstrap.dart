import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../location/location_service.dart';
import '../providers/providers.dart';

/// Wires backend geocode API into [LocationService] at app start.
class GeocodeBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const GeocodeBootstrap({super.key, required this.child});

  @override
  ConsumerState<GeocodeBootstrap> createState() => _GeocodeBootstrapState();
}

class _GeocodeBootstrapState extends ConsumerState<GeocodeBootstrap> {
  @override
  void initState() {
    super.initState();
    LocationService.useGeocode(ref.read(geocodeRepositoryProvider));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
