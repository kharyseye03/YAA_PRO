// ⚠️ TEMPLATE — Copiez ce fichier vers maps_config.dart
// et collez votre clé API Google Cloud.
// maps_config.dart est ignoré par git (contient la clé API).
//
// Cette clé est celle des appels HTTPS faits depuis l'app : elle ne
// peut porter aucune restriction d'application, contrairement aux clés
// des SDK natifs (AndroidManifest.xml et AppDelegate.swift).
// À restreindre côté Google Cloud à l'API Directions uniquement.

class MapsConfig {
  // Clé API Google Cloud (AIzaSy...)
  static const String apiKey = 'VOTRE_CLE_API_GOOGLE';

  // ── Directions API ────────────────────────────────────────
  // Itinéraire routier entre deux points (tracé sur la carte)
  static String directionsUrl(
    double originLat,
    double originLng,
    double destLat,
    double destLng,
  ) =>
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=$originLat,$originLng'
      '&destination=$destLat,$destLng'
      '&mode=driving'
      '&language=fr'
      '&key=$apiKey';
}
