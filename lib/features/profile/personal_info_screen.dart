import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../config/api/api_config.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../auth/providers/auth_notifier.dart';
import '../auth/providers/driver_provider.dart';
import '../orders/providers/refused_missions_provider.dart';
import '../shell/main_shell.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() =>
      _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  bool _suppressionEnCours = false;

  /// Suppression définitive du compte.
  ///
  /// Exigée par Google Play pour toute application permettant de créer
  /// un compte. La confirmation est volontairement plus lourde que
  /// celle de la déconnexion : c'est irréversible, et un appui par
  /// erreur ferait perdre au coursier son historique et ses gains.
  Future<void> _supprimerCompte(int driverId) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Supprimer votre compte ?',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Text(
          'Cette action est définitive. Votre profil, votre véhicule et '
          'l\'historique de vos courses seront supprimés, et vous ne '
          'pourrez plus vous connecter avec ce numéro.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey700),
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
              'Supprimer définitivement',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    setState(() => _suppressionEnCours = true);
    try {
      await ref.read(apiServiceProvider).deleteAccount(driverId);
      if (!mounted) return;
      // Le compte n'existe plus : on nettoie l'état local exactement
      // comme à la déconnexion, sinon l'app rouvrirait sur des données
      // d'un compte effacé.
      await ref.read(refusedMissionsProvider.notifier).clear();
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      ref.read(shellIndexProvider.notifier).state = 0;
      context.goNamed(RouteNames.onboarding);
    } catch (e) {
      if (!mounted) return;
      setState(() => _suppressionEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(driverDetailProvider).valueOrNull;
    final imageUrl = driver?.imageFileName != null
        ? ApiConfig.getImageUrl(driver!.imageFileName!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12.h,
              left: AppDimens.screenPadding.w,
              right: AppDimens.screenPadding.w,
              bottom: 16.h,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  // Sans fond : la flèche se suffit, et le carré gris
                  // alourdissait l'en-tête.
                  child: SizedBox(
                    width: 38.r,
                    height: 38.r,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.dark,
                      size: 22.r,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Informations personnelles',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.grey200),

          // ── Contenu ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding.w,
              ),
              child: Column(
                children: [
                  SizedBox(height: 28.h),

                  // Avatar
                  Container(
                    width: 88.r,
                    height: 88.r,
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
                            color: AppColors.grey400, size: 44.r)
                        : null,
                  ),

                  SizedBox(height: 8.h),

                  // Nom complet sous l'avatar
                  if (driver != null)
                    Text(
                      driver.fullName,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        color: AppColors.dark,
                      ),
                    ),

                  SizedBox(height: 28.h),
                  Divider(height: 1, color: AppColors.grey200),

                  // Lignes infos
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Prénom',
                    value: driver?.firstName ?? '—',
                  ),
                  Divider(height: 1, color: AppColors.grey200),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Nom',
                    value: driver?.lastName ?? '—',
                  ),
                  Divider(height: 1, color: AppColors.grey200),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: driver?.telephone ?? '—',
                  ),
                  Divider(height: 1, color: AppColors.grey200),
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: driver?.email ?? '—',
                  ),
                  Divider(height: 1, color: AppColors.grey200),
                  _InfoRow(
                    icon: Icons.home_outlined,
                    label: 'Adresse',
                    value: driver?.address?.isNotEmpty == true
                        ? driver!.address!
                        : 'Non renseignée',
                  ),
                  Divider(height: 1, color: AppColors.grey200),

                  // ── Pièce d'identité ──────────────────────
                  if (driver?.pieceIdentite != null) ...[
                    SizedBox(height: 24.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pièce d\'identité',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.dark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Divider(height: 1, color: AppColors.grey200),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Type',
                      value: driver!.pieceIdentite!.typeLabel,
                    ),
                    Divider(height: 1, color: AppColors.grey200),
                    _InfoRow(
                      icon: Icons.numbers_rounded,
                      label: 'Numéro',
                      value: driver.pieceIdentite!.numero.isNotEmpty
                          ? driver.pieceIdentite!.numero
                          : '—',
                    ),
                    Divider(height: 1, color: AppColors.grey200),
                  ],

                  // ── Suppression du compte ─────────────────
                  // Discrète et en bas de page : c'est une sortie de
                  // secours, pas une action proposée au même niveau
                  // que la modification des informations.
                  if (driver != null) ...[
                    SizedBox(height: 28.h),
                    TextButton(
                      onPressed: _suppressionEnCours
                          ? null
                          : () => _supprimerCompte(driver.id),
                      child: _suppressionEnCours
                          ? SizedBox(
                              height: 16.r,
                              width: 16.r,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.error),
                            )
                          : Text(
                              'Supprimer mon compte',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.error,
                              ),
                            ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),

          // ── Bouton Modifier ──────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: AppDimens.screenPadding.w,
              right: AppDimens.screenPadding.w,
              top: 12.h,
              bottom: MediaQuery.of(context).padding.bottom + 12.h,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight.h,
              child: ElevatedButton(
                onPressed: () =>
                    context.pushNamed(RouteNames.editPersonalInfo),
                child: const Text('Modifier'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ligne d'information ───────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.r, color: AppColors.grey600),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                    fontSize: 14.sp,
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
