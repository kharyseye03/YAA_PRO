class CommandeLivraison {
  final int id;
  final String structureName;
  final String structureAdresse;
  final String structureTelephone;
  final String referenceCommande;
  final String description;
  final String adresseLivraison;
  final String telephoneClient;
  final double? latitude;
  final double? longitude;
  final String modeLivraison;
  final DateTime? createdDate;
  final String? statutCommande;

  const CommandeLivraison({
    required this.id,
    required this.structureName,
    required this.structureAdresse,
    required this.structureTelephone,
    required this.referenceCommande,
    required this.description,
    required this.adresseLivraison,
    required this.telephoneClient,
    this.latitude,
    this.longitude,
    required this.modeLivraison,
    this.createdDate,
    this.statutCommande,
  });

  /// Référence courte affichable (8 premiers caractères).
  String get shortRef =>
      referenceCommande.length >= 8
          ? referenceCommande.substring(0, 8).toUpperCase()
          : referenceCommande.toUpperCase();

  factory CommandeLivraison.fromJson(Map<String, dynamic> json) {
    return CommandeLivraison(
      id: json['id'] as int,
      structureName: json['structureName'] as String? ?? '',
      structureAdresse: json['structureAdresse'] as String? ?? '',
      structureTelephone: json['structureTelephone'] as String? ?? '',
      referenceCommande: json['referenceCommande'] as String? ?? '',
      description: json['description'] as String? ?? '',
      adresseLivraison: json['adresseLivraison'] as String? ?? '',
      telephoneClient: json['telephoneClient'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      modeLivraison: json['modeLivraison'] as String? ?? '',
      createdDate: json['createdDate'] != null
          ? DateTime.tryParse(json['createdDate'] as String)
          : null,
      statutCommande: json['statutCommande'] as String?,
    );
  }
}
