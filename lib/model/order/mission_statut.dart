/// Statuts d'une course ou d'une livraison, tels que définis par le
/// backend (`StatutCourseLivraison`).
///
/// Centralisé ici pour éviter de comparer des chaînes de caractères
/// un peu partout dans l'app.
enum MissionStatut {
  rechercheCoursier('RECHERCHE_COURSIER'),
  coursierAssigne('COURSIER_ASSIGNE'),
  coursierEnRouteVersDepart('COURSIER_EN_ROUTE_VERS_DEPART'),
  coursierArriveAuDepart('COURSIER_ARRIVE_AU_DEPART'),
  priseEnChargeEffectuee('PRISE_EN_CHARGE_EFFECTUEE'),
  courseEnCours('COURSE_EN_COURS'),
  courseTerminee('COURSE_TERMINEE'),
  annule('ANNULE'),

  /// Valeur absente ou inconnue de l'app (nouveau statut backend).
  inconnu('');

  final String value;
  const MissionStatut(this.value);

  static MissionStatut from(String? raw) {
    final v = raw?.toUpperCase().trim();
    return values.firstWhere(
      (s) => s.value == v,
      orElse: () => inconnu,
    );
  }

  /// La mission attend encore un coursier.
  bool get isAvailable => this == rechercheCoursier;

  /// Le colis est récupéré : le livreur roule vers la livraison
  /// (étape 2 du parcours).
  bool get isPickedUp =>
      this == priseEnChargeEffectuee || this == courseEnCours;

  /// Plus rien à faire : la mission est livrée ou annulée.
  bool get isFinished => this == courseTerminee || this == annule;

  /// Une mission est en cours pour le livreur connecté.
  bool get isActive => !isAvailable && !isFinished && this != inconnu;

  /// Libellé affichable.
  String get label => switch (this) {
        rechercheCoursier => 'En recherche de coursier',
        coursierAssigne => 'Coursier assigné',
        coursierEnRouteVersDepart => 'En route vers le départ',
        coursierArriveAuDepart => 'Arrivé au point de départ',
        priseEnChargeEffectuee => 'Colis récupéré',
        courseEnCours => 'Course en cours',
        courseTerminee => 'Terminée',
        annule => 'Annulée',
        inconnu => '',
      };
}
