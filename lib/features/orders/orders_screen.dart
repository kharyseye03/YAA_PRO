import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../../model/order/commande_livraison.dart';
import 'order_detail_screen.dart';
import 'providers/orders_provider.dart';

// ── Écran commandes ─────────────────────────────────────────────
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  int _filterIndex = 0;
  final _filters = ['Toutes', 'Proches', 'Bien payées'];

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(availableOrdersProvider);
    final count = ordersAsync.valueOrNull?.length;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.lg.h,
                AppDimens.screenPadding.w,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commandes', style: AppTextStyles.h3),
                  SizedBox(height: 2.h),
                  Text(
                    count != null
                        ? '$count disponible${count > 1 ? 's' : ''} près de vous'
                        : 'Recherche de commandes...',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimens.lg.h),

            // Filtres
            SizedBox(
              height: 38.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: AppDimens.screenPadding.w),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => SizedBox(width: AppDimens.sm.w),
                itemBuilder: (context, i) {
                  final selected = i == _filterIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: AppDimens.lg.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.grey300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 13.sp,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppColors.white : AppColors.grey600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: AppDimens.lg.h),

            // Liste commandes
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    ref.invalidate(availableOrdersProvider),
                child: ordersAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                  error: (e, _) => _MessageState(
                    icon: LucideIcons.wifiOff,
                    message:
                        e.toString().replaceFirst('Exception: ', ''),
                    onRetry: () =>
                        ref.invalidate(availableOrdersProvider),
                  ),
                  data: (orders) => orders.isEmpty
                      ? _MessageState(
                          icon: LucideIcons.packageOpen,
                          message:
                              'Aucune commande disponible pour le moment.',
                          onRetry: () =>
                              ref.invalidate(availableOrdersProvider),
                        )
                      : ListView.separated(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.screenPadding.w),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: AppDimens.md.h),
                          itemBuilder: (context, i) =>
                              _OrderCard(order: orders[i]),
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

// ── État message (vide / erreur) ────────────────────────────────
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _MessageState({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // ListView pour rester compatible avec le pull-to-refresh
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Icon(icon, size: 48.r, color: AppColors.grey300),
        SizedBox(height: AppDimens.lg.h),
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding.w * 2),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
          ),
        ),
        SizedBox(height: AppDimens.lg.h),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(
              'Réessayer',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Carte commande ──────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final CommandeLivraison order;
  const _OrderCard({required this.order});

  // ⏳ En attendant que le back fournisse ces champs
  static const _mockAmount = '2 300';
  static const _mockDistance = '3.2 km';
  static const _mockTime = '12 min';
  static const _mockTimerSeconds = 45;
  static const _mockCategory = 'Restaurant';

  static ({Color bg, Color text}) _catColors(String cat) =>
      switch (cat.toLowerCase()) {
        'restaurant'  => (bg: AppColors.catRestaurantLight, text: AppColors.catRestaurant),
        'pharmacie'   => (bg: AppColors.catPharmacieLight,  text: AppColors.catPharmacie),
        'boutique'    => (bg: AppColors.catBoutiqueLight,   text: AppColors.catBoutique),
        'supermarché' => (bg: AppColors.catSupermarcheLight,text: AppColors.catSupermarche),
        'supermarche' => (bg: AppColors.catSupermarcheLight,text: AppColors.catSupermarche),
        _             => (bg: AppColors.primarySurface,     text: AppColors.primary),
      };

  @override
  Widget build(BuildContext context) {
    const mins = _mockTimerSeconds ~/ 60;
    const secs = _mockTimerSeconds % 60;
    final timerStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
    const timerUrgent = _mockTimerSeconds < 60;
    final catColor = _catColors(_mockCategory);

    final args = OrderDetailArgs(
      id: '#${order.shortRef}',
      amount: _mockAmount,
      distance: _mockDistance,
      estimatedTime: _mockTime,
      pickup: order.structureName,
      delivery: order.adresseLivraison,
      timerSeconds: _mockTimerSeconds,
      category: _mockCategory,
      merchantName: order.structureName,
      merchantAddress: order.structureAdresse,
      merchantPhone: order.structureTelephone,
      clientName: 'Client',
      clientPhone: order.telephoneClient,
      clientNotes: order.description,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Zone tappable (tout sauf les boutons)
          GestureDetector(
            onTap: () => context.pushNamed(
              RouteNames.orderDetail,
              extra: args,
            ),
            behavior: HitTestBehavior.opaque,
            child: Column(children: [
          // Top strip
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppDimens.lg.w, AppDimens.md.h, AppDimens.lg.w, 0),
            child: Row(
              children: [
                // Catégorie badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: catColor.bg,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    _mockCategory,
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: catColor.text,
                    ),
                  ),
                ),
                const Spacer(),
                // Timer
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: timerUrgent
                        ? AppColors.errorLight
                        : AppColors.warningLight,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.timer,
                          size: 11.r,
                          color: timerUrgent
                              ? AppColors.error
                              : AppColors.warning),
                      SizedBox(width: 3.w),
                      Text(
                        timerStr,
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: timerUrgent
                              ? AppColors.error
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Montant + infos
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppDimens.lg.w, vertical: AppDimens.md.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$_mockAmount FCFA',
                  style: AppTextStyles.h4
                      .copyWith(color: AppColors.dark),
                ),
                SizedBox(width: AppDimens.sm.w),
                Container(
                  width: 3.r,
                  height: 3.r,
                  decoration: const BoxDecoration(
                    color: AppColors.grey400,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppDimens.sm.w),
                Text(
                  _mockDistance,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
                SizedBox(width: AppDimens.sm.w),
                Container(
                  width: 3.r,
                  height: 3.r,
                  decoration: const BoxDecoration(
                    color: AppColors.grey400,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppDimens.sm.w),
                Text(
                  _mockTime,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),

          // Itinéraire
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppDimens.lg.w, 0, AppDimens.lg.w, AppDimens.md.h),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Icônes + ligne flexible ──
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
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3),
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
                      Expanded(
                        child: Center(
                          child: Container(
                              width: 1.5, color: AppColors.grey200),
                        ),
                      ),
                      Icon(LucideIcons.mapPin,
                          color: AppColors.secondary, size: 18.r),
                      SizedBox(height: 3.h),
                    ],
                  ),
                  SizedBox(width: AppDimens.md.w),
                  // ── Textes départ / arrivée ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Départ',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grey500)),
                        SizedBox(height: 2.h),
                        Text(order.structureName,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark)),
                        SizedBox(height: 12.h),
                        Text('Arrivée',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grey500)),
                        SizedBox(height: 2.h),
                        Text(order.adresseLivraison,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ]), // fin GestureDetector
          ),

          // Divider
          Divider(height: 1, color: AppColors.grey100),

          // Boutons
          Padding(
            padding: EdgeInsets.all(AppDimens.md.r),
            child: Row(
              children: [
                // Refuser
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey600,
                      side: const BorderSide(color: AppColors.grey300),
                      minimumSize: Size(double.infinity, 44.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    child: Text(
                      'Refuser',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppDimens.sm.w),
                // Accepter
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 44.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 16.r),
                        SizedBox(width: 6.w),
                        Text(
                          'Accepter',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
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
