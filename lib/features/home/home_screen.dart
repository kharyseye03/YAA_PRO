import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../../model/order/commande_livraison.dart';
import '../auth/providers/driver_provider.dart';
import '../orders/order_detail_screen.dart';
import '../orders/providers/orders_provider.dart';
import '../shell/main_shell.dart';
import 'providers/location_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dernière commande arrivée = id le plus élevé
    final orders = ref.watch(availableOrdersProvider).valueOrNull;
    final latestOrder = orders == null || orders.isEmpty
        ? null
        : orders.reduce((a, b) => a.id > b.id ? a : b);

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
          const Positioned.fill(
            child: _DashboardMap(),
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
                  count: ref
                          .watch(availableOrdersProvider)
                          .valueOrNull
                          ?.length ??
                      0,
                  onTapAll: () =>
                      ref.read(shellIndexProvider.notifier).state = 1,
                ),
                if (latestOrder != null) ...[
                  SizedBox(height: 10.h),
                  _OrderCard(order: latestOrder),
                ],
              ],
            ),
          ),
        ],
      ),
    )); // AnnotatedRegion
  }
}

// ── Carte Google Maps du dashboard ──────────────────────────────
class _DashboardMap extends ConsumerStatefulWidget {
  const _DashboardMap();

  @override
  ConsumerState<_DashboardMap> createState() => _DashboardMapState();
}

class _DashboardMapState extends ConsumerState<_DashboardMap> {
  GoogleMapController? _controller;

  // Dakar par défaut en attendant la position GPS
  static const _fallbackCamera = CameraPosition(
    target: LatLng(14.6928, -17.4467),
    zoom: 12,
  );

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recentre la carte quand la position arrive/change
    ref.listen(currentLocationProvider, (previous, next) {
      final loc = next.valueOrNull;
      if (loc != null && _controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target:
                  LatLng(loc.position.latitude, loc.position.longitude),
              zoom: 15.5,
            ),
          ),
        );
      }
    });

    final loc = ref.watch(currentLocationProvider).valueOrNull;
    final target = loc != null
        ? LatLng(loc.position.latitude, loc.position.longitude)
        : null;
    final initialCamera = target != null
        ? CameraPosition(target: target, zoom: 15.5)
        : _fallbackCamera;

    return GoogleMap(
      initialCameraPosition: initialCamera,
      onMapCreated: (controller) => _controller = controller,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      buildingsEnabled: false,
      // ── Position bien visible : pin bleu + halo ──
      markers: {
        if (target != null)
          Marker(
            markerId: const MarkerId('me'),
            position: target,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            anchor: const Offset(0.5, 1),
          ),
      },
      circles: {
        if (target != null)
          Circle(
            circleId: const CircleId('me_halo'),
            center: target,
            radius: 60,
            fillColor: AppColors.info.withValues(alpha: 0.15),
            strokeColor: AppColors.info.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
      },
    );
  }
}

// ── Header dark (couleur bottom nav) ───────────────────────────
class _HomeHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = ref.watch(driverDetailProvider).valueOrNull;
    final greeting =
        driver != null ? 'Bonjour, ${driver.firstName} 👋' : 'Bonjour 👋';
    final location = ref.watch(currentLocationProvider);
    final locationLabel = location.when(
      data: (loc) => loc.label,
      loading: () => 'Localisation...',
      error: (_, __) => 'Position indisponible',
    );

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
                  greeting,
                  style: AppTextStyles.h4.copyWith(color: AppColors.white),
                ),
                SizedBox(height: 4.h),
                GestureDetector(
                  onTap: () => ref.invalidate(currentLocationProvider),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Icon(LucideIcons.mapPin,
                          color: AppColors.white, size: 13.r),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                              color:
                                  AppColors.white.withValues(alpha: 0.6)),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(LucideIcons.chevronDown,
                          color: AppColors.white.withValues(alpha: 0.6),
                          size: 12.r),
                    ],
                  ),
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
  final int count;
  final VoidCallback onTapAll;
  const _FloatingRow({required this.count, required this.onTapAll});

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
          if (count > 0)
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Text(
                '$count',
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
  final CommandeLivraison order;
  const _OrderCard({required this.order});

  // ⏳ En attendant que le back fournisse ces champs
  static const _mockAmount = '2 300';
  static const _mockDistance = '3.2 km';
  static const _mockTime = '12 min';
  static const _mockTimerSeconds = 45;
  static const _mockCategory = 'Restaurant';

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
                Text('$_mockAmount FCFA',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.black)),
                SizedBox(width: AppDimens.sm.w),
                _Dot(),
                SizedBox(width: AppDimens.sm.w),
                Text(_mockDistance,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500)),
                SizedBox(width: AppDimens.sm.w),
                _Dot(),
                SizedBox(width: AppDimens.sm.w),
                Text(_mockTime,
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

