import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/constants.dart';
import '../../../model/order/history_mission.dart';
import '../../../model/order/mission_statut.dart';

/// Détail d'une mission passée, avec le décompte de la rémunération.
Future<void> showHistoryMissionSheet(
  BuildContext context,
  HistoryMission mission,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: AppColors.dark.withValues(alpha: 0.45),
    builder: (_) => _HistoryMissionSheet(mission: mission),
  );
}

class _HistoryMissionSheet extends StatelessWidget {
  final HistoryMission mission;
  const _HistoryMissionSheet({required this.mission});

  static const _mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  String get _dateLabel {
    final d = mission.date;
    if (d == null) return '—';
    return '${d.day} ${_mois[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final annulee = mission.statutEnum == MissionStatut.annule;
    final accent = annulee ? AppColors.error : AppColors.success;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
            // Poignée
            Container(
              width: 38.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 12.h, bottom: AppDimens.xl.h),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Gain
            Container(
              width: 60.r,
              height: 60.r,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(annulee ? LucideIcons.x : LucideIcons.check,
                  color: accent, size: 28.r),
            ),
            SizedBox(height: AppDimens.lg.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  annulee ? '—' : '+${mission.gainFormate}',
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 34.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    height: 1.1,
                  ),
                ),
                if (!annulee) ...[
                  SizedBox(width: 5.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 5.h),
                    child: Text(mission.devise,
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.grey600)),
                  ),
                ],
              ],
            ),
            SizedBox(height: AppDimens.sm.h),

            Text(
              mission.reference,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.grey600),
            ),
            SizedBox(height: AppDimens.xxl.h),

            // ── Itinéraire ────────────────────────────────────
            _Bloc(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 3.h),
                        Container(
                          width: 12.r,
                          height: 12.r,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
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
                                  .copyWith(color: AppColors.grey600)),
                          SizedBox(height: 2.h),
                          Text(mission.adresseDepart,
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.dark)),
                          SizedBox(height: 16.h),
                          Text('Arrivée',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.grey600)),
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

            SizedBox(height: AppDimens.md.h),

            // ── Décompte de la rémunération ───────────────────
            if (!annulee)
              _Bloc(
                child: Column(
                  children: [
                    _Ligne(
                      label: 'Prix de la course',
                      value: '${mission.fraisFormate} ${mission.devise}',
                    ),
                    _Ligne(
                      label: 'Commission YAA',
                      value: '− ${mission.commissionFormate}',
                      valueColor: AppColors.error,
                    ),
                    if (mission.bonus > 0)
                      _Ligne(
                        label: 'Bonus',
                        value: '+ ${mission.bonusFormate}',
                        valueColor: AppColors.success,
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child:
                          Divider(height: 1, color: AppColors.grey300),
                    ),
                    _Ligne(
                      label: 'Votre gain',
                      value: '${mission.gainFormate} ${mission.devise}',
                      valueColor: AppColors.success,
                      gras: true,
                    ),
                  ],
                ),
              ),

            SizedBox(height: AppDimens.md.h),

            // ── Informations ──────────────────────────────────
            _Bloc(
              child: Column(
                children: [
                  _Ligne(label: 'Client', value: mission.client),
                  _Ligne(label: 'Type', value: mission.typeLabel),
                  _Ligne(label: 'Date', value: _dateLabel),
                  _Ligne(label: 'Heure', value: mission.heureLabel),
                  _Ligne(
                      label: 'Distance', value: mission.distanceLabel),
                  _Ligne(label: 'Durée', value: mission.dureeLabel),
                  _Ligne(
                    label: 'Statut',
                    value: mission.statutEnum.label,
                    valueColor: accent,
                  ),
                ],
              ),
            ),

            if (mission.instructions.isNotEmpty) ...[
              SizedBox(height: AppDimens.md.h),
              _Bloc(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.clipboardList,
                        size: 16.r, color: AppColors.grey600),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(mission.instructions,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.grey800)),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: AppDimens.xl.h),

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
                  child: Text('Fermer',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.dark)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Encadré gris doux ─────────────────────────────────────────────
class _Bloc extends StatelessWidget {
  final Widget child;
  const _Bloc({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: AppDimens.screenPadding.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: AppDimens.lg.w, vertical: AppDimens.md.h),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: child,
      ),
    );
  }
}

// ── Ligne libellé / valeur ────────────────────────────────────────
class _Ligne extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool gras;

  const _Ligne({
    required this.label,
    required this.value,
    this.valueColor,
    this.gras = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: [
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.grey700)),
          const Spacer(),
          Text(
            value.isNotEmpty ? value : '—',
            style: (gras
                    ? AppTextStyles.labelMedium
                    : AppTextStyles.labelSmall)
                .copyWith(color: valueColor ?? AppColors.dark),
          ),
        ],
      ),
    );
  }
}
