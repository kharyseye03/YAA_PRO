import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/constants.dart';
import '../providers/orders_provider.dart';

/// Articles à récupérer chez le commerçant, pour une mission
/// LIVRAISON_COMMANDE.
///
/// Replié par défaut : le coursier n'a besoin du détail qu'au comptoir,
/// au moment de vérifier ce qu'on lui remet. Le bloc disparaît
/// entièrement si l'API ne renvoie rien — mieux vaut pas de bloc qu'un
/// bloc en erreur.
class ProduitsCommandeBlock extends ConsumerStatefulWidget {
  final int commandeStructureId;

  /// Couleur d'accent de l'écran hôte.
  final Color accent;

  const ProduitsCommandeBlock({
    super.key,
    required this.commandeStructureId,
    required this.accent,
  });

  @override
  ConsumerState<ProduitsCommandeBlock> createState() =>
      _ProduitsCommandeBlockState();
}

class _ProduitsCommandeBlockState
    extends ConsumerState<ProduitsCommandeBlock> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final commande = ref
        .watch(commandeProduitsProvider(widget.commandeStructureId))
        .valueOrNull;
    if (commande == null || commande.produits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.all(AppDimens.md.r),
              child: Row(
                children: [
                  Icon(LucideIcons.shoppingBag,
                      size: 16.r, color: widget.accent),
                  SizedBox(width: AppDimens.sm.w),
                  Text(
                    commande.resumeArticles,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.dark),
                  ),
                  SizedBox(width: AppDimens.sm.w),
                  if (commande.estPrete)
                    const _Pastille(texte: 'Prête', couleur: AppColors.success)
                  else if (commande.enPreparation)
                    const _Pastille(
                        texte: 'En préparation', couleur: AppColors.warning),
                  const Spacer(),
                  Icon(
                    _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18.r,
                    color: AppColors.grey600,
                  ),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(height: 1, color: AppColors.grey300),
            Padding(
              padding: EdgeInsets.fromLTRB(AppDimens.md.w, AppDimens.sm.h,
                  AppDimens.md.w, AppDimens.md.h),
              child: Column(
                children: [
                  for (final p in commande.produits)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantité mise en avant : c'est elle qu'on
                          // vérifie au comptoir, pas le prix.
                          Container(
                            constraints: BoxConstraints(minWidth: 26.r),
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusSm),
                            ),
                            child: Text(
                              '${p.quantite}×',
                              style: AppTextStyles.caption
                                  .copyWith(color: widget.accent),
                            ),
                          ),
                          SizedBox(width: AppDimens.sm.w),
                          Expanded(
                            child: Text(
                              p.nom,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.grey800),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  final String texte;
  final Color couleur;

  const _Pastille({required this.texte, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child:
          Text(texte, style: AppTextStyles.caption.copyWith(color: couleur)),
    );
  }
}
