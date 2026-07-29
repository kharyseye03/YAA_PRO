import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/constants.dart';
import '../../model/gains/gains_summary.dart';
import '../../model/order/type_service.dart';
import 'providers/gains_provider.dart';
import 'widgets/mission_gain_sheet.dart';

// ── Écran ───────────────────────────────────────────────────────
class GainsScreen extends ConsumerStatefulWidget {
  const GainsScreen({super.key});

  @override
  ConsumerState<GainsScreen> createState() => _GainsScreenState();
}

const _types = <TypeService>[
  TypeService.livraison,
  TypeService.course,
  TypeService.livraisonCommande,
];

class _GainsScreenState extends ConsumerState<GainsScreen> {
  bool _balanceVisible = true;

  /// « 12 – 28 juil. »
  String _customRangeLabel(DateTimeRange? range) {
    if (range == null) return GainsPeriod.personnalisee.label;
    String d(DateTime x) => '${x.day}/${x.month}';
    return '${d(range.start)} – ${d(range.end)}';
  }

  Future<void> _onPeriodTap(GainsPeriod period) async {
    if (period != GainsPeriod.personnalisee) {
      ref
          .read(gainsFilterProvider.notifier)
          .update((f) => f.copyWith(period: period));
      return;
    }

    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: ref.read(gainsFilterProvider).customRange,
      helpText: 'Choisir une période',
      saveText: 'Valider',
    );
    if (picked == null) return;
    ref.read(gainsFilterProvider.notifier).update(
          (f) => f.copyWith(
            period: GainsPeriod.personnalisee,
            customRange: picked,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(gainsByDayProvider);
    final summary = ref.watch(gainsProvider).valueOrNull;
    final filter = ref.watch(gainsFilterProvider);
    final hasFilter =
        filter.period != GainsPeriod.tout || filter.type != null;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.screenPadding.w,
                  AppDimens.lg.h,
                  AppDimens.screenPadding.w,
                  0,
                ),
                child: Text('Mes gains', style: AppTextStyles.h3),
              ),
            ),
          ),

          // ── Card solde ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.lg.h,
                AppDimens.screenPadding.w,
                0,
              ),
              child: Container(
                padding: EdgeInsets.all(AppDimens.xl.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF0D1117)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label + icône portefeuille + œil
                    Row(
                      children: [
                        Text(
                          'Solde disponible',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const Spacer(),
                        Icon(LucideIcons.wallet,
                            color: AppColors.white.withValues(alpha: 0.5),
                            size: 18.r),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _balanceVisible = !_balanceVisible),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            ),
                            child: Icon(
                              _balanceVisible
                                  ? LucideIcons.eye
                                  : LucideIcons.eyeOff,
                              color: AppColors.white,
                              size: 16.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.sm.h),

                    // Montant principal
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _balanceVisible
                              ? Text(
                                  '0',
                                  key: const ValueKey('shown'),
                                  style: TextStyle(
                                    fontFamily: 'Archivo',
                                    fontSize: 38.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white,
                                    height: 1.1,
                                  ),
                                )
                              : Text(
                                  '••••••',
                                  key: const ValueKey('hidden'),
                                  style: TextStyle(
                                    fontFamily: 'Archivo',
                                    fontSize: 38.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.white.withValues(alpha: 0.5),
                                    height: 1.1,
                                    letterSpacing: 4,
                                  ),
                                ),
                        ),
                        SizedBox(width: 6.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Text(
                            'FCFA',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.xs.h),

                    // Sous-texte gains aujourd'hui
                    Row(
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          _balanceVisible
                              ? '+${summary?.aujourdhuiFormate ?? '0'} '
                                  '${summary?.devise ?? 'FCFA'} aujourd\'hui'
                              : '•••••• FCFA aujourd\'hui',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 12.sp,
                            color: AppColors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.xl.h),

                    // Bouton Charger
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(LucideIcons.wallet, size: 16.r),
                        label: Text(
                          'Charger mes gains',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.dark,
                          minimumSize: Size(double.infinity, 48.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusMd),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Titre section courses ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.xl.h,
                AppDimens.screenPadding.w,
                AppDimens.md.h,
              ),
              child: Row(
                children: [
                  Text('Mes courses', style: AppTextStyles.labelLarge),
                  const Spacer(),
                  if (summary != null)
                    Text(
                      '${summary.nombreMissions} course${summary.nombreMissions > 1 ? 's' : ''} · +${summary.totalFormate} ${summary.devise}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey500),
                    ),
                ],
              ),
            ),
          ),

          // ── Filtres : tous · période · service ──────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding.w),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tous',
                    selected: !hasFilter,
                    onTap: () => ref
                        .read(gainsFilterProvider.notifier)
                        .state = const GainsFilter(),
                  ),
                  SizedBox(width: 8.w),

                  // Période
                  PopupMenuButton<GainsPeriod>(
                    offset: Offset(0, 40.h),
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    onSelected: _onPeriodTap,
                    itemBuilder: (_) => [
                      for (final p in GainsPeriod.values.skip(1))
                        PopupMenuItem(
                          value: p,
                          child: Text(
                            p.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.dark,
                              fontWeight: p == filter.period
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                    child: _FilterChip(
                      label: filter.period == GainsPeriod.tout
                          ? 'Période'
                          : filter.period == GainsPeriod.personnalisee
                              ? _customRangeLabel(filter.customRange)
                              : filter.period.label,
                      selected: filter.period != GainsPeriod.tout,
                      showChevron: true,
                    ),
                  ),
                  SizedBox(width: 8.w),

                  // Type de service
                  PopupMenuButton<TypeService>(
                    offset: Offset(0, 40.h),
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    onSelected: (t) => ref
                        .read(gainsFilterProvider.notifier)
                        .update((f) => f.copyWith(type: t)),
                    itemBuilder: (_) => [
                      for (final t in _types)
                        PopupMenuItem(
                          value: t,
                          child: Text(
                            t.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.dark,
                              fontWeight: t == filter.type
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                    child: _FilterChip(
                      label: filter.type?.label ?? 'Service',
                      selected: filter.type != null,
                      showChevron: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: AppDimens.md.h)),

          // ── Historique groupé par jour ──────────────────────
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
                  child: _GainsMessage(
                    icon: LucideIcons.wifiOff,
                    message:
                        error.toString().replaceFirst('Exception: ', ''),
                    onRetry: () => ref.invalidate(gainsProvider),
                  ),
                ),
              ],
            AsyncValue(:final value) when value == null || value.isEmpty =>
              [
                SliverToBoxAdapter(
                  child: _GainsMessage(
                    icon: LucideIcons.receipt,
                    message:
                        'Aucune course terminée pour le moment.\nVos gains apparaîtront ici.',
                    onRetry: () => ref.invalidate(gainsProvider),
                  ),
                ),
              ],
            AsyncValue(:final value!) => [
                for (final day in value) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppDimens.screenPadding.w,
                        AppDimens.sm.h,
                        AppDimens.screenPadding.w,
                        AppDimens.sm.h,
                      ),
                      child: Row(
                        children: [
                          Text(
                            day.label,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.grey600),
                          ),
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
                      AppDimens.md.h,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: EdgeInsets.only(bottom: AppDimens.sm.h),
                          child: _CourseTile(
                            mission: day.missions[i],
                            onTap: () => showMissionGainSheet(
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

          SliverToBoxAdapter(child: SizedBox(height: 90.h)),
        ],
      ),
    );
  }
}

// ── Chip de filtre ──────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool showChevron;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: selected ? AppColors.dark : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        border: Border.all(
          color: selected ? AppColors.dark : AppColors.grey300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 12.sp,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.white : AppColors.grey600,
            ),
          ),
          if (showChevron) ...[
            SizedBox(width: 4.w),
            Icon(
              LucideIcons.chevronDown,
              size: 13.r,
              color: selected ? AppColors.white : AppColors.grey500,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: chip,
    );
  }
}

// ── État vide / erreur ──────────────────────────────────────────
class _GainsMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _GainsMessage({
    required this.icon,
    required this.message,
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
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.grey500),
          ),
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

// ── Tile course ─────────────────────────────────────────────────
class _CourseTile extends StatelessWidget {
  final MissionGain mission;
  final VoidCallback onTap;

  const _CourseTile({required this.mission, required this.onTap});

  /// Couleurs selon le type de service.
  static ({Color bg, Color icon}) typeColor(String type) =>
      switch (type.toUpperCase()) {
        'LIVRAISON' => (
            bg: AppColors.catRestaurantLight,
            icon: AppColors.catRestaurant
          ),
        'COURSE' => (bg: AppColors.infoLight, icon: AppColors.info),
        'LIVRAISON_COMMANDE' => (
            bg: AppColors.catBoutiqueLight,
            icon: AppColors.catBoutique
          ),
        _ => (bg: AppColors.primarySurface, icon: AppColors.primary),
      };

  static IconData typeIcon(String type) => switch (type.toUpperCase()) {
        'LIVRAISON' => LucideIcons.package,
        'COURSE' => LucideIcons.userCheck,
        'LIVRAISON_COMMANDE' => LucideIcons.shoppingBag,
        _ => LucideIcons.mapPin,
      };

  @override
  Widget build(BuildContext context) {
    final cc = typeColor(mission.typeService);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppDimens.md.w, vertical: AppDimens.md.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icône type de service
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: cc.bg,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(typeIcon(mission.typeService),
                  color: cc.icon, size: 20.r),
            ),
            SizedBox(width: AppDimens.md.w),

            // Trajet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${mission.adresseDepart} → ${mission.adresseArrivee}',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.dark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Text('${mission.typeLabel} · ${mission.heure}',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            SizedBox(width: AppDimens.sm.w),

            // Montant
            Text(
              '+${mission.gainFormate} F',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }
}
