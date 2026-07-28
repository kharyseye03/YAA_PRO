import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:http/http.dart' as http;
import '../../config/maps/maps_config.dart';
import '../../model/order/nav_route.dart';

class DirectionsService {
  /// Itinéraire complet : tracé + manœuvres détaillées.
  /// Retourne [NavRoute.empty] si l'itinéraire est introuvable.
  Future<NavRoute> getNavRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final data = await _fetch(origin, destination);
    if (data == null) return NavRoute.empty;

    final route = (data['routes'] as List<dynamic>).first
        as Map<String, dynamic>;
    final legs = route['legs'] as List<dynamic>;
    if (legs.isEmpty) return NavRoute.empty;
    final leg = legs.first as Map<String, dynamic>;

    return NavRoute(
      polyline: decodePolyline((route['overview_polyline']
          as Map<String, dynamic>)['points'] as String),
      steps: (leg['steps'] as List<dynamic>)
          .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      distanceMetres:
          ((leg['distance'] as Map?)?['value'] as num?)?.toInt() ?? 0,
      durationSeconds:
          ((leg['duration'] as Map?)?['value'] as num?)?.toInt() ?? 0,
    );
  }

  /// Tracé routier entre deux points, prêt à dessiner sur la carte.
  /// Retourne une liste vide si l'itinéraire est introuvable.
  Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final data = await _fetch(origin, destination);
    if (data == null) return const [];

    final route = (data['routes'] as List<dynamic>).first
        as Map<String, dynamic>;
    return decodePolyline(
        (route['overview_polyline'] as Map<String, dynamic>)['points']
            as String);
  }

  /// Appelle l'API Directions. Retourne null si l'itinéraire est
  /// introuvable ou si l'API refuse la requête.
  Future<Map<String, dynamic>?> _fetch(
      LatLng origin, LatLng destination) async {
    final url = MapsConfig.directionsUrl(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    );

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('❌ Directions HTTP ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') {
        // REQUEST_DENIED = Directions API non activée sur la clé
        debugPrint('❌ Directions → $status : ${data['error_message'] ?? ''}');
        return null;
      }
      if ((data['routes'] as List<dynamic>).isEmpty) return null;
      return data;
    } catch (e) {
      debugPrint('❌ Directions → $e');
      return null;
    }
  }

  /// Décode une polyline encodée Google en liste de coordonnées.
  @visibleForTesting
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(latitude: lat / 1e5, longitude: lng / 1e5));
    }
    return points;
  }
}
