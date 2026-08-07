import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/constants.dart';
import '../../model/gains/gains_summary.dart' show formatMontant;
import '../../model/order/history_mission.dart';
import '../../model/order/mission_statut.dart';
import 'providers/history_provider.dart';
import 'widgets/history_mission_sheet.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(historyByDayProvider);
    final totals = ref.watch(historyTotalProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(allMissionsProvider),
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.screenPadding.w,
                    AppDimens.lg.h,
                    AppDimens.screenPadding.w,
                    AppDimens.lg.h,
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
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(Icons.chevron_left_rounded,
                              color: AppColors.dark, size: 22.r),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Historique', style: AppTextStyles.h3),
                          SizedBox(height: 2.h),
                          Text('Vos courses terminées',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Résumé ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.screenPadding.w),
                  child: Row(
                    children: [
                      _SummaryCard(
                        label: 'Courses effectuées',
                        value: '${totals?.nombre ?? 0}',
                        icon: LucideIcons.checkCircle2,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: AppDimens.md.w),
                      _SummaryCard(
                        label: 'Total gagné',
                        value: formatMontant(totals?.gain ?? 0),
                        unit: 'FCFA',
                        icon: LucideIcons.wallet,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: AppDimens.xl.h)),

              // ── Liste ───────────────────────────────────────
              ...switch (daysAsync) {
                AsyncLoading() => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60.h),
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      ),
                    ),
                  ],
                AsyncError(:final error) => [
                    SliverToBoxAdapter(
                      child: _Message(
                        icon: LucideIcons.wifiOff,
                        text: error
                            .toString()
                            .replaceFirst('Exception: ', ''),
                        onRetry: () => ref.invalidate(allMissionsProvider),
                      ),
                    ),
                  ],
                AsyncValue(:final value)
                    when value == null || value.isEmpty =>
                  [
                    SliverToBoxAdapter(
                      child: _Message(
                        icon: LucideIcons.packageOpen,
                        text: 'Aucune course terminée pour le moment.',
                        onRetry: () => ref.invalidate(allMissionsProvider),
                      ),
                    ),
                  ],
                AsyncValue(:final value!) => [
                    for (final day in value) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppDimens.screenPadding.w,
                            0,
                            AppDimens.screenPadding.w,
                            AppDimens.sm.h,
                          ),
                          child: Row(
                            children: [
                              Text(day.label,
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: AppColors.grey700)),
                              const Spacer(),
                              Text(
                                '+${formatMontant(day.total)} FCFA',
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          AppDimens.screenPadding.w,
                          0,
                          AppDimens.screenPadding.w,
                          AppDimens.lg.h,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => Padding(
                              padding:
                                  EdgeInsets.only(bottom: AppDimens.sm.h),
                              child: _MissionTile(
                                mission: day.missions[i],
                                onTap: () => showHistoryMissionSheet(
                                    context, day.missions[i]),
                              ),
                            ),
                            childCount: day.missions.length,
                          ),
                        ),
                      ),
                    ],
                  ],
              },

              SliverToBoxAdapter(child: SizedBox(height: AppDimens.xl.h)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Couleurs du badge selon le type de service.
({Color bg, Color text}) typeColors(String type) =>
    switch (type.toUpperCase()) {
      'LIVRAISON' => (
          bg: AppColors.catRestaurantLight,
          text: AppColors.catRestaurant
        ),
      'COURSE' => (bg: AppColors.infoLight, text: AppColors.info),
      'LIVRAISON_COMMANDE' => (
          bg: AppColors.catBoutiqueLight,
          text: AppColors.catBoutique
        ),
      _ => (bg: AppColors.primarySurface, text: AppColors.primary),
    };

// ── Carte de mission ──────────────────────────────────────────────
class _MissionTile extends StatelessWidget {
  final HistoryMission mission;
  final VoidCallback onTap;

  const _MissionTile({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = typeColors(mission.typeService);
    final annulee = mission.statutEnum == MissionStatut.annule;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(AppDimens.md.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type · statut · heure
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: type.bg,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    mission.typeLabel,
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: type.text,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: annulee
                        ? AppColors.errorLight
                        : AppColors.successLight,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    annulee ? 'Annulée' : 'Terminée',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          annulee ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
                const Spacer(),
                Text(mission.heureLabel,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grey600)),
              ],
            ),
            SizedBox(height: AppDimens.md.h),

            // Gain · distance · durée
            Row(
              children: [
                Text(
                  annulee ? '—' : '${mission.gainFormate} ${mission.devise}',
                  style: AppTextStyles.h4.copyWith(
                    color: annulee ? AppColors.grey400 : AppColors.dark,
                  ),
                ),
                SizedBox(width: AppDimens.sm.w),
                _Dot(),
                SizedBox(width: AppDimens.sm.w),
                Text(mission.distanceLabel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey600)),
                SizedBox(width: AppDimens.sm.w),
                _Dot(),
                SizedBox(width: AppDimens.sm.w),
                Text(mission.dureeLabel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey600)),
              ],
            ),
            SizedBox(height: AppDimens.md.h),

            // Itinéraire
            IntrinsicHeight(
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
                                      .withValues(alpha: 0.3),
                                  width: 1.5),
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
                              width: 1.5, color: AppColors.grey200),
                        ),
                      ),
                      Icon(LucideIcons.mapPin,
                          color: AppColors.secondary, size: 16.r),
                      SizedBox(height: 3.h),
                    ],
                  ),
                  SizedBox(width: AppDimens.md.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mission.adresseDepart,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark)),
                        SizedBox(height: 14.h),
                        Text(mission.adresseArrivee,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 3.r,
        height: 3.r,
        decoration: const BoxDecoration(
            color: AppColors.grey400, shape: BoxShape.circle),
      );
}

// ── Carte de résumé ───────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(icon, color: color, size: 18.r),
            ),
            SizedBox(height: AppDimens.sm.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h4),
                ),
                if (unit != null) ...[
                  SizedBox(width: 3.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(unit!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey600)),
                  ),
                ],
              ],
            ),
            SizedBox(height: 2.h),
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey600)),
          ],
        ),
      ),
    );
  }
}

// ── État vide / erreur ────────────────────────────────────────────
class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onRetry;

  const _Message({
    required this.icon,
    required this.text,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppDimens.xxl.w, 50.h, AppDimens.xxl.w, 0),
      child: Column(
        children: [
          Icon(icon, size: 44.r, color: AppColors.grey300),
          SizedBox(height: AppDimens.lg.h),
          Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey600)),
          TextButton(
            onPressed: onRetry,
            child: Text('Actualiser',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
