import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/api/api_config.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/type_service_ui.dart';
import '../../../model/order/mission.dart';
import '../providers/accept_mission.dart';
import '../providers/orders_provider.dart';
import 'produits_commande_block.dart';

/// Détail d'une course proposée, avant acceptation.
///
/// Feuille plutôt qu'écran : le coursier compare plusieurs courses à la
/// suite, et une feuille se referme d'un glissement sans quitter la
/// liste. Tout ce qui s'affiche vient de l'API — ni illustration, ni
/// exemple : sur une course réelle, une fausse carte ou un faux contact
/// font douter du reste.
Future<void> showOrderDetailSheet(BuildContext context, Mission order) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: AppColors.dark.withValues(alpha: 0.45),
    builder: (_) => _OrderDetailSheet(order: order),
  );
}

class _OrderDetailSheet extends ConsumerStatefulWidget {
  final Mission order;
  const _OrderDetailSheet({required this.order});

  @override
  ConsumerState<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<_OrderDetailSheet> {
  bool _accepting = false;

  Future<void> _accepter() async {
    setState(() => _accepting = true);
    final reussi = await acceptMission(context, ref, widget.order.id);
    if (!mounted) return;
    setState(() => _accepting = false);
    if (reussi) Navigator.of(context).pop();
  }

  void _refuser() {
    refuseMission(ref, widget.order.id);
    Navigator.of(context).pop();
  }

  Future<void> _appeler(String telephone) async {
    final uri = Uri.parse('tel:${telephone.replaceAll(' ', '')}');
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lancer l\'appel.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final couleurs = order.typeServiceEnum.couleurs;

    // Contacts, commerçant, produits et instructions ne figurent que
    // dans le détail de la mission : la liste ne les porte pas.
    final detail = ref.watch(missionDetailProvider(order.id));

    return Container(
      constraints: BoxConstraints(
        // Plafond bas volontairement : la feuille ne doit pas couvrir
        // tout l'écran, on doit continuer à voir la liste derrière.
        // Au-delà, le contenu défile.
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée
          Container(
            width: 38.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 12.h, bottom: AppDimens.lg.h),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                0,
                AppDimens.screenPadding.w,
                AppDimens.lg.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type de course, référence, ancienneté
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: couleurs.bg,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull),
                        ),
                        child: Text(
                          order.typeLabel,
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: couleurs.fg,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        order.code,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimens.md.h),

                  // Rémunération
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        order.montantFormate,
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dark,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Padding(
                        padding: EdgeInsets.only(bottom: 3.h),
                        child: Text(order.devise,
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.grey600)),
                      ),
                      const Spacer(),
                      Text(
                        order.ancienneteLabel,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimens.md.h),

                  Row(
                    children: [
                      _Pastille(
                        icon: LucideIcons.mapPin,
                        label: order.distanceLabel,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppDimens.sm.w),
                      _Pastille(
                        icon: LucideIcons.clock,
                        label: order.dureeLabel,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimens.xl.h),

                  _Section(
                    title: 'Itinéraire',
                    icon: LucideIcons.navigation,
                    child: _Itineraire(
                      depart: order.adresseDepart,
                      arrivee: order.adresseArrivee,
                    ),
                  ),

                  // Le reste n'existe que dans le détail : tant qu'il
                  // charge, on n'affiche pas de cadre vide.
                  detail.when(
                    loading: () => Padding(
                      padding: EdgeInsets.only(top: AppDimens.xl.h),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.primary),
                        ),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (m) => _DetailSections(
                      mission: m,
                      onCall: _appeler,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions, toujours visibles
          Container(
            padding: EdgeInsets.fromLTRB(
              AppDimens.screenPadding.w,
              AppDimens.md.h,
              AppDimens.screenPadding.w,
              MediaQuery.of(context).padding.bottom + AppDimens.md.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _accepting ? null : _refuser,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey600,
                      side: const BorderSide(color: AppColors.grey300),
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Refuser',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppDimens.sm.w),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _accepting ? null : _accepter,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    child: _accepting
                        ? SizedBox(
                            height: 20.r,
                            width: 20.r,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 18.r),
                              SizedBox(width: 6.w),
                              Text(
                                'Accepter la course',
                                style: TextStyle(
                                  fontFamily: 'Archivo',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sections issues du détail de la mission ──────────────────────
class _DetailSections extends StatelessWidget {
  final Mission mission;
  final void Function(String telephone) onCall;

  const _DetailSections({required this.mission, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final structure = mission.structure;
    final pickupNom = structure?.nom;
    final pickupTel = structure?.telephone ?? mission.telephoneExpediteur;
    final clientNom = mission.customerFullName;
    final clientTel =
        mission.telephoneDestinataire ?? mission.customerTelephone;
    final instructions = mission.instructions.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pickupNom != null || mission.commandeStructureId != null) ...[
          SizedBox(height: AppDimens.md.h),
          _Section(
            title: 'Récupérer chez',
            icon: LucideIcons.store,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pickupNom != null)
                  _Contact(
                    nom: pickupNom,
                    telephone: pickupTel,
                    logoUrl: structure?.logoFile != null
                        ? ApiConfig.getImageUrl(structure!.logoFile!)
                        : null,
                    fond: AppColors.primarySurface,
                    couleurIcone: AppColors.primary,
                    icone: Icons.storefront_rounded,
                    onCall: onCall,
                  ),
                // Ce qu'il y a à prendre au comptoir
                if (mission.commandeStructureId != null) ...[
                  if (pickupNom != null) SizedBox(height: AppDimens.md.h),
                  ProduitsCommandeBlock(
                    commandeStructureId: mission.commandeStructureId!,
                    accent: AppColors.secondary,
                  ),
                ],
              ],
            ),
          ),
        ],

        if (clientNom != null || clientTel != null) ...[
          SizedBox(height: AppDimens.md.h),
          _Section(
            title: 'Livrer à',
            icon: LucideIcons.user,
            child: _Contact(
              nom: clientNom ?? 'Client',
              telephone: clientTel,
              fond: AppColors.secondaryLight.withValues(alpha: 0.15),
              couleurIcone: AppColors.secondary,
              icone: Icons.person_rounded,
              onCall: onCall,
            ),
          ),
        ],

        if (instructions.isNotEmpty) ...[
          SizedBox(height: AppDimens.md.h),
          _Section(
            title: 'Instructions',
            icon: LucideIcons.clipboardList,
            child: Text(
              instructions,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.grey800),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Pastille distance / durée ────────────────────────────────────
class _Pastille extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Pastille(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: color),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte de section ─────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Section(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDimens.lg.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.r, color: AppColors.grey600),
              SizedBox(width: 7.w),
              Text(title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          SizedBox(height: AppDimens.md.h),
          child,
        ],
      ),
    );
  }
}

// ── Départ → arrivée ─────────────────────────────────────────────
class _Itineraire extends StatelessWidget {
  final String depart;
  final String arrivee;
  const _Itineraire({required this.depart, required this.arrivee});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            SizedBox(height: 3.h),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 18.r,
                  height: 18.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5),
                  ),
                ),
                Container(
                  width: 9.r,
                  height: 9.r,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Container(width: 1.5, height: 32.h, color: AppColors.grey200),
            Icon(LucideIcons.mapPin, color: AppColors.secondary, size: 18.r),
          ],
        ),
        SizedBox(width: AppDimens.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Départ',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.grey500)),
              SizedBox(height: 1.h),
              Text(depart,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.dark)),
              SizedBox(height: 16.h),
              Text('Arrivée',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.grey500)),
              SizedBox(height: 1.h),
              Text(arrivee,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.dark)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Contact appelable ────────────────────────────────────────────
class _Contact extends StatelessWidget {
  final String nom;
  final String? telephone;
  final String? logoUrl;
  final Color fond;
  final Color couleurIcone;
  final IconData icone;
  final void Function(String telephone) onCall;

  const _Contact({
    required this.nom,
    required this.telephone,
    required this.fond,
    required this.couleurIcone,
    required this.icone,
    required this.onCall,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final tel = telephone?.trim();
    final appelable = tel != null && tel.isNotEmpty;

    return Row(
      children: [
        Container(
          width: 42.r,
          height: 42.r,
          decoration: BoxDecoration(
            color: fond,
            shape: BoxShape.circle,
            image: logoUrl != null
                ? DecorationImage(
                    image: NetworkImage(logoUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: logoUrl != null
              ? null
              : Icon(icone, color: couleurIcone, size: 22.r),
        ),
        SizedBox(width: AppDimens.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nom,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.dark)),
              if (appelable) ...[
                SizedBox(height: 2.h),
                Text(tel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey700)),
              ],
            ],
          ),
        ),
        if (appelable)
          GestureDetector(
            onTap: () => onCall(tel),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38.r,
              height: 38.r,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_rounded,
                  color: AppColors.success, size: 18.r),
            ),
          ),
      ],
    );
  }
}
