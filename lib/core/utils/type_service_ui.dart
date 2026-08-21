import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../model/order/type_service.dart';
import '../constants/app_colors.dart';

/// Habillage visuel d'un type de prestation : couleurs et icône.
///
/// Vit ici plutôt que dans [TypeService] pour garder le modèle libre
/// de toute dépendance à Flutter — mais reste l'unique source de
/// vérité côté affichage. Chaque écran qui montre un badge de type
/// passe par cette extension, jamais par une comparaison de chaînes.
extension TypeServiceUi on TypeService {
  /// Fond clair et couleur de contenu (texte ou icône) assortis.
  ({Color bg, Color fg}) get couleurs => switch (this) {
        TypeService.livraison => (
            bg: AppColors.catRestaurantLight,
            fg: AppColors.catRestaurant,
          ),
        TypeService.course => (
            bg: AppColors.infoLight,
            fg: AppColors.info,
          ),
        TypeService.livraisonCommande => (
            bg: AppColors.catBoutiqueLight,
            fg: AppColors.catBoutique,
          ),
        TypeService.inconnu => (
            bg: AppColors.primarySurface,
            fg: AppColors.primary,
          ),
      };

  IconData get icone => switch (this) {
        TypeService.livraison => LucideIcons.package,
        TypeService.course => LucideIcons.userCheck,
        TypeService.livraisonCommande => LucideIcons.shoppingBag,
        TypeService.inconnu => LucideIcons.mapPin,
      };
}
