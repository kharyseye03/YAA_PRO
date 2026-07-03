import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../config/api/api_config.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../auth/providers/driver_provider.dart';

class PersonalInfoScreen extends ConsumerWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
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
