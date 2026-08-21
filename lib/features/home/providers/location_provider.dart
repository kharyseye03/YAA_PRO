import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../service/location/location_service.dart';
import '../../../service/location/position_publisher.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../delivery/providers/active_mission_provider.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

/// Position GPS + libellé « Quartier, Ville » du livreur.
/// Rechargeable via ref.invalidate(currentLocationProvider).
final currentLocationProvider =
    FutureProvider<({Position position, String label})>((ref) async {
  return ref.read(locationServiceProvider).getCurrentLocation();
});

/// Position du livreur en continu, pour le suivi pendant la mission.
/// Émet une nouvelle position tous les 5 mètres.
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

/// Publie la position du livreur vers le backend tant qu'une mission
/// est en cours, pour que le client puisse le suivre sur sa carte.
///
/// S'active à l'acceptation d'une mission et s'arrête à la livraison :
/// hors mission, la position du livreur ne regarde personne, et le GPS
/// n'a aucune raison de rester allumé.
///
/// Doit être observé par un widget vivant en permanence — c'est
/// [MainShell] qui s'en charge — sinon il n'est jamais construit.
final positionPublishingProvider = Provider<void>((ref) {
  final missionId = ref.watch(activeMissionIdProvider);
  if (missionId == null) return;

  final publisher = PositionPublisher(
    ref.read(apiServiceProvider),
    // Dernier libellé connu, sans recalcul : le champ adresse est
    // indicatif, il ne justifie pas un géocodage toutes les 15 s.
    adresse: () => ref.read(currentLocationProvider).valueOrNull?.label ?? '',
  );
  debugPrint('📍 Suivi démarré pour la mission $missionId');
  publisher.demarrer();

  final abonnement = ref.listen<AsyncValue<Position>>(
    positionStreamProvider,
    (_, next) {
      final position = next.valueOrNull;
      if (position != null) publisher.onPosition(position);
    },
    fireImmediately: true,
  );

  ref.onDispose(() {
    abonnement.close();
    publisher.arreter();
    debugPrint('📍 Suivi arrêté');
  });
});
