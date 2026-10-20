import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../../config/api/api_config.dart';
import '../../model/driver/driver_detail.dart';
import '../auth/providers/auth_notifier.dart';
import '../auth/providers/driver_provider.dart';
import '../orders/providers/refused_missions_provider.dart';
import '../shell/main_shell.dart';

/// Profil du coursier.
///
/// Les lignes sont groupées en cartes posées sur un fond gris, plutôt
/// qu'alignées à plat séparées par des filets. La liste précédente
/// mélangeait des filets pleine largeur et d'autres indentés, ce qui
/// suggérait des groupes sans jamais dire lesquels.
///
/// Chaque ligne porte la **valeur du moment** en sous-titre — « Mame
/// Khary · 622 12 34 56 », « Yamaha · AB-123-CD » — pour renseigner
/// sans qu'on ait à l'ouvrir.
///
/// Même structure que le profil de l'application client, moins la
/// carte de recrutement qui n'a pas de sens ici.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Bloque un second appui pendant l'appel de suppression.

  /// « 622123456 » → « 622 12 34 56 »
  static String _formatPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    final local = d.length > 9 ? d.substring(d.length - 9) : d;
    if (local.length != 9) return raw;
    return '${local.substring(0, 3)} ${local.substring(3, 5)} '
        '${local.substring(5, 7)} ${local.substring(7)}';
  }

  /// Ouvre un lien externe sans jamais laisser l'appui sans effet.
  ///
  /// Sur Android 11+, `canLaunchUrl` renvoie false pour un schéma que
  /// le manifeste ne déclare pas — le bouton semble alors cassé. Si
  /// l'appareil n'a aucune application pour l'ouvrir, on le dit au
  /// lieu de ne rien faire.
  Future<void> _ouvrir(Uri uri, String siImpossible) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(siImpossible)),
    );
  }

  /// Feuille de choix du canal de contact.
  ///
  /// Le coursier ouvre « Support » sans savoir encore s'il préfère
  /// appeler ou écrire — c'est ici qu'il tranche, plutôt que devant
  /// deux lignes qui se ressemblent dans la liste.
  Future<void> _ouvrirSupport() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (feuille) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(feuille).padding.bottom + AppDimens.lg.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: AppDimens.md.h),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppDimens.md.w, 0,
                  AppDimens.md.w, AppDimens.sm.h),
              child: Row(
                children: [
                  Text('Contacter le support',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.dark)),
                ],
              ),
            ),
            _Ligne(
              icon: Icons.phone_outlined,
              label: 'Appeler',
              subtitle: AppContacts.telephoneSupport,
              onTap: () {
                Navigator.of(feuille).pop();
                _ouvrir(
                  Uri(scheme: 'tel', path: AppContacts.telephoneSupport),
                  'Aucune application téléphone',
                );
              },
            ),
            _Ligne(
              icon: Icons.mail_outline_rounded,
              label: 'Écrire',
              subtitle: AppContacts.emailSupport,
              onTap: () {
                Navigator.of(feuille).pop();
                _ouvrir(
                  Uri(scheme: 'mailto', path: AppContacts.emailSupport),
                  'Aucune application e-mail',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Se déconnecter',
          style:
              AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Se déconnecter',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    await ref.read(refusedMissionsProvider.notifier).clear();
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    ref.read(shellIndexProvider.notifier).state = 0;
    context.goNamed(RouteNames.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final driver = ref.watch(driverDetailProvider).valueOrNull;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: top + AppDimens.xl.h),

            _EnTete(driver: driver),

            SizedBox(height: AppDimens.xl.h),

            // ── Compte ────────────────────────────────────
            _Carte(children: [
              _Ligne(
                icon: Icons.person_outline_rounded,
                label: 'Informations personnelles',
                // Nom et numéro rendent la ligne utile sans avoir à
                // l'ouvrir.
                subtitle: [
                  driver?.fullName,
                  driver == null ? null : _formatPhone(driver.telephone),
                ].where((e) => e != null && e.isNotEmpty).join(' · '),
                onTap: () => context.pushNamed(RouteNames.personalInfo),
              ),
              _Ligne(
                icon: Icons.two_wheeler_rounded,
                label: 'Mon véhicule',
                subtitle: driver?.vehiculeInfo?.resume ?? 'Non renseigné',
                onTap: () => context.pushNamed(RouteNames.vehicle),
              ),
              _Ligne(
                icon: Icons.receipt_long_outlined,
                label: 'Historique des courses',
                subtitle: 'Vos courses terminées',
                onTap: () => context.pushNamed(RouteNames.history),
              ),
            ]),

            SizedBox(height: AppDimens.lg.h),

            // ── Aide ──────────────────────────────────────
            // Une seule ligne plutôt que deux : le coursier veut
            // « joindre le support », le canal se choisit ensuite.
            _Carte(children: [
              _Ligne(
                icon: Icons.headset_mic_outlined,
                label: 'Support',
                subtitle: 'Une question, un problème ?',
                onTap: _ouvrirSupport,
              ),
            ]),

            SizedBox(height: AppDimens.xl.h),

            // ── Déconnexion ───────────────────────────────
            // En rouge et pleine largeur : c'est une action qu'on
            // cherche, elle ne doit pas se confondre avec le pied de
            // page.
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: AppDimens.screenPadding.w),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: Icon(Icons.logout_rounded,
                      size: 18.r, color: AppColors.error),
                  label: Text(
                    'Se déconnecter',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50.h),
                    backgroundColor: AppColors.errorLight,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusLg),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: AppDimens.sm.h),

            // La suppression du compte vit dans « Informations
            // personnelles » : c'est là qu'on gère son identité, et
            // elle n'a pas à côtoyer la déconnexion, bien plus
            // fréquente et anodine.

            SizedBox(height: AppDimens.sm.h),

            Text(
              'YAA PRO · version 1.0.0',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
            ),

            // Barre de navigation flottante + barre système
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 16.h),
          ],
        ),
      ),
    );
  }
}

// ── En-tête : avatar, nom, note ───────────────────────────────
class _EnTete extends StatelessWidget {
  const _EnTete({required this.driver});
  final DriverDetail? driver;

  @override
  Widget build(BuildContext context) {
    final imageUrl = driver?.imageFileName != null
        ? ApiConfig.getImageUrl(driver!.imageFileName!)
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDimens.screenPadding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de page plutôt qu'un avatar centré : l'écran sert
          // surtout à ouvrir les rubriques en dessous.
          Text(
            'Mon espace',
            style: AppTextStyles.h2.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Gérez vos informations et vos préférences.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
          ),
          SizedBox(height: AppDimens.xl.h),

          Row(
            children: [
              Container(
                width: 68.r,
                height: 68.r,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey200, width: 2),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Icon(Icons.person_rounded,
                        color: AppColors.grey400, size: 34.r)
                    : null,
              ),
              SizedBox(width: AppDimens.lg.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver?.fullName ?? '—',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      driver?.email ?? '—',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.grey500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    _Note(driver: driver),
                  ],
                ),
              ),
              SizedBox(width: AppDimens.sm.w),
              // Modifier la photo et les informations
              GestureDetector(
                onTap: () => context.pushNamed(RouteNames.editPersonalInfo),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded,
                      color: AppColors.primary, size: 18.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Note du coursier ──────────────────────────────────────────
class _Note extends StatelessWidget {
  const _Note({required this.driver});
  final DriverDetail? driver;

  @override
  Widget build(BuildContext context) {
    return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded,
                color: driver?.estNote == true
                    ? const Color(0xFFF4C430)
                    : AppColors.grey300,
                size: 16.r),
            SizedBox(width: 4.w),
            if (driver?.estNote == true) ...[
              Text(
                driver!.notation!.toStringAsFixed(1),
                style:
                    AppTextStyles.labelSmall.copyWith(color: AppColors.dark),
              ),
              SizedBox(width: 4.w),
              Text(
                '(${driver!.nombreNotations} avis)',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.grey600),
              ),
            ] else
              Text(
                'Pas encore noté',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.grey600),
              ),
      ],
    );
  }
}

// ── Carte groupée ─────────────────────────────────────────────
class _Carte extends StatelessWidget {
  const _Carte({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimens.screenPadding.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: EdgeInsets.only(left: 52.w),
                child: const Divider(height: 1, color: AppColors.grey100),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Ligne de carte ────────────────────────────────────────────
class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sousTitre = subtitle;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(AppDimens.md.r),
        child: Row(
          children: [
            Icon(icon, size: 20.r, color: AppColors.grey600),
            SizedBox(width: AppDimens.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                  if (sousTitre != null && sousTitre.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      sousTitre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18.r, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}
