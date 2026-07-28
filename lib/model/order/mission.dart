import 'mission_statut.dart';

/// Mission disponible pour un coursier (livraison ou course).
class Mission {
  final int id;
  final String code;
  final String typeService; // LIVRAISON | COURSE
  final String typeVehicule;
  final String statut;
  final int? clientId;
  final double? latitudeDepart;
  final double? longitudeDepart;
  final double? latitudeArrivee;
  final double? longitudeArrivee;
  final String adresseDepart;
  final String adresseArrivee;
  final double distanceKm;
  final int dureeMinutes;
  final double montant;
  final String devise;
  final String instructions;
  final DateTime? dateCreationMission;

  // ── Champs présents uniquement sur le détail d'une mission ──
  final String? customerFullName;
  final String? customerTelephone;
  /// LIVRAISON uniquement : contact au point de départ.
  final String? telephoneExpediteur;
  /// LIVRAISON uniquement : contact au point d'arrivée.
  final String? telephoneDestinataire;

  const Mission({
    required this.id,
    required this.code,
    required this.typeService,
    required this.typeVehicule,
    required this.statut,
    this.clientId,
    this.latitudeDepart,
    this.longitudeDepart,
    this.latitudeArrivee,
    this.longitudeArrivee,
    required this.adresseDepart,
    required this.adresseArrivee,
    required this.distanceKm,
    required this.dureeMinutes,
    required this.montant,
    required this.devise,
    required this.instructions,
    this.dateCreationMission,
    this.customerFullName,
    this.customerTelephone,
    this.telephoneExpediteur,
    this.telephoneDestinataire,
  });

  bool get isLivraison => typeService.toUpperCase() == 'LIVRAISON';

  MissionStatut get statutEnum => MissionStatut.from(statut);

  /// True une fois le colis récupéré : le livreur roule alors vers
  /// le point de livraison (étape 2).
  bool get isPickedUp => statutEnum.isPickedUp;

  /// La mission est livrée ou annulée : il n'y a plus rien à faire.
  bool get isFinished => statutEnum.isFinished;

  /// Adresse de l'étape en cours.
  String get currentAddress => isPickedUp ? adresseArrivee : adresseDepart;

  /// Coordonnées de l'étape en cours.
  double? get currentLatitude => isPickedUp ? latitudeArrivee : latitudeDepart;
  double? get currentLongitude =>
      isPickedUp ? longitudeArrivee : longitudeDepart;

  /// Montant formaté avec séparateur de milliers : 2000.0 → « 2 000 »
  String get montantFormate {
    final entier = montant.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < entier.length; i++) {
      if (i > 0 && (entier.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(entier[i]);
    }
    return buffer.toString();
  }

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';

  String get dureeLabel => '$dureeMinutes min';

  /// Libellé du type de service : « Livraison » / « Course »
  String get typeLabel => typeService.isEmpty
      ? ''
      : typeService[0].toUpperCase() +
          typeService.substring(1).toLowerCase();

  /// Ancienneté de la mission : « à l'instant », « 5 min », « 2 h »
  String get ancienneteLabel {
    if (dateCreationMission == null) return '';
    final diff = DateTime.now().difference(dateCreationMission!);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} j';
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      typeService: json['typeService'] as String? ?? '',
      typeVehicule: json['typeVehicule'] as String? ?? '',
      statut: json['statut'] as String? ?? '',
      clientId: json['clientId'] as int?,
      latitudeDepart: (json['latitudeDepart'] as num?)?.toDouble(),
      longitudeDepart: (json['longitudeDepart'] as num?)?.toDouble(),
      latitudeArrivee: (json['latitudeArrivee'] as num?)?.toDouble(),
      longitudeArrivee: (json['longitudeArrivee'] as num?)?.toDouble(),
      adresseDepart: json['adresseDepart'] as String? ?? '',
      adresseArrivee: json['adresseArrivee'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      dureeMinutes: (json['dureeMinutes'] as num?)?.toInt() ?? 0,
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      devise: json['devise'] as String? ?? 'FCFA',
      instructions: json['instructions'] as String? ?? '',
      dateCreationMission: json['dateCreationMission'] != null
          ? DateTime.tryParse(json['dateCreationMission'] as String)
          : null,
      customerFullName: json['customerFullName'] as String?,
      customerTelephone: json['customerTelephone'] as String?,
      telephoneExpediteur: json['telephoneExpediteur'] as String?,
      telephoneDestinataire: json['telephoneDestinataire'] as String?,
    );
  }
}
