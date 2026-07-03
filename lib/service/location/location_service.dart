import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../config/maps/maps_config.dart';

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

  /// Coordonnées → libellé court « Quartier, Ville »
  /// via Google Geocoding API.
  Future<String> reverseGeocode(double lat, double lng) async {
    final response =
        await http.get(Uri.parse(MapsConfig.reverseGeocodeUrl(lat, lng)));
    if (response.statusCode != 200) {
      throw Exception('Erreur geocoding (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) throw Exception('Adresse introuvable.');

    String? quartier;
    String? ville;

    for (final result in results) {
      final components =
          (result['address_components'] as List<dynamic>? ?? []);
      for (final comp in components) {
        final types = (comp['types'] as List<dynamic>).cast<String>();
        final name = comp['long_name'] as String;
        if (quartier == null &&
            (types.contains('sublocality') ||
                types.contains('sublocality_level_1') ||
                types.contains('neighborhood'))) {
          quartier = name;
        }
        if (ville == null && types.contains('locality')) {
          ville = name;
        }
      }
      if (quartier != null && ville != null) break;
    }

    if (quartier != null && ville != null) return '$quartier, $ville';
    if (ville != null) return ville;
    if (quartier != null) return quartier;

    // Fallback : adresse formatée du premier résultat
    return (results.first['formatted_address'] as String?) ??
        'Position inconnue';
  }

  /// Position + libellé en un seul appel.
  Future<({Position position, String label})> getCurrentLocation() async {
    final position = await getCurrentPosition();
    final label =
        await reverseGeocode(position.latitude, position.longitude);
    return (position: position, label: label);
  }
}
