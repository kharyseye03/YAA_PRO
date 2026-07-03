import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../../config/api/api_config.dart';
import '../auth/providers/auth_notifier.dart';
import '../auth/providers/driver_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.goNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final driver = ref.watch(driverDetailProvider).valueOrNull;
    final imageUrl = driver?.imageFileName != null
        ? ApiConfig.getImageUrl(driver!.imageFileName!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: top + 24.h),

            // ── Avatar + nom ─────────────────────────────────
            Center(
              child: Column(
                children: [
                  // Avatar avec bouton edit
                  Stack(
                    children: [
                      Container(
                        width: 88.r,
                        height: 88.r,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.grey200, width: 2),
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl == null
                            ? Icon(
                                Icons.person_rounded,
                                color: AppColors.grey400,
                                size: 44.r,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => context
                              .pushNamed(RouteNames.editPersonalInfo),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 28.r,
                            height: 28.r,
                            decoration: BoxDecoration(
                              color: AppColors.dark,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.white, width: 2),
                            ),
                            child: Icon(Icons.edit_rounded,
                                color: AppColors.white, size: 13.r),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // Nom
                  Text(
                    driver?.fullName ?? '...',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Email
                  Text(
                    driver?.email ?? '',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Note
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded,
                          color: const Color(0xFFF4C430), size: 16.r),
                      SizedBox(width: 4.w),
                      Text(
                        '4.8',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.dark),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(47 avis)',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey400),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),
            Divider(height: 1, color: AppColors.grey200),

            // ── Infos personnelles ────────────────────────────
            _Row(
              icon: Icons.person_outline_rounded,
              label: 'Informations personnelles',
              onTap: () => context.pushNamed(RouteNames.personalInfo),
            ),
            const _RowDivider(),
            _Row(
              icon: Icons.two_wheeler_rounded,
              label: 'Mon véhicule',
              subtitle: 'Honda CB 125 · DK 4421 AB',
              onTap: () {},
            ),
            const _RowDivider(),
            _Row(
              icon: Icons.bar_chart_rounded,
              label: 'Mes statistiques',
              subtitle: '47 livraisons · 312 km',
              onTap: () {},
            ),

            SizedBox(height: 8.h),
            Divider(height: 1, color: AppColors.grey200),
            SizedBox(height: 8.h),

            // ── Préférences ───────────────────────────────────
            _ToggleRow(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            const _RowDivider(),
            _Row(
              icon: Icons.language_rounded,
              label: 'Langue',
              subtitle: 'Français',
              onTap: () {},
            ),
            const _RowDivider(),
            _Row(
              icon: Icons.help_outline_rounded,
              label: 'Aide & Support',
              onTap: () {},
            ),
            const _RowDivider(),
            _Row(
              icon: Icons.privacy_tip_outlined,
              label: 'Confidentialité',
              onTap: () {},
            ),

            SizedBox(height: 8.h),
            Divider(height: 1, color: AppColors.grey200),
            SizedBox(height: 8.h),

            // ── Déconnexion ───────────────────────────────────
            _Row(
              icon: Icons.logout_rounded,
              label: 'Se déconnecter',
              labelColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: _logout,
            ),
            const _RowDivider(),
            _Row(
              icon: Icons.delete_outline_rounded,
              label: 'Supprimer mon compte',
              labelColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () {},
            ),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}

// ── Ligne simple ─────────────────────────────────────────────────
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.subtitle,
    this.labelColor,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding.w,
          vertical: 14.h,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20.r,
                color: iconColor ?? AppColors.grey600),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? AppColors.dark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null && labelColor == null)
              Icon(Icons.chevron_right,
                  size: 18.r, color: AppColors.grey300),
          ],
        ),
      ),
    );
  }
}

// ── Ligne avec toggle ─────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.screenPadding.w,
        vertical: 10.h,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.r, color: AppColors.grey600),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.dark,
              trackOutlineColor:
                  WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider interne indenté ───────────────────────────────────────
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 52.w),
      child: Divider(height: 1, color: AppColors.grey200),
    );
  }
}
