import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/constants.dart';

class GainsScreen extends StatefulWidget {
  const GainsScreen({super.key});

  @override
  State<GainsScreen> createState() => _GainsScreenState();
}

class _GainsScreenState extends State<GainsScreen> {
  int _periodIndex = 1; // 0=Jour, 1=Semaine, 2=Mois
  final _periods = ['Jour', 'Semaine', 'Mois'];

  // Données simulées par période
  final _weekData = [4200.0, 8500.0, 12000.0, 7300.0, 15500.0, 0.0, 0.0];
  final _weekLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  final _dayData = [0.0, 1200.0, 2300.0, 1800.0, 3500.0, 3200.0, 2500.0, 1000.0];
  final _dayLabels = ['7h', '8h', '9h', '10h', '11h', '12h', '13h', '14h'];
  final _monthData = [42000.0, 38000.0, 55000.0, 48200.0];
  final _monthLabels = ['Fév', 'Mar', 'Avr', 'Mai'];

  List<double> get _currentData {
    switch (_periodIndex) {
      case 0: return _dayData;
      case 2: return _monthData;
      default: return _weekData;
    }
  }

  List<String> get _currentLabels {
    switch (_periodIndex) {
      case 0: return _dayLabels;
      case 2: return _monthLabels;
      default: return _weekLabels;
    }
  }

  String get _totalLabel {
    switch (_periodIndex) {
      case 0: return 'Gains aujourd\'hui';
      case 2: return 'Gains ce mois';
      default: return 'Gains cette semaine';
    }
  }

  String get _totalAmount {
    switch (_periodIndex) {
      case 0: return '15 500';
      case 2: return '183 200';
      default: return '47 500';
    }
  }

  // Transactions simulées
  static const _transactions = [
    _Transaction(time: '14h32', from: 'Sandaga', to: 'Keur Gorgui', amount: '2 300', deliveries: 1),
    _Transaction(time: '11h15', from: 'Plateau', to: 'Mermoz', amount: '1 800', deliveries: 1),
    _Transaction(time: '09h47', from: 'Point E', to: 'Almadies', amount: '3 800', deliveries: 1),
    _Transaction(time: 'Hier', from: 'Sandaga', to: 'Fann', amount: '2 100', deliveries: 1),
    _Transaction(time: 'Hier', from: 'Grand Yoff', to: 'Parcelles', amount: '1 500', deliveries: 1),
  ];

  @override
  Widget build(BuildContext context) {
    final maxData = _currentData.reduce((a, b) => a > b ? a : b);

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
                  0,
                ),
                child: Text('Mes gains', style: AppTextStyles.h3),
              ),
            ),

            // Sélecteur de période
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.screenPadding.w,
                  AppDimens.lg.h,
                  AppDimens.screenPadding.w,
                  0,
                ),
                child: Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: List.generate(_periods.length, (i) {
                      final selected = i == _periodIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _periodIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.all(3.r),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                  AppDimens.radiusSm),
                            ),
                            child: Center(
                              child: Text(
                                _periods[i],
                                style: TextStyle(
                                  fontFamily: 'Archivo',
                                  fontSize: 13.sp,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected
                                      ? AppColors.white
                                      : AppColors.grey500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

            // Carte total
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
                      colors: [Color(0xFF1A1A2E), Color(0xFF0E3BB8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _totalLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      SizedBox(height: AppDimens.sm.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _totalAmount,
                            style: TextStyle(
                              fontFamily: 'Archivo',
                              fontSize: 36.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Padding(
                            padding: EdgeInsets.only(bottom: 5.h),
                            child: Text(
                              'FCFA',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.white
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimens.xl.h),

                      // Mini stats
                      Row(
                        children: [
                          _GainsStat(
                              label: 'Livraisons',
                              value: '5',
                              icon: Icons.local_shipping_outlined),
                          _GainsDivider(),
                          _GainsStat(
                              label: 'Temps actif',
                              value: '4h 20',
                              icon: Icons.access_time_rounded),
                          _GainsDivider(),
                          _GainsStat(
                              label: 'Km parcourus',
                              value: '23.4',
                              icon: Icons.route_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Graphe barres
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.screenPadding.w,
                  AppDimens.lg.h,
                  AppDimens.screenPadding.w,
                  0,
                ),
                child: Container(
                  padding: EdgeInsets.all(AppDimens.lg.r),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusMd),
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
                      Text('Évolution', style: AppTextStyles.labelMedium),
                      SizedBox(height: AppDimens.lg.h),
                      SizedBox(
                        height: 120.h,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            _currentData.length,
                            (i) {
                              final val = _currentData[i];
                              final ratio =
                                  maxData > 0 ? val / maxData : 0.0;
                              final isMax = val == maxData && val > 0;
                              return Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 400),
                                    width: 28.w,
                                    height: 100.h * ratio,
                                    decoration: BoxDecoration(
                                      color: isMax
                                          ? AppColors.primary
                                          : AppColors.primarySurface,
                                      borderRadius:
                                          BorderRadius.circular(6.r),
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    _currentLabels[i],
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Transactions récentes
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.screenPadding.w,
                  AppDimens.xl.h,
                  AppDimens.screenPadding.w,
                  0,
                ),
                child: Text('Transactions récentes',
                    style: AppTextStyles.labelLarge),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.md.h,
                AppDimens.screenPadding.w,
                AppDimens.xl.h,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: EdgeInsets.only(bottom: AppDimens.sm.h),
                    child: _TransactionTile(tx: _transactions[i]),
                  ),
                  childCount: _transactions.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internes ────────────────────────────────────────────

class _GainsStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _GainsStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: 0.6), size: 16.r),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 10.sp,
              color: AppColors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _GainsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36.h,
      color: AppColors.white.withValues(alpha: 0.15),
    );
  }
}

class _Transaction {
  final String time;
  final String from;
  final String to;
  final String amount;
  final int deliveries;
  const _Transaction({
    required this.time,
    required this.from,
    required this.to,
    required this.amount,
    required this.deliveries,
  });
}

class _TransactionTile extends StatelessWidget {
  final _Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppDimens.lg.w, vertical: AppDimens.md.h),
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
          Container(
            width: 42.r,
            height: 42.r,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Icon(Icons.local_shipping_rounded,
                color: AppColors.success, size: 20.r),
          ),
          SizedBox(width: AppDimens.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tx.from} → ${tx.to}',
                  style:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.dark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3.h),
                Text(tx.time, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            '+${tx.amount} FCFA',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}
