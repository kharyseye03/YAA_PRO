import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import '../../../model/order/mission.dart';
import '../../../model/order/nav_route.dart';
import '../../../service/maps/directions_service.dart';
import '../../../service/storage/active_mission_storage.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../home/providers/location_provider.dart';

/// Identifiant de la mission en cours du livreur (null s'il n'en a pas).
/// Restauré depuis le stockage local au lancement de l'app.
class ActiveMissionIdNotifier extends StateNotifier<int?> {
  ActiveMissionIdNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    state = await ActiveMissionStorage.instance.get();
  }

  Future<void> start(int missionId) async {
    await ActiveMissionStorage.instance.save(missionId);
    state = missionId;
  }

  Future<void> finish() async {
    await ActiveMissionStorage.instance.clear();
    state = null;
  }
}

final activeMissionIdProvider =
    StateNotifierProvider<ActiveMissionIdNotifier, int?>(
  (ref) => ActiveMissionIdNotifier(),
);

/// Détail de la mission en cours, rechargé automatiquement quand
/// le livreur en accepte une nouvelle ou la termine.
final activeMissionProvider = FutureProvider<Mission?>((ref) async {
  final id = ref.watch(activeMissionIdProvider);
  if (id == null) return null;
  return ref.read(apiServiceProvider).getMissionDetail(id);
});

final directionsServiceProvider =
    Provider<DirectionsService>((ref) => DirectionsService());

/// Destination de l'étape en cours : point de récupération tant que
/// le colis n'est pas pris en charge, point de livraison ensuite.
LatLng? activeDestinationOf(Mission mission) {
  final lat = mission.currentLatitude;
  final lng = mission.currentLongitude;
  if (lat == null || lng == null) return null;
  return LatLng(latitude: lat, longitude: lng);
}

/// Tracés affichés sur la carte pendant la mission :
/// - [active]  : ma position → destination de l'étape en cours,
///   avec les manœuvres pour le guidage
/// - [preview] : aperçu du trajet de la course (étape 1 seulement)
typedef MissionRoutes = ({NavRoute active, List<LatLng> preview});

final activeRouteProvider = FutureProvider<MissionRoutes>((ref) async {
  const empty = (active: NavRoute.empty, preview: <LatLng>[]);

  final mission = await ref.watch(activeMissionProvider.future);
  if (mission == null) return empty;

  final destination = activeDestinationOf(mission);
  if (destination == null) return empty;

  final service = ref.read(directionsServiceProvider);
  final me = ref.watch(currentLocationProvider).valueOrNull?.position;

  final active = me == null
      ? NavRoute.empty
      : await service.getNavRoute(
          origin: LatLng(latitude: me.latitude, longitude: me.longitude),
          destination: destination,
        );

  // Étape 2 : plus d'aperçu, le trajet affiché est déjà le bon
  if (mission.isPickedUp) return (active: active, preview: <LatLng>[]);

  final dropoff = mission.latitudeArrivee != null &&
          mission.longitudeArrivee != null
      ? LatLng(
          latitude: mission.latitudeArrivee!,
          longitude: mission.longitudeArrivee!)
      : null;
  final preview = dropoff == null
      ? <LatLng>[]
      : await service.getRoute(origin: destination, destination: dropoff);

  return (active: active, preview: preview);
});
