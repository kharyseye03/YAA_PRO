import '../gains/gains_summary.dart' show formatMontant;
import 'mission_statut.dart';
import 'type_service.dart';

/// Une mission de l'historique du livreur, avec le détail de sa
/// rémunération.
class HistoryMission {
  final int id;
  final String reference;
  final String typeService;
  final String typeVehicule;
  final String client;
  final String adresseDepart;
  final String adresseArrivee;
  final double distanceMetres;
  final int dureeSecondes;

  /// Prix payé par le client.
  final double frais;

  /// Part prélevée par YAA.
  final double commissionYaa;

  /// Ce que le livreur touche réellement.
  final double gainLivreur;
  final double bonus;

  final String devise;
  final String statut;
  final DateTime? date;
  final String instructions;

  const HistoryMission({
    required this.id,
    required this.reference,
    required this.typeService,
    required this.typeVehicule,
    required this.client,
    required this.adresseDepart,
    required this.adresseArrivee,
    required this.distanceMetres,
    required this.dureeSecondes,
    required this.frais,
    required this.commissionYaa,
    required this.gainLivreur,
    required this.bonus,
    required this.devise,
    required this.statut,
    this.date,
    this.instructions = '',
  });

  TypeService get typeServiceEnum => TypeService.from(typeService);
  MissionStatut get statutEnum => MissionStatut.from(statut);

  String get typeLabel => typeServiceEnum.label;

  /// « 4.99 km »
  String get distanceLabel =>
      '${(distanceMetres / 1000).toStringAsFixed(2)} km';

  /// « 14 min »
  String get dureeLabel => '${(dureeSecondes / 60).round()} min';

  /// « 14h32 »
  String get heureLabel {
    final d = date;
    if (d == null) return '';
    return '${d.hour}h${d.minute.toString().padLeft(2, '0')}';
  }

  String get gainFormate => formatMontant(gainLivreur);
  String get fraisFormate => formatMontant(frais);
  String get commissionFormate => formatMontant(commissionYaa);
  String get bonusFormate => formatMontant(bonus);

  factory HistoryMission.fromJson(Map<String, dynamic> json) {
    return HistoryMission(
      id: json['id'] as int,
      reference: json['reference'] as String? ?? '',
      typeService: json['typeService'] as String? ?? '',
      typeVehicule: json['typeVehicule'] as String? ?? '',
      client: json['client'] as String? ?? '',
      adresseDepart: json['adresseDepart'] as String? ?? '',
      adresseArrivee: json['adresseArrivee'] as String? ?? '',
      distanceMetres: (json['distanceMetres'] as num?)?.toDouble() ?? 0,
      dureeSecondes: (json['dureeSecondes'] as num?)?.toInt() ?? 0,
      frais: (json['frais'] as num?)?.toDouble() ?? 0,
      commissionYaa: (json['commissionYaa'] as num?)?.toDouble() ?? 0,
      gainLivreur: (json['gainLivreur'] as num?)?.toDouble() ?? 0,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
      devise: json['devise'] as String? ?? 'GNF',
      statut: json['statut'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      instructions: json['instructions'] as String? ?? '',
    );
  }
}
