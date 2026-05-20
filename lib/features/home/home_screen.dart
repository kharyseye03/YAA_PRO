import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../orders/order_detail_screen.dart';
import '../shell/main_shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _order = _OrderData(
    amount: '2 300',
    distance: '3.2 km',
    estimatedTime: '12 min',
    pickup: 'Marché Sandaga',
    pickupDetail: 'Plateau, Dakar',
    delivery: 'Cité Keur Gorgui',
    deliveryDetail: 'Mermoz, Dakar',
    timerSeconds: 45,
    category: 'Restaurant',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // icônes blanches (Android)
        statusBarBrightness: Brightness.dark,       // iOS
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Map plein écran ───────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/map2.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── Header dark arrondi en bas ────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HomeHeader(),
          ),

          // ── Éléments flottants en bas ─────────────────────
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: 90.h,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FloatingRow(
                  onTapAll: () =>
                      ref.read(shellIndexProvider.notifier).state = 1,
                ),
                SizedBox(height: 10.h),
                _OrderCard(order: _order),
              ],
            ),
          ),
        ],
      ),
    )); // AnnotatedRegion
  }
}

// ── Header dark (couleur bottom nav) ───────────────────────────
class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding.w,
        right: AppDimens.screenPadding.w,
        top: MediaQuery.of(context).padding.top + AppDimens.sm.h,
        bottom: AppDimens.lg.h,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bonjour, Mame 👋',
                  style: AppTextStyles.h4.copyWith(color: AppColors.white),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin,
                        color: AppColors.white, size: 13.r),
                    SizedBox(width: 4.w),
                    Text(
                      'Dakar, Sénégal',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.6)),
                    ),
                    SizedBox(width: 2.w),
                    Icon(LucideIcons.chevronDown,
                        color: AppColors.white.withValues(alpha: 0.6),
                        size: 12.r),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: 40.r,
                  height: 40.r,
                  child: Icon(LucideIcons.bell,
                      color: AppColors.white, size: 22.r),
                ),
                Positioned(
                  top: 8.h,
                  right: 6.w,
                  child: Container(
                    width: 7.r,
                    height: 7.r,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
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

// ── Ligne "Commandes disponibles" — card indépendante ──────────
class _FloatingRow extends StatelessWidget {
  final VoidCallback onTapAll;
  const _FloatingRow({required this.onTapAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppDimens.lg.w, vertical: AppDimens.md.h),
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
      child: Row(
        children: [
          Text('Commandes disponibles',
              style: AppTextStyles.labelMedium),
          SizedBox(width: AppDimens.sm.w),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppDimens.radiusFull),
            ),
            child: Text(
              '3',
              style: TextStyle(
                fontFamily: 'Archivo',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTapAll,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tous',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(Icons.chevron_right,
                      size: 14.r, color: AppColors.dark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte commande — card indépendante ─────────────────────────
class _OrderCard extends StatelessWidget {
  final _OrderData order;
  const _OrderCard({required this.order});

  /// Retourne (bg, text) selon la catégorie
  static ({Color bg, Color text}) _catColors(String cat) =>
      switch (cat.toLowerCase()) {
        'restaurant'   => (bg: AppColors.catRestaurantLight, text: AppColors.catRestaurant),
        'pharmacie'    => (bg: AppColors.catPharmacieLight,  text: AppColors.catPharmacie),
        'boutique'     => (bg: AppColors.catBoutiqueLight,   text: AppColors.catBoutique),
        'supermarché'  => (bg: AppColors.catSupermarcheLight,text: AppColors.catSupermarche),
        'supermarche'  => (bg: AppColors.catSupermarcheLight,text: AppColors.catSupermarche),
        _              => (bg: AppColors.primarySurface,     text: AppColors.primary),
      };

  @override
  Widget build(BuildContext context) {
    final mins = order.timerSeconds ~/ 60;
    final secs = order.timerSeconds % 60;
    final timerStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
    final timerUrgent = order.timerSeconds < 60;
    final catColor = _catColors(order.category);

    final args = OrderDetailArgs(
      id: '#CMD-2024-001',
      amount: order.amount,
      distance: order.distance,
      estimatedTime: order.estimatedTime,
      pickup: order.pickup,
      delivery: order.delivery,
      timerSeconds: order.timerSeconds,
      category: order.category,
      merchantName: 'Chez Fatou Restaurant',
      merchantAddress: 'Marché Sandaga, Plateau, Dakar',
      merchantPhone: '+221 33 821 45 67',
      clientName: 'Aissatou Diallo',
      clientPhone: '+221 77 456 78 90',
      clientNotes: 'Appeler à l\'arrivée. Code portail : 1234',
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
          // Catégorie + timer
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppDimens.lg.w, AppDimens.md.h, AppDimens.lg.w, 0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: catColor.bg,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    order.category,
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: catColor.text,
                    ),
                  ),
                ),
                const Spacer(),
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

          // Montant + méta
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppDimens.lg.w, vertical: AppDimens.sm.h),
            child: Row(
              children: [
                Text('${order.amount} FCFA',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.black)),
                SizedBox(width: AppDimens.sm.w),
                _Dot(),
                SizedBox(width: AppDimens.sm.w),
                Text(order.distance,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500)),
                SizedBox(width: AppDimens.sm.w),
                _Dot(),
                SizedBox(width: AppDimens.sm.w),
                Text(order.estimatedTime,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500)),
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
                        Text(order.pickup,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark)),
                        SizedBox(height: 12.h),
                        Text('Arrivée',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grey500)),
                        SizedBox(height: 2.h),
                        Text(order.delivery,
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

          // Boutons
          Divider(height: 1, color: AppColors.grey100),
          Padding(
            padding: EdgeInsets.all(AppDimens.md.r),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.grey600,
                      side: const BorderSide(color: AppColors.grey300),
                      minimumSize: Size(double.infinity, 42.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    child: Text('Refuser',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey600,
                        )),
                  ),
                ),
                SizedBox(width: AppDimens.sm.w),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 42.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 15.r),
                        SizedBox(width: 5.w),
                        Text('Accepter',
                            style: TextStyle(
                              fontFamily: 'Archivo',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            )),
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

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 3.r,
        height: 3.r,
        decoration: const BoxDecoration(
            color: AppColors.grey400, shape: BoxShape.circle),
      );
}

class _OrderData {
  final String amount;
  final String distance;
  final String estimatedTime;
  final String pickup;
  final String pickupDetail;
  final String delivery;
  final String deliveryDetail;
  final int timerSeconds;
  final String category;

  const _OrderData({
    required this.amount,
    required this.distance,
    required this.estimatedTime,
    required this.pickup,
    required this.pickupDetail,
    required this.delivery,
    required this.deliveryDetail,
    required this.timerSeconds,
    required this.category,
  });
}
