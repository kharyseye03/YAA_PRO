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

/// Position du livreur en continu, pour le suivi pendant la
/// navigation. Émet une nouvelle position tous les 5 mètres.
final positionStreamProvider = StreamProvider<Position>((ref) async* {
  // Garantit que la permission est accordée avant d'ouvrir le flux
  await ref.read(locationServiceProvider).getCurrentPosition();
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    ),
  );
});
