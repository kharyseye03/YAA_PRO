/// Types de prestation proposés au coursier, tels que définis par le
/// backend (`TypeServiceTarification`).
enum TypeService {
  /// Colis d'un particulier à un autre.
  livraison('LIVRAISON'),

  /// Transport d'une personne : le coursier prend le client au départ
  /// et le dépose à l'arrivée.
  course('COURSE'),

  /// Commande passée chez un commerçant, à récupérer sur place puis à
  /// livrer au client.
  livraisonCommande('LIVRAISON_COMMANDE'),

  /// Valeur absente ou inconnue de l'app.
  inconnu('');

  final String value;
  const TypeService(this.value);

  static TypeService from(String? raw) {
    final v = raw?.toUpperCase().trim();
    return values.firstWhere((t) => t.value == v, orElse: () => inconnu);
  }

  /// Le coursier transporte une personne et non un objet.
  bool get transportePersonne => this == course;

  /// Libellé court affiché sur les badges.
  String get label => switch (this) {
        livraison => 'Livraison',
        course => 'Course',
        livraisonCommande => 'Commande',
        inconnu => '',
      };
}
