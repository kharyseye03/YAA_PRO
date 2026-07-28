import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/constants.dart';
import '../../../model/gains/gains_summary.dart';

/// Ouvre le détail d'une mission terminée.
Future<void> showMissionGainSheet(
  BuildContext context,
  MissionGain mission,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: AppColors.dark.withValues(alpha: 0.45),
    builder: (_) => _MissionGainSheet(mission: mission),
  );
}

class _MissionGainSheet extends StatelessWidget {
  final MissionGain mission;
  const _MissionGainSheet({required this.mission});

  static const _mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  String get _dateLabel {
    final d = mission.dateHeureMission ?? mission.dateMission;
    if (d == null) return '—';
    return '${d.day} ${_mois[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isLivraison = mission.isLivraison;
    final accent =
        isLivraison ? AppColors.catRestaurant : AppColors.info;
    final accentSoft =
        isLivraison ? AppColors.catRestaurantLight : AppColors.infoLight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + AppDimens.lg.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Poignée ──────────────────────────────────────
            Container(
              width: 38.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 12.h, bottom: AppDimens.xl.h),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // ── Montant gagné ────────────────────────────────
            Container(
              width: 60.r,
              height: 60.r,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.check,
                  color: AppColors.success, size: 28.r),
            ),
            SizedBox(height: AppDimens.lg.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${mission.gainFormate}',
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    height: 1.1,
                  ),
                ),
                SizedBox(width: 5.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 5.h),
                  child: Text(
                    mission.devise,
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.grey500),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimens.sm.h),

            // Type de service + référence
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: accentSoft,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    mission.typeLabel,
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  mission.reference,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey400),
                ),
              ],
            ),

            SizedBox(height: AppDimens.xxl.h),

            // ── Itinéraire ───────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppDimens.lg.r),
                decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: 3.h),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 16.r,
                                height: 16.r,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                  width: 1.5, color: AppColors.grey300),
                            ),
                          ),
                          Icon(LucideIcons.mapPin,
                              size: 16.r, color: AppColors.secondary),
                          SizedBox(height: 3.h),
                        ],
                      ),
                      SizedBox(width: AppDimens.md.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Départ',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.grey500)),
                            SizedBox(height: 2.h),
                            Text(mission.adresseDepart,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.dark)),
                            SizedBox(height: 16.h),
                            Text('Arrivée',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.grey500)),
                            SizedBox(height: 2.h),
                            Text(mission.adresseArrivee,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.dark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: AppDimens.md.h),

            // ── Détails ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding.w),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.lg.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.scaffold,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: LucideIcons.calendar,
                      label: 'Date',
                      value: _dateLabel,
                    ),
                    Divider(height: 1, color: AppColors.grey200),
                    _DetailRow(
                      icon: LucideIcons.clock,
                      label: 'Heure',
                      value: mission.heure,
                    ),
                    Divider(height: 1, color: AppColors.grey200),
                    _DetailRow(
                      icon: LucideIcons.badgeCheck,
                      label: 'Statut',
                      value: mission.statutEnum.label,
                      valueColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppDimens.xl.h),

            // ── Fermer ───────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding.w),
              child: SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight.h,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.grey100,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Fermer',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.dark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ligne de détail ───────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: AppColors.grey500),
          SizedBox(width: 10.w),
          Text(label,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.labelSmall
                .copyWith(color: valueColor ?? AppColors.dark),
          ),
        ],
      ),
    );
  }
}
