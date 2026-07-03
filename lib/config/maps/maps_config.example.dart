// ⚠️ TEMPLATE — Copiez ce fichier vers maps_config.dart
// et collez votre clé API Google Cloud.
// maps_config.dart est ignoré par git (contient la clé API).

class MapsConfig {
  // Clé API Google Cloud (AIzaSy...)
  static const String apiKey = 'VOTRE_CLE_API_GOOGLE';

  // ── Places API (autocomplétion) ───────────────────────────
  static const String placesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  static String autocompleteUrl(String input) =>
      '$placesBaseUrl/autocomplete/json'
      '?input=${Uri.encodeComponent(input)}'
      '&components=country:sn'
      '&language=fr'
      '&key=$apiKey';

  static String placeDetailsUrl(String placeId) =>
      '$placesBaseUrl/details/json'
      '?place_id=$placeId'
      '&fields=geometry,formatted_address'
      '&language=fr'
      '&key=$apiKey';

  // ── Geocoding API ─────────────────────────────────────────
  static String reverseGeocodeUrl(double lat, double lng) =>
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=$lat,$lng'
      '&language=fr'
      '&key=$apiKey';
}
