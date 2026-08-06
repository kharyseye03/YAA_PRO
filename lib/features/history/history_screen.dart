import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/constants.dart';

class _Delivery {
  final String time;
  final String from;
  final String to;
  final String amount;
  final String status;
  const _Delivery({
    required this.time,
    required this.from,
    required this.to,
    required this.amount,
    required this.status,
  });
}

class _DayGroup {
  final String label;
  final String total;
  final List<_Delivery> deliveries;
  const _DayGroup({required this.label, required this.total, required this.deliveries});
}

const _history = [
  _DayGroup(
    label: 'Aujourd\'hui',
    total: '15 500',
    deliveries: [
      _Delivery(time: '14h32', from: 'Sandaga', to: 'Keur Gorgui', amount: '2 300', status: 'delivered'),
      _Delivery(time: '11h15', from: 'Plateau', to: 'Mermoz', amount: '1 800', status: 'delivered'),
      _Delivery(time: '09h47', from: 'Point E', to: 'Les Almadies', amount: '3 800', status: 'delivered'),
    ],
  ),
  _DayGroup(
    label: 'Hier',
    total: '8 500',
    deliveries: [
      _Delivery(time: '17h20', from: 'Grand Yoff', to: 'Parcelles U15', amount: '1 500', status: 'delivered'),
      _Delivery(time: '13h05', from: 'Fann', to: 'Ouakam', amount: '2 200', status: 'delivered'),
      _Delivery(time: '10h30', from: 'Médina', to: 'Sacré Cœur', amount: '2 800', status: 'cancelled'),
    ],
  ),
  _DayGroup(
    label: 'Vendredi 17 mai',
    total: '12 000',
    deliveries: [
      _Delivery(time: '16h45', from: 'Liberté 6', to: 'Ngor', amount: '3 500', status: 'delivered'),
      _Delivery(time: '12h10', from: 'Plateau', to: 'Hann Mariste', amount: '2 100', status: 'delivered'),
      _Delivery(time: '09h00', from: 'Pikine', to: 'Guédiawaye', amount: '1 900', status: 'delivered'),
    ],
  ),
];

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
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
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.dark,
                          size: 22.r,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Historique', style: AppTextStyles.h3),
                        SizedBox(height: 2.h),
                        Text('Vos dernières livraisons',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Résumé global
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.screenPadding.w),
                child: Row(
                  children: [
                    _SummaryCard(
                      label: 'Total livraisons',
                      value: '47',
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppDimens.md.w),
                    _SummaryCard(
                      label: 'Gains totaux',
                      value: '183 200',
                      unit: 'FCFA',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppDimens.xl.h)),

            // Liste groupée
            for (final group in _history) ...[
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
                      Text(group.label,
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.grey700)),
                      const Spacer(),
                      Text(
                        '${group.total} FCFA',
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
                      padding: EdgeInsets.only(bottom: AppDimens.sm.h),
                      child: _DeliveryTile(delivery: group.deliveries[i]),
                    ),
                    childCount: group.deliveries.length,
                  ),
                ),
              ),
            ],

            SliverToBoxAdapter(child: SizedBox(height: AppDimens.xl.h)),
          ],
        ),
      ),
    );
  }
}

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
                Text(value, style: AppTextStyles.h4),
                if (unit != null) ...[
                  SizedBox(width: 3.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      unit!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grey500),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 2.h),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final _Delivery delivery;
  const _DeliveryTile({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final isCancelled = delivery.status == 'cancelled';

    return Container(
      padding: EdgeInsets.all(AppDimens.md.r),
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
          // Icône statut
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: isCancelled
                  ? AppColors.errorLight
                  : AppColors.successLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Icon(
              isCancelled
                  ? Icons.close_rounded
                  : Icons.check_rounded,
              color: isCancelled ? AppColors.error : AppColors.success,
              size: 20.r,
            ),
          ),
          SizedBox(width: AppDimens.md.w),

          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${delivery.from} → ${delivery.to}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.dark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Text(delivery.time, style: AppTextStyles.caption),
                    SizedBox(width: AppDimens.sm.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: isCancelled
                            ? AppColors.errorLight
                            : AppColors.successLight,
                        borderRadius: BorderRadius.circular(
                            AppDimens.radiusFull),
                      ),
                      child: Text(
                        isCancelled ? 'Annulée' : 'Livrée',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Montant
          Text(
            isCancelled ? '—' : '+${delivery.amount} F',
            style: AppTextStyles.labelMedium.copyWith(
              color: isCancelled ? AppColors.grey400 : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}
