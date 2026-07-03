import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../service/location/location_service.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

/// Position GPS + libellé « Quartier, Ville » du livreur.
/// Rechargeable via ref.invalidate(currentLocationProvider).
final currentLocationProvider =
    FutureProvider<({Position position, String label})>((ref) async {
  return ref.read(locationServiceProvider).getCurrentLocation();
});
