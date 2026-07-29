import 'package:flutter/foundation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Résultat d'un démarrage de guidage.
enum NavStartResult {
  ok,
  termsRefused,
  routeNotFound,
  networkError,
  apiKeyNotAuthorized,
  quotaExceeded,
  locationUnavailable,
  error,
}

/// Guidage turn-by-turn natif via le Navigation SDK de Google.
///
/// Facturation : un événement « Navigation Request » par destination
/// définie — le guidage vocal, le trafic et les recalculs d'itinéraire
/// sont inclus ensuite sans surcoût.
class NavigationService {
  /// Le SDK impose d'afficher les conditions d'utilisation Google au
  /// conducteur avant tout guidage. Retourne false s'il refuse.
  Future<bool> ensureTermsAccepted() async {
    if (await GoogleMapsNavigator.areTermsAccepted()) return true;
    return GoogleMapsNavigator.showTermsAndConditionsDialog(
      'YAA PRO',
      'YAA',
    );
  }

  /// Démarre le guidage vocal vers un point.
  Future<NavStartResult> startGuidanceTo({
    required double latitude,
    required double longitude,
    required String title,
  }) async {
    try {
      if (!await ensureTermsAccepted()) return NavStartResult.termsRefused;

      if (!await GoogleMapsNavigator.isInitialized()) {
        await GoogleMapsNavigator.initializeNavigationSession();
      }

      final status = await GoogleMapsNavigator.setDestinations(
        Destinations(
          waypoints: [
            NavigationWaypoint.withLatLngTarget(
              title: title,
              target: LatLng(latitude: latitude, longitude: longitude),
            ),
          ],
          displayOptions:
              NavigationDisplayOptions(showDestinationMarkers: true),
        ),
      );

      debugPrint('🧭 setDestinations → $status');
      switch (status) {
        case NavigationRouteStatus.statusOk:
          break;
        case NavigationRouteStatus.routeNotFound:
          return NavStartResult.routeNotFound;
        case NavigationRouteStatus.networkError:
          return NavStartResult.networkError;
        case NavigationRouteStatus.apiKeyNotAuthorized:
          return NavStartResult.apiKeyNotAuthorized;
        case NavigationRouteStatus.quotaExceeded:
        case NavigationRouteStatus.quotaCheckFailed:
          return NavStartResult.quotaExceeded;
        case NavigationRouteStatus.locationUnavailable:
        case NavigationRouteStatus.locationUnknown:
          return NavStartResult.locationUnavailable;
        default:
          return NavStartResult.error;
      }

      await GoogleMapsNavigator.setAudioGuidance(
        NavigationAudioGuidanceSettings(
          guidanceType: NavigationAudioGuidanceType.alertsAndGuidance,
          isVibrationEnabled: true,
        ),
      );
      await GoogleMapsNavigator.startGuidance();
      return NavStartResult.ok;
    } catch (e) {
      debugPrint('❌ Navigation → $e');
      return NavStartResult.error;
    }
  }

  /// Arrête le guidage et libère la session.
  Future<void> stopGuidance() async {
    try {
      if (await GoogleMapsNavigator.isInitialized()) {
        await GoogleMapsNavigator.stopGuidance();
        await GoogleMapsNavigator.clearDestinations();
      }
    } catch (e) {
      debugPrint('❌ Arrêt navigation → $e');
    }
  }

  /// ⏳ Test uniquement : simule le déplacement du livreur le long de
  /// l'itinéraire, pour vérifier le guidage sans se déplacer.
  /// [speedMultiplier] accélère le trajet — à vitesse réelle, une
  /// course de 15 min met 15 min à défiler.
  Future<void> startSimulation({double speedMultiplier = 5}) async {
    try {
      debugPrint('🧪 Simulation lancée (x$speedMultiplier)');
      await GoogleMapsNavigator.simulator
          .simulateLocationsAlongExistingRouteWithOptions(
        SimulationOptions(speedMultiplier: speedMultiplier),
      );
      debugPrint('🧪 Simulation en cours');
    } catch (e) {
      debugPrint('❌ Simulation → $e');
    }
  }

  /// Message utilisateur correspondant à un échec de démarrage.
  static String messageFor(NavStartResult result) => switch (result) {
        NavStartResult.ok => '',
        NavStartResult.termsRefused =>
          'Vous devez accepter les conditions pour utiliser le guidage.',
        NavStartResult.routeNotFound =>
          'Aucun itinéraire trouvé vers ce point.',
        NavStartResult.networkError =>
          'Guidage indisponible : le téléphone n\'arrive pas à joindre '
              'les serveurs Google. Vérifiez l\'accès Internet.',
        NavStartResult.apiKeyNotAuthorized =>
          'Clé Google non autorisée pour le Navigation SDK.',
        NavStartResult.quotaExceeded =>
          'Quota Google dépassé pour le guidage.',
        NavStartResult.locationUnavailable =>
          'Position GPS indisponible : activez la localisation.',
        NavStartResult.error => 'Impossible de démarrer le guidage.',
      };
}
