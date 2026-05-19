import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/constants.dart';

// ── Données statiques ───────────────────────────────────────────
class _Order {
  final String id;
  final String amount;
  final String distance;
  final String estimatedTime;
  final String pickup;
  final String pickupDetail;
  final String delivery;
  final String deliveryDetail;
  final int timerSeconds;
  final String category;

  const _Order({
    required this.id,
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

const _mockOrders = [
  _Order(
    id: '1',
    amount: '2 300',
    distance: '3.2 km',
    estimatedTime: '12 min',
    pickup: 'Marché Sandaga',
    pickupDetail: 'Plateau, Dakar',
    delivery: 'Cité Keur Gorgui',
    deliveryDetail: 'Mermoz, Dakar',
    timerSeconds: 45,
    category: 'Alimentation',
  ),
  _Order(
    id: '2',
    amount: '3 800',
    distance: '5.7 km',
    estimatedTime: '18 min',
    pickup: 'Point E',
    pickupDetail: 'Fann, Dakar',
    delivery: 'Les Almadies',
    deliveryDetail: 'Ngor, Dakar',
    timerSeconds: 112,
    category: 'Colis',
  ),
  _Order(
    id: '3',
    amount: '1 500',
    distance: '1.8 km',
    estimatedTime: '8 min',
    pickup: 'HLM Grand Yoff',
    pickupDetail: 'Grand Yoff, Dakar',
    delivery: 'Parcelles Assainies',
    deliveryDetail: 'Parcelles U15, Dakar',
    timerSeconds: 78,
    category: 'Pharmacie',
  ),
];

// ── Écran commandes ─────────────────────────────────────────────
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _filterIndex = 0;
  final _filters = ['Toutes', 'Proches', 'Bien payées'];

  @override
  Widget build(BuildContext context) {
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
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Commandes', style: AppTextStyles.h3),
                      SizedBox(height: 2.h),
                      Text(
                        '3 disponibles près de vous',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(Icons.tune_rounded,
                        color: AppColors.dark, size: 20.r),
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
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusFull),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.grey300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 13.sp,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? AppColors.white
                              : AppColors.grey600,
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
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.screenPadding.w),
                itemCount: _mockOrders.length,
                separatorBuilder: (_, __) => SizedBox(height: AppDimens.md.h),
                itemBuilder: (context, i) =>
                    _OrderCard(order: _mockOrders[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte commande ──────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final _Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final mins = order.timerSeconds ~/ 60;
    final secs = order.timerSeconds % 60;
    final timerStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
    final timerUrgent = order.timerSeconds < 60;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top strip
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppDimens.lg.w, AppDimens.lg.h, AppDimens.lg.w, 0),
            child: Row(
              children: [
                // Catégorie badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    order.category,
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
                      Icon(Icons.timer_outlined,
                          size: 12.r,
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
                  '${order.amount} FCFA',
                  style: AppTextStyles.h4
                      .copyWith(color: AppColors.secondary),
                ),
                SizedBox(width: AppDimens.sm.w),
                Container(
                  width: 4.r,
                  height: 4.r,
                  decoration: const BoxDecoration(
                    color: AppColors.grey400,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppDimens.sm.w),
                Text(
                  order.distance,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey600),
                ),
                SizedBox(width: AppDimens.sm.w),
                Container(
                  width: 4.r,
                  height: 4.r,
                  decoration: const BoxDecoration(
                    color: AppColors.grey400,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppDimens.sm.w),
                Text(
                  order.estimatedTime,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey600),
                ),
              ],
            ),
          ),

          // Itinéraire
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppDimens.lg.w, 0, AppDimens.lg.w, AppDimens.md.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icônes + ligne de connexion ──
                Column(
                  children: [
                    SizedBox(height: 15.h),
                    // Départ : cercle plein avec anneau extérieur
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 18.r,
                          height: 18.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
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
                    Container(width: 1.5, height: 40.h, color: AppColors.grey200),
                    // Arrivée : pin de localisation
                    Icon(LucideIcons.mapPin,
                        color: AppColors.secondary, size: 18.r),
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
                      SizedBox(height: 1.h),
                      Text(order.pickup,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.dark)),
                      Text(order.pickupDetail,
                          style: AppTextStyles.caption),
                      SizedBox(height: 10.h),
                      Text('Arrivée',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.grey500)),
                      SizedBox(height: 1.h),
                      Text(order.delivery,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.dark)),
                      Text(order.deliveryDetail,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
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
