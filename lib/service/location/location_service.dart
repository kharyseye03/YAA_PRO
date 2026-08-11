import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Position GPS actuelle (gère permissions + service désactivé).
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Le GPS est désactivé.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Permission refusée définitivement. Activez-la dans les réglages.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Coordonnées → libellé court « Quartier, Ville ».
  ///
  /// S'appuie sur le géocodeur natif de l'appareil (Geocoder côté
  /// Android, CLGeocoder côté iOS) : ni clé API, ni quota, ni
  /// facturation. Retourne null quand aucune adresse n'est trouvée,
  /// l'appelant décide quoi afficher.
  /// La locale est un réglage global du géocodeur, posé une seule fois.
  static bool _localePosee = false;

  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      if (!_localePosee) {
        await setLocaleIdentifier('fr_FR');
        _localePosee = true;
      }
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return null;
      final mark = marks.first;

      // Du plus précis au plus large : le premier champ renseigné
      // gagne. Les plateformes laissent des chaînes vides plutôt que
      // null quand un niveau est inconnu.
      final quartier = _premierNonVide(
          [mark.subLocality, mark.thoroughfare, mark.subAdministrativeArea]);
      final ville =
          _premierNonVide([mark.locality, mark.administrativeArea]);

      if (quartier != null && ville != null) return '$quartier, $ville';
      return ville ?? quartier;
    } catch (e) {
      // Hors ligne, ou géocodeur indisponible sur l'appareil
      debugPrint('Géocodage inverse indisponible : $e');
      return null;
    }
  }

  static String? _premierNonVide(List<String?> valeurs) {
    for (final v in valeurs) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return null;
  }

  /// Position + libellé en un seul appel.
  ///
  /// Le libellé est purement indicatif : s'il ne peut pas être résolu,
  /// on rend quand même la position, dont dépendent les calculs de
  /// distance et l'affichage de la carte.
  Future<({Position position, String label})> getCurrentLocation() async {
    final position = await getCurrentPosition();
    final label =
        await reverseGeocode(position.latitude, position.longitude);
    return (position: position, label: label ?? 'Position actuelle');
  }
}
