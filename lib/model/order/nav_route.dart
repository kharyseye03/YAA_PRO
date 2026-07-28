import 'package:google_navigation_flutter/google_navigation_flutter.dart';

/// Une manœuvre de l'itinéraire (« Tournez à droite sur la VDN »).
class RouteStep {
  final String instruction;
  final int distanceMetres;
  final int durationSeconds;

  /// Type de manœuvre renvoyé par Google (turn-right, roundabout-left…).
  final String maneuver;

  /// Point où la manœuvre se termine — sert à savoir quand passer
  /// à l'instruction suivante.
  final LatLng endLocation;

  const RouteStep({
    required this.instruction,
    required this.distanceMetres,
    required this.durationSeconds,
    required this.maneuver,
    required this.endLocation,
  });

  /// « 200 m », « 1,2 km »
  String get distanceLabel => distanceMetres < 1000
      ? '$distanceMetres m'
      : '${(distanceMetres / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final end = json['end_location'] as Map<String, dynamic>;
    return RouteStep(
      instruction:
          _stripHtml(json['html_instructions'] as String? ?? ''),
      distanceMetres:
          ((json['distance'] as Map?)?['value'] as num?)?.toInt() ?? 0,
      durationSeconds:
          ((json['duration'] as Map?)?['value'] as num?)?.toInt() ?? 0,
      maneuver: json['maneuver'] as String? ?? '',
      endLocation: LatLng(
        latitude: (end['lat'] as num).toDouble(),
        longitude: (end['lng'] as num).toDouble(),
      ),
    );
  }

  /// Google renvoie les instructions en HTML : on retire les balises
  /// et on décode les entités les plus courantes.
  static String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<div[^>]*>'), ' · ')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', '\'')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Itinéraire complet : tracé + manœuvres.
class NavRoute {
  final List<LatLng> polyline;
  final List<RouteStep> steps;
  final int distanceMetres;
  final int durationSeconds;

  const NavRoute({
    required this.polyline,
    required this.steps,
    required this.distanceMetres,
    required this.durationSeconds,
  });

  static const empty = NavRoute(
    polyline: [],
    steps: [],
    distanceMetres: 0,
    durationSeconds: 0,
  );

  bool get isEmpty => polyline.isEmpty;

  String get distanceLabel => distanceMetres < 1000
      ? '$distanceMetres m'
      : '${(distanceMetres / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60} h ${minutes % 60} min';
  }
}
