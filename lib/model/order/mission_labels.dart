import 'mission.dart';
import 'type_service.dart';

/// Textes affichés pendant une mission, adaptés au type de service et
/// à l'étape en cours.
///
/// Un coursier qui transporte une personne ne « récupère pas un
/// colis » : tout le vocabulaire de l'écran passe par ici pour rester
/// juste dans les trois cas de figure.
class MissionLabels {
  /// « Étape 1 sur 2 · Récupération »
  final String stepBadge;

  /// Libellé de l'adresse de l'étape : « Récupérer à », « Déposer à »…
  final String addressLabel;

  /// Texte du bouton d'action de l'étape.
  final String actionButton;

  /// Titre du bloc contact : « Expéditeur », « Client »…
  final String contactLabel;

  /// Message affiché quand le SDK détecte l'arrivée.
  final String arrivalMessage;

  const MissionLabels({
    required this.stepBadge,
    required this.addressLabel,
    required this.actionButton,
    required this.contactLabel,
    required this.arrivalMessage,
  });

  factory MissionLabels.of(Mission mission) {
    final type = mission.typeServiceEnum;
    final step2 = mission.isPickedUp;

    return switch (type) {
      // ── Transport d'une personne ──────────────────────────
      TypeService.course => step2
          ? const MissionLabels(
              stepBadge: 'Étape 2 sur 2 · Dépose',
              addressLabel: 'Déposer à',
              actionButton: 'Client déposé',
              contactLabel: 'Client',
              arrivalMessage: 'Vous êtes arrivé à destination',
            )
          : const MissionLabels(
              stepBadge: 'Étape 1 sur 2 · Prise en charge',
              addressLabel: 'Prendre le client à',
              actionButton: 'Client à bord',
              contactLabel: 'Client',
              arrivalMessage: 'Vous êtes arrivé chez le client',
            ),

      // ── Commande chez un commerçant ───────────────────────
      TypeService.livraisonCommande => step2
          ? const MissionLabels(
              stepBadge: 'Étape 2 sur 2 · Livraison',
              addressLabel: 'Livrer à',
              actionButton: 'J\'ai livré la commande',
              contactLabel: 'Client',
              arrivalMessage: 'Vous êtes arrivé chez le client',
            )
          : const MissionLabels(
              stepBadge: 'Étape 1 sur 2 · Récupération',
              addressLabel: 'Récupérer chez',
              actionButton: 'J\'ai récupéré la commande',
              contactLabel: 'Commerçant',
              arrivalMessage: 'Vous êtes arrivé chez le commerçant',
            ),

      // ── Colis entre particuliers ──────────────────────────
      _ => step2
          ? const MissionLabels(
              stepBadge: 'Étape 2 sur 2 · Livraison',
              addressLabel: 'Livrer à',
              actionButton: 'J\'ai livré le colis',
              contactLabel: 'Destinataire',
              arrivalMessage: 'Vous êtes arrivé chez le destinataire',
            )
          : const MissionLabels(
              stepBadge: 'Étape 1 sur 2 · Récupération',
              addressLabel: 'Récupérer à',
              actionButton: 'J\'ai récupéré le colis',
              contactLabel: 'Expéditeur',
              arrivalMessage:
                  'Vous êtes arrivé au point de récupération',
            ),
    };
  }

  /// Numéro à appeler à l'étape en cours.
  static String? contactPhoneOf(Mission mission) {
    // Pour une course, le client est le seul interlocuteur
    if (mission.typeServiceEnum.transportePersonne) {
      return mission.customerTelephone;
    }
    return mission.isPickedUp
        ? mission.telephoneDestinataire ?? mission.customerTelephone
        : mission.telephoneExpediteur ?? mission.customerTelephone;
  }

  /// Nom à afficher à l'étape en cours, quand il est connu.
  static String? contactNameOf(Mission mission) {
    if (mission.typeServiceEnum.transportePersonne) {
      return mission.customerFullName;
    }
    // Le destinataire n'a pas de nom dans la réponse API
    return mission.isPickedUp ? null : mission.customerFullName;
  }
}
