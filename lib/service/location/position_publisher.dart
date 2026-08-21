import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../api/api_service.dart';

/// Publie la position du livreur vers le backend pendant une mission.
///
/// Le flux GPS n'émet que tous les 5 mètres parcourus : il se tait
/// complètement quand le livreur est à l'arrêt. C'est pourquoi
/// l'envoi n'est pas piloté par le flux mais par une horloge — le flux
/// se contente de tenir à jour la dernière position connue.
///
/// Sans ça, un livreur arrêté à un feu rouge ou en attente au comptoir
/// d'un restaurant cesserait d'émettre, et le client le croirait
/// déconnecté.
///
/// Trois règles décident à chaque battement :
/// - jamais plus d'un envoi toutes les [intervalleMin] ;
/// - dans cette limite, on envoie dès [distanceMinMetres] parcourus,
///   pour suivre finement celui qui roule ;
/// - à l'arrêt, un envoi toutes les [battementCoeur] pour signaler que
///   le livreur est toujours là.
class PositionPublisher {
  /// Délai plancher entre deux envois, et cadence de l'horloge.
  static const Duration intervalleMin = Duration(seconds: 15);

  /// Déplacement à partir duquel une nouvelle position vaut un envoi.
  static const double distanceMinMetres = 30;

  /// Envoi périodique même immobile.
  static const Duration battementCoeur = Duration(seconds: 60);

  final ApiService _api;

  /// Libellé « Quartier, Ville » de la dernière position connue.
  /// Fourni par l'appelant : le recalculer à chaque envoi coûterait un
  /// géocodage inverse toutes les quinze secondes pour un champ que
  /// personne ne regarde bouger.
  final String Function() _adresse;

  Timer? _horloge;
  Position? _dernierePositionConnue;
  Position? _dernierePositionEnvoyee;
  DateTime? _dernierEnvoi;

  /// Envoi en cours : sur une connexion lente, une requête peut durer
  /// plus longtemps que l'intervalle. Sans ce garde-fou les appels
  /// s'empileraient et arriveraient dans le désordre.
  bool _enVol = false;

  PositionPublisher(this._api, {String Function()? adresse})
      : _adresse = adresse ?? (() => '');

  /// Démarre l'horloge. Sans appel à [demarrer], rien n'est publié.
  void demarrer() {
    _horloge?.cancel();
    _horloge = Timer.periodic(intervalleMin, (_) => _evaluer());
    debugPrint('📍 Horloge de publication démarrée '
        '(${intervalleMin.inSeconds}s)');
  }

  /// Arrête tout et oublie l'historique de la mission écoulée.
  void arreter() {
    _horloge?.cancel();
    _horloge = null;
    _dernierePositionConnue = null;
    _dernierePositionEnvoyee = null;
    _dernierEnvoi = null;
    debugPrint('📍 Horloge de publication arrêtée');
  }

  /// À appeler pour chaque position émise par le GPS.
  ///
  /// N'envoie rien par elle-même, sauf pour la toute première position
  /// de la mission : c'est celle qui fait apparaître le livreur sur la
  /// carte du client, elle ne doit pas attendre le premier battement.
  void onPosition(Position position) {
    _dernierePositionConnue = position;
    if (_dernierEnvoi == null) _evaluer();
  }

  Future<void> _evaluer() async {
    final position = _dernierePositionConnue;
    if (position == null || _enVol || !_doitEnvoyer(position)) return;

    _enVol = true;
    _dernierEnvoi = DateTime.now();
    _dernierePositionEnvoyee = position;
    try {
      await _api.updateDriverPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        adresse: _adresse(),
      );
    } finally {
      _enVol = false;
    }
  }

  bool _doitEnvoyer(Position position) {
    final precedente = _dernierePositionEnvoyee;
    final dernier = _dernierEnvoi;
    if (precedente == null || dernier == null) return true;

    final ecoule = DateTime.now().difference(dernier);
    if (ecoule < intervalleMin) return false;
    if (ecoule >= battementCoeur) return true;

    final metres = Geolocator.distanceBetween(
      precedente.latitude,
      precedente.longitude,
      position.latitude,
      position.longitude,
    );
    return metres >= distanceMinMetres;
  }
}
