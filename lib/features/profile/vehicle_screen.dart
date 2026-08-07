import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/constants.dart';
import '../auth/providers/driver_provider.dart';

/// Véhicule déclaré par le livreur : marque, immatriculation,
/// permis et assurance.
class VehicleScreen extends ConsumerWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicule =
        ref.watch(driverDetailProvider).valueOrNull?.vehiculeInfo;

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
                    child: Icon(Icons.chevron_left_rounded,
                        color: AppColors.dark, size: 22.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Mon véhicule',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.grey200),

          Expanded(
            child: vehicule == null
                ? _AucunVehicule()
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.screenPadding.w),
                    child: Column(
                      children: [
                        SizedBox(height: 28.h),

                        // Vignette du véhicule
                        Container(
                          width: 88.r,
                          height: 88.r,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.two_wheeler_rounded,
                              color: AppColors.primary, size: 44.r),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          vehicule.marque.isNotEmpty
                              ? vehicule.marque
                              : 'Véhicule',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                            color: AppColors.dark,
                          ),
                        ),
                        if (vehicule.immatriculation.isNotEmpty)
                          Text(
                            vehicule.immatriculation,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.grey600),
                          ),

                        SizedBox(height: 28.h),
                        Divider(height: 1, color: AppColors.grey200),

                        _InfoRow(
                          icon: Icons.directions_car_outlined,
                          label: 'Marque',
                          value: vehicule.marque,
                        ),
                        Divider(height: 1, color: AppColors.grey200),
                        _InfoRow(
                          icon: Icons.pin_outlined,
                          label: 'Immatriculation',
                          value: vehicule.immatriculation,
                        ),
                        Divider(height: 1, color: AppColors.grey200),
                        _InfoRow(
                          icon: Icons.palette_outlined,
                          label: 'Couleur',
                          value: vehicule.couleur,
                        ),
                        Divider(height: 1, color: AppColors.grey200),
                        _InfoRow(
                          icon: Icons.credit_card_outlined,
                          label: 'Permis de conduire',
                          value: vehicule.permis,
                        ),
                        Divider(height: 1, color: AppColors.grey200),
                        _InfoRow(
                          icon: Icons.verified_user_outlined,
                          label: 'Assurance',
                          value: vehicule.assurance,
                        ),
                        Divider(height: 1, color: AppColors.grey200),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Aucun véhicule déclaré ────────────────────────────────────────
class _AucunVehicule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.xxl.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.two_wheeler_rounded,
                size: 48.r, color: AppColors.grey300),
            SizedBox(height: AppDimens.lg.h),
            Text(
              'Aucun véhicule enregistré',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ligne d'information ───────────────────────────────────────────
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
                    color: AppColors.grey600,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value.isNotEmpty ? value : '—',
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
