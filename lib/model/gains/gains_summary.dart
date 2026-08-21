import '../order/mission_statut.dart';
import '../order/type_service.dart';

/// Une mission terminée qui a rapporté au livreur.
class MissionGain {
  final int id;
  final String reference;
  final String typeService;
  final String statut;
  final String adresseDepart;
  final String adresseArrivee;
  final String heure;
  final double gain;
  final String devise;
  final DateTime? dateMission;
  final DateTime? dateHeureMission;

  const MissionGain({
    required this.id,
    required this.reference,
    required this.typeService,
    required this.statut,
    required this.adresseDepart,
    required this.adresseArrivee,
    required this.heure,
    required this.gain,
    required this.devise,
    this.dateMission,
    this.dateHeureMission,
  });

  TypeService get typeServiceEnum => TypeService.from(typeService);
  MissionStatut get statutEnum => MissionStatut.from(statut);

  /// Transport d'un objet, par opposition au transport d'une personne.
  bool get isLivraison => !typeServiceEnum.transportePersonne;

  /// « Livraison », « Course », « Commande » — via le mapping partagé,
  /// et non par une mise en forme de la valeur brute : « Commande »
  /// n'a rien à voir avec « Livraison_commande ».
  String get typeLabel => typeServiceEnum.label;

  String get gainFormate => formatMontant(gain);

  factory MissionGain.fromJson(Map<String, dynamic> json) {
    return MissionGain(
      id: json['id'] as int,
      reference: json['reference'] as String? ?? '',
      typeService: json['typeService'] as String? ?? '',
      statut: json['statut'] as String? ?? '',
      adresseDepart: json['adresseDepart'] as String? ?? '',
      adresseArrivee: json['adresseArrivee'] as String? ?? '',
      heure: json['heure'] as String? ?? '',
      gain: (json['gain'] as num?)?.toDouble() ?? 0,
      devise: json['devise'] as String? ?? 'GNF',
      dateMission: json['dateMission'] != null
          ? DateTime.tryParse(json['dateMission'] as String)
          : null,
      dateHeureMission: json['dateHeureMission'] != null
          ? DateTime.tryParse(json['dateHeureMission'] as String)
          : null,
    );
  }
}

/// Récapitulatif des gains du livreur et des missions associées.
class GainsSummary {
  final double gainsAujourdhui;
  final double totalGain;
  final String devise;
  final int nombreMissions;
  final List<MissionGain> missions;

  const GainsSummary({
    required this.gainsAujourdhui,
    required this.totalGain,
    required this.devise,
    required this.nombreMissions,
    required this.missions,
  });

  static const empty = GainsSummary(
    gainsAujourdhui: 0,
    totalGain: 0,
    devise: 'GNF',
    nombreMissions: 0,
    missions: [],
  );

  String get totalFormate => formatMontant(totalGain);
  String get aujourdhuiFormate => formatMontant(gainsAujourdhui);

  factory GainsSummary.fromJson(Map<String, dynamic> json) {
    return GainsSummary(
      gainsAujourdhui: (json['gainsAujourdhui'] as num?)?.toDouble() ?? 0,
      totalGain: (json['totalGain'] as num?)?.toDouble() ?? 0,
      devise: json['devise'] as String? ?? 'GNF',
      nombreMissions: (json['nombreMissions'] as num?)?.toInt() ?? 0,
      missions: (json['missions'] as List<dynamic>? ?? [])
          .map((e) => MissionGain.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 2000.0 → « 2 000 »
String formatMontant(double montant) {
  final entier = montant.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < entier.length; i++) {
    if (i > 0 && (entier.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(entier[i]);
  }
  return buffer.toString();
}
