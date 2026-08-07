import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../../model/order/mission.dart';
import '../auth/providers/driver_provider.dart';
import '../orders/order_detail_screen.dart';
import '../orders/providers/accept_mission.dart';
import '../orders/providers/orders_provider.dart';
import '../shell/main_shell.dart';
import 'providers/location_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dernière commande arrivée = première de la liste complète
    // (triée par date décroissante, indépendante du filtre Commandes)
    final orders = ref.watch(dashboardOrdersProvider).valueOrNull;
    final latestOrder =
        orders == null || orders.isEmpty ? null : orders.first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // icônes blanches (Android)
        statusBarBrightness: Brightness.dark,       // iOS b
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
                  count: orders?.length ?? 0,
                  onTapAll: () =>
                      ref.read(shellIndexProvider.notifier).state = 1,
                ),
                // La commande sortante glisse vers la gauche, la
                // suivante entre par la droite — comme une pile de
                // cartes qui défile.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final sortante =
                        animation.status == AnimationStatus.reverse;
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(sortante ? -1 : 1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: latestOrder == null
                      ? const SizedBox(
                          key: ValueKey('aucune'), width: double.infinity)
                      : Padding(
                          key: ValueKey(latestOrder.id),
                          padding: EdgeInsets.only(top: 10.h),
                          child: _OrderCard(order: latestOrder),
                        ),
                ),
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
  GoogleMapViewController? _controller;
  Circle? _halo;

  // Dakar par défaut en attendant la position GPS
  static const _fallbackCamera = CameraPosition(
    target: LatLng(latitude: 14.6928, longitude: -17.4467),
    zoom: 12,
  );

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }
// faut verrouiller ta machineeeeeeeeeeeeeeeeeee
  Future<void> _onViewCreated(GoogleMapViewController controller) async {
    _controller = controller;
    // La vue peut être détruite avant que ces appels aboutissent
    // (bascule immédiate vers une mission en cours au démarrage).
    try {
      await controller.setMyLocationEnabled(true);
      if (!mounted) return;
      final loc = ref.read(currentLocationProvider).valueOrNull;
      if (loc != null) await _centerOn(loc.position);
    } catch (e) {
      debugPrint('Carte dashboard indisponible : $e');
    }
  }

  /// Recentre la carte et repositionne le halo autour du livreur.
  Future<void> _centerOn(Position position) async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final target =
        LatLng(latitude: position.latitude, longitude: position.longitude);

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15.5),
        ),
      );

      // Halo bleu autour de la position, pour la rendre bien visible
      if (_halo != null) {
        await controller.removeCircles([_halo!]);
        _halo = null;
      }
      final added = await controller.addCircles([
        CircleOptions(
          position: target,
          radius: 60,
          fillColor: AppColors.info.withValues(alpha: 0.15),
          strokeColor: AppColors.info.withValues(alpha: 0.4),
          strokeWidth: 2,
        ),
      ]);
      if (mounted) _halo = added.isNotEmpty ? added.first : null;
    } catch (e) {
      debugPrint('Carte dashboard indisponible : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recentre la carte quand la position arrive/change
    ref.listen(currentLocationProvider, (previous, next) {
      final loc = next.valueOrNull;
      if (loc != null) _centerOn(loc.position);
    });

    final loc = ref.watch(currentLocationProvider).valueOrNull;
    final initialCamera = loc != null
        ? CameraPosition(
            target: LatLng(
              latitude: loc.position.latitude,
              longitude: loc.position.longitude,
            ),
            zoom: 15.5,
          )
        : _fallbackCamera;

    return GoogleMapsMapView(
      initialCameraPosition: initialCamera,
      onViewCreated: _onViewCreated,
      initialZoomControlsEnabled: false,
      initialCompassEnabled: false,
      initialMapToolbarEnabled: false,
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
class _OrderCard extends ConsumerStatefulWidget {
  final Mission order;
  const _OrderCard({required this.order});

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _isAccepting = false;

  /// Couleurs du badge selon le type de service
  static ({Color bg, Color text}) _catColors(String type) =>
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

  Future<void> _onAccept() async {
    setState(() => _isAccepting = true);
    await acceptMission(context, ref, widget.order.id);
    if (mounted) setState(() => _isAccepting = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final catColor = _catColors(order.typeService);
    final anciennete = order.ancienneteLabel;
    // Distance jusqu'au point de récupération (≠ longueur du trajet)
    final pickupDistance = distanceToPickupLabel(
      order,
      ref.watch(currentLocationProvider).valueOrNull?.position,
    );

    final args = OrderDetailArgs(
      missionId: order.id,
      id: order.code,
      amount: order.montantFormate,
      distance: order.distanceLabel,
      estimatedTime: order.dureeLabel,
      pickup: order.adresseDepart,
      delivery: order.adresseArrivee,
      timerSeconds: 0,
      category: order.typeLabel,
      merchantName: order.typeLabel,
      merchantAddress: order.adresseDepart,
      merchantPhone: '',
      clientName: 'Client',
      clientPhone: '',
      clientNotes: order.instructions,
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
                    order.typeLabel,
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
                    color: AppColors.warningLight,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.timer,
                          size: 11.r, color: AppColors.warning),
                      SizedBox(width: 3.w),
                      Text(
                        anciennete,
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
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
                Text('${order.montantFormate} ${order.devise}',
                    style: AppTextStyles.h4
                        .copyWith(color: AppColors.black)),
                SizedBox(width: AppDimens.sm.w),
                _Dot(),
                SizedBox(width: AppDimens.sm.w),
                Text(order.distanceLabel,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey500)),
                SizedBox(width: AppDimens.sm.w),
                _Dot(),
                SizedBox(width: AppDimens.sm.w),
                Text(order.dureeLabel,
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
                        Text(
                            pickupDistance != null
                                ? 'Départ · $pickupDistance'
                                : 'Départ',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grey500)),
                        SizedBox(height: 2.h),
                        Text(order.adresseDepart,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.dark)),
                        SizedBox(height: 12.h),
                        Text('Arrivée',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.grey500)),
                        SizedBox(height: 2.h),
                        Text(order.adresseArrivee,
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
                    onPressed: _isAccepting
                        ? null
                        : () => refuseMission(ref, order.id),
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
                    onPressed: _isAccepting ? null : _onAccept,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 42.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                    child: _isAccepting
                        ? SizedBox(
                            height: 18.r,
                            width: 18.r,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.white),
                          )
                        : Row(
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

