import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../model/order/mission.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../home/providers/location_provider.dart';
import 'refused_missions_provider.dart';

/// Rayon de recherche par défaut autour du coursier (en mètres).
/// Large : c'est le filtre « Proches » qui sert à restreindre.
const int kSearchRadiusMetres = 15000;

/// Rayons proposés au coursier pour le filtre « Proches » (en mètres).
const List<int> kNearRadiusOptions = [1000, 2000, 5000, 10000];

/// « 1 km », « 500 m »…
String radiusLabel(int metres) =>
    metres >= 1000 ? '${metres ~/ 1000} km' : '$metres m';

/// Filtres disponibles sur l'écran Commandes.
enum OrderFilter {
  toutes('Toutes'),
  proches('Proches'),
  mieuxPayees('Bien payées'),
  livraison('Livraison'),
  course('Course');

  final String label;
  const OrderFilter(this.label);

  /// Valeur du paramètre `tri` envoyée à l'API (null = pas de tri serveur).
  String? get triParam => this == OrderFilter.mieuxPayees ? 'MIEUX_PAYE' : null;

  /// Valeur du paramètre de type de service (null = tous les types).
  String? get typeServiceParam => switch (this) {
        OrderFilter.livraison => 'LIVRAISON',
        OrderFilter.course => 'COURSE',
        _ => null,
      };
}

/// Distance à vol d'oiseau entre le coursier et le point de départ
/// de la mission, en mètres. `null` si une position manque.
///
/// À ne pas confondre avec [Mission.distanceKm], qui est la longueur
/// du trajet départ → arrivée.
double? distanceToPickup(Mission m, Position? me) {
  if (me == null || m.latitudeDepart == null || m.longitudeDepart == null) {
    return null;
  }
  return Geolocator.distanceBetween(
    me.latitude,
    me.longitude,
    m.latitudeDepart!,
    m.longitudeDepart!,
  );
}

/// « à 300 m de vous », « à 1.2 km de vous ». `null` si la position
/// du coursier n'est pas connue.
String? distanceToPickupLabel(Mission m, Position? me) {
  final d = distanceToPickup(m, me);
  if (d == null) return null;
  return d < 1000
      ? 'à ${d.round()} m de vous'
      : 'à ${(d / 1000).toStringAsFixed(1)} km de vous';
}

/// La plus récente en premier.
int _byDateDesc(Mission a, Mission b) {
  if (a.dateCreationMission == null && b.dateCreationMission == null) return 0;
  if (a.dateCreationMission == null) return 1;
  if (b.dateCreationMission == null) return -1;
  return b.dateCreationMission!.compareTo(a.dateCreationMission!);
}

/// Détail complet d'une mission : contacts, commerçant, instructions.
/// Ces champs n'existent pas dans la liste, il faut les charger à part.
final missionDetailProvider =
    FutureProvider.family<Mission, int>((ref, missionId) async {
  return ref.read(apiServiceProvider).getMissionDetail(missionId);
});

/// Filtre actuellement sélectionné sur l'écran Commandes.
final orderFilterProvider =
    StateProvider<OrderFilter>((ref) => OrderFilter.toutes);


/// Rayon choisi par le coursier pour le filtre « Proches ».
final nearRadiusProvider =
    StateProvider<int>((ref) => kNearRadiusOptions.first);

/// Toutes les missions disponibles, sans filtre — source du dashboard
/// et des badges, qui restent donc indépendants du filtre choisi.
final allOrdersProvider = FutureProvider<List<Mission>>((ref) async {
  // ⚠️ Les paramètres latitude/longitude/rayon ne sont pas envoyés :
  // le backend renvoie alors un jeu de données erroné et ignore le
  // rayon (bug signalé). Le filtrage par distance se fait côté app.
  final orders = await ref.read(apiServiceProvider).getAvailableOrders();
  orders.sort(_byDateDesc);
  return orders;
});

List<Mission> _withoutRefused(List<Mission> list, Set<int> refused) =>
    refused.isEmpty
        ? list
        : list.where((m) => !refused.contains(m.id)).toList();

/// Liste complète moins les missions refusées — dashboard et badges.
/// Dérivé : masquer une mission ne relance aucune requête.
final dashboardOrdersProvider = Provider<AsyncValue<List<Mission>>>((ref) {
  final refused = ref.watch(refusedMissionsProvider);
  return ref
      .watch(allOrdersProvider)
      .whenData((l) => _withoutRefused(l, refused));
});

/// Missions affichées sur l'écran Commandes, selon [orderFilterProvider].
final availableOrdersProvider = FutureProvider<List<Mission>>((ref) async {
  final filter = ref.watch(orderFilterProvider);

  // Mêmes paramètres de requête que la liste complète : on réutilise
  // son résultat plutôt que de relancer un appel réseau.
  if (filter == OrderFilter.toutes) {
    return ref.watch(allOrdersProvider.future);
  }

  final loc = ref.watch(currentLocationProvider).valueOrNull;
  final rayon = ref.watch(nearRadiusProvider);

  // Pas de coordonnées envoyées : voir le commentaire de
  // [allOrdersProvider]. Le rayon est appliqué côté app.
  final orders = await ref.read(apiServiceProvider).getAvailableOrders(
        tri: filter.triParam,
        typeService: filter.typeServiceParam,
      );

  switch (filter) {
    // Filtre et tri appliqués aussi côté app : le rayon porte sur la
    // distance jusqu'au point de départ, pas sur la longueur du trajet.
    case OrderFilter.proches:
      final me = loc?.position;
      final proches = orders.where((o) {
        final d = distanceToPickup(o, me);
        return d == null || d <= rayon;
      }).toList();
      proches.sort((a, b) {
        final da = distanceToPickup(a, me) ?? double.infinity;
        final db = distanceToPickup(b, me) ?? double.infinity;
        return da.compareTo(db);
      });
      return proches;

    // Tri par montant décroissant garanti côté app
    case OrderFilter.mieuxPayees:
      orders.sort((a, b) => b.montant.compareTo(a.montant));

    default:
      orders.sort(_byDateDesc);
  }
  return orders;
});

/// Liste filtrée moins les missions refusées — écran Commandes.
/// Dérivé : masquer une mission ne relance aucune requête.
final visibleOrdersProvider = Provider<AsyncValue<List<Mission>>>((ref) {
  final refused = ref.watch(refusedMissionsProvider);
  return ref
      .watch(availableOrdersProvider)
      .whenData((l) => _withoutRefused(l, refused));
});
