/// Un article de la commande passée chez le commerçant.
///
/// N'existe que pour les missions LIVRAISON_COMMANDE, et n'est pas
/// renvoyé par le détail de la mission : il faut un appel séparé sur
/// `commandeStructureId`.
class CommandeProduit {
  final int produitId;
  final String nom;
  final String? image;
  final int quantite;
  final double prixUnitaire;
  final double prixTotal;

  const CommandeProduit({
    required this.produitId,
    required this.nom,
    this.image,
    required this.quantite,
    required this.prixUnitaire,
    required this.prixTotal,
  });

  factory CommandeProduit.fromJson(Map<String, dynamic> json) {
    return CommandeProduit(
      produitId: (json['produitId'] as num?)?.toInt() ?? 0,
      nom: json['nom'] as String? ?? '',
      image: json['image'] as String?,
      quantite: (json['quantite'] as num?)?.toInt() ?? 1,
      prixUnitaire: (json['prixUnitaire'] as num?)?.toDouble() ?? 0,
      prixTotal: (json['prixTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Ce que le coursier doit récupérer chez le commerçant : les articles
/// et l'état de préparation de la commande.
class CommandeStructureDetail {
  final int id;
  final String referenceCommande;
  final double montantTotal;

  /// `EN_PREPARATION`, `PRET`, `EN_ATTENTE_LIVREUR`… Permet de savoir
  /// si la commande attend déjà au comptoir.
  final String statut;

  final List<CommandeProduit> produits;

  const CommandeStructureDetail({
    required this.id,
    required this.referenceCommande,
    required this.montantTotal,
    required this.statut,
    required this.produits,
  });

  /// « 3 articles », « 1 article »
  String get resumeArticles {
    final total = produits.fold<int>(0, (s, p) => s + p.quantite);
    return '$total article${total > 1 ? 's' : ''}';
  }

  /// La commande est prête à être retirée.
  bool get estPrete =>
      statut == 'PRET' ||
      statut == 'EN_ATTENTE_LIVREUR' ||
      statut == 'LIVREUR_ASSIGNE';

  /// Le commerçant est encore en train de préparer.
  bool get enPreparation =>
      statut == 'EN_PREPARATION' ||
      statut == 'CONFIRME' ||
      statut == 'EN_ATTENTE';

  factory CommandeStructureDetail.fromJson(Map<String, dynamic> json) {
    final produits = json['commandeProduits'];
    return CommandeStructureDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      referenceCommande: json['referenceCommande'] as String? ?? '',
      montantTotal: (json['montantTotal'] as num?)?.toDouble() ?? 0,
      statut: json['statut'] as String? ?? '',
      produits: produits is List
          ? produits
              .whereType<Map<String, dynamic>>()
              .map(CommandeProduit.fromJson)
              .toList()
          : const [],
    );
  }
}
