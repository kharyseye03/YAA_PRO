import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../model/order/mission.dart';
import '../../model/order/nav_route.dart';
import '../../service/maps/navigation_service.dart';
import '../auth/providers/auth_notifier.dart';
import '../home/providers/location_provider.dart';
import '../orders/providers/orders_provider.dart';
import 'providers/active_mission_provider.dart';

/// Écran affiché tant que le livreur a une mission en cours.
/// Phase 1 : trajet vers le point de récupération.
class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  GoogleMapViewController? _mapController;
  bool _framed = false;
  bool _decorated = false;

  /// Guidage turn-by-turn natif Google en cours.
  bool _navigating = false;
  bool _startingNavigation = false;
  bool _confirmingStep = false;

  /// Le SDK a signalé l'arrivée à destination : on met l'action de
  /// l'étape en avant.
  bool _arrived = false;

  final _navService = NavigationService();
  StreamSubscription<OnArrivalEvent>? _arrivalSub;

  @override
  void initState() {
    super.initState();
    // Détection automatique de l'arrivée au point de l'étape
    _arrivalSub = GoogleMapsNavigator.setOnArrivalListener((_) {
      if (mounted) setState(() => _arrived = true);
    });
  }

  @override
  void dispose() {
    _arrivalSub?.cancel();
    if (_navigating) _navService.stopGuidance();
    super.dispose();
  }

  // ── Tracés et cadrage d'ensemble (hors navigation) ────────────
  /// Dessine les marqueurs et les deux tracés sur la carte, puis
  /// cadre la vue sur l'ensemble du trajet.
  Future<void> _decorateMap(
    MissionRoutes routes,
    LatLng? pickup,
    LatLng? dropoff,
  ) async {
    final controller = _mapController;
    if (controller == null || _decorated || _navigating || !mounted) return;
    final points = [...routes.active.polyline, ...routes.preview];
    if (points.isEmpty) return;
    _decorated = true;

    try {
      await controller.addMarkers([
        if (pickup != null)
          MarkerOptions(
            position: pickup,
            infoWindow: const InfoWindow(title: 'Récupération'),
          ),
        if (dropoff != null)
          MarkerOptions(
            position: dropoff,
            infoWindow: const InfoWindow(title: 'Livraison'),
          ),
      ]);

      await controller.addPolylines([
        // Aperçu du trajet de la course (étape 1 seulement)
        if (routes.preview.isNotEmpty)
          PolylineOptions(
            points: routes.preview,
            strokeColor: AppColors.grey500,
            strokeWidth: 5,
          ),
        // Étape en cours : ma position → destination du moment
        if (routes.active.polyline.isNotEmpty)
          PolylineOptions(
            points: routes.active.polyline,
            strokeColor: AppColors.primary,
            strokeWidth: 8,
          ),
      ]);

      await _frameRoute(points);
    } catch (e) {
      debugPrint('Carte mission indisponible : $e');
      _decorated = false;
    }
  }

  Future<void> _frameRoute(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty || _framed || _navigating) {
      return;
    }
    _framed = true;

    var minLat = points.first.latitude, maxLat = points.first.latitude;
    var minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(latitude: minLat, longitude: minLng),
          northeast: LatLng(latitude: maxLat, longitude: maxLng),
        ),
        padding: 60,
      ),
    );
  }

  // ── Navigation turn-by-turn ───────────────────────────────────
  Future<void> _startNavigation(LatLng destination, String title) async {
    setState(() => _startingNavigation = true);
    final result = await _navService.startGuidanceTo(
      latitude: destination.latitude,
      longitude: destination.longitude,
      title: title,
    );
    if (!mounted) return;

    setState(() {
      _startingNavigation = false;
      _navigating = result == NavStartResult.ok;
    });
    if (result != NavStartResult.ok) {
      _toast(NavigationService.messageFor(result));
    }
  }

  Future<void> _stopNavigation() async {
    await _navService.stopGuidance();
    if (!mounted) return;
    setState(() {
      _navigating = false;
      _framed = false; // recadrera sur l'ensemble du trajet
    });
  }

  // ── Actions ───────────────────────────────────────────────────
  Future<void> _openExternalMaps(double lat, double lng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _toast('Impossible d\'ouvrir Google Maps.');
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (!await launchUrl(uri)) {
      if (mounted) _toast('Impossible de lancer l\'appel.');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.dark),
    );
  }

  /// Confirme la récupération du colis puis bascule le guidage vers
  /// le point de livraison.
  Future<void> _onPickedUp(int missionId) async {
    setState(() => _confirmingStep = true);
    try {
      await ref.read(apiServiceProvider).pickupMission(missionId);
      if (_navigating) await _stopNavigation();
      // Le nouveau statut fait basculer l'écran sur l'étape 2
      _decorated = false;
      _framed = false;
      _arrived = false;
      ref.invalidate(activeMissionProvider);
      if (mounted) {
        _toast('Colis récupéré — direction le point de livraison.');
      }
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _confirmingStep = false);
    }
  }

  /// Clôture la mission puis ramène le livreur au tableau de bord.
  Future<void> _onDelivered(Mission mission) async {
    setState(() => _confirmingStep = true);
    try {
      await ref.read(apiServiceProvider).deliverMission(mission.id);
      if (_navigating) await _stopNavigation();
      await _finishMission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Course terminée · +${mission.montantFormate} ${mission.devise}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _confirmingStep = false);
    }
  }

  /// Libère la mission en cours : l'app revient au tableau de bord et
  /// les listes de commandes se rafraîchissent.
  Future<void> _finishMission() async {
    await ref.read(activeMissionIdProvider.notifier).finish();
    ref.invalidate(allOrdersProvider);
    ref.invalidate(availableOrdersProvider);
  }

  /// ⏳ Temporaire : sortie de secours pendant les tests, tant que
  /// l'endpoint « livrer » n'existe pas.
  Future<void> _quitForTesting() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la mission ?'),
        content: const Text(
            'Uniquement pour les tests : la mission reste assignée côté '
            'serveur, elle disparaît seulement de cet écran.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(activeMissionIdProvider.notifier).finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionAsync = ref.watch(activeMissionProvider);
    final routes = ref.watch(activeRouteProvider).valueOrNull ??
        (active: NavRoute.empty, preview: <LatLng>[]);
    final me = ref.watch(currentLocationProvider).valueOrNull?.position;


    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: missionAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorState(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(activeMissionProvider),
          onQuit: _quitForTesting,
        ),
        data: (mission) {
          if (mission == null) {
            return const Center(child: Text('Aucune mission en cours.'));
          }

          // Terminée ou annulée côté serveur : on rend la main au
          // tableau de bord sans laisser le livreur bloqué ici.
          if (mission.isFinished) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _finishMission());
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }

          final pickup = mission.latitudeDepart != null &&
                  mission.longitudeDepart != null
              ? LatLng(
                  latitude: mission.latitudeDepart!,
                  longitude: mission.longitudeDepart!)
              : null;
          final dropoff = mission.latitudeArrivee != null &&
                  mission.longitudeArrivee != null
              ? LatLng(
                  latitude: mission.latitudeArrivee!,
                  longitude: mission.longitudeArrivee!)
              : null;
          // Destination de l'étape en cours (récupération ou livraison)
          final destination = activeDestinationOf(mission);

          // Tracés dessinés dès que l'itinéraire est disponible
          if (!_navigating) {
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _decorateMap(routes, pickup, dropoff));
          }

          // ── Guidage natif Google : vue plein écran du SDK ──
          if (_navigating) {
            return Stack(
              children: [
                Positioned.fill(
                  child: GoogleMapsNavigationView(
                    onViewCreated: (controller) {
                      // On garde l'en-tête (instructions) et on masque
                      // le pied de page : notre panneau prend la place.
                      controller
                          .setNavigationFooterEnabled(false)
                          .catchError(
                              (e) => debugPrint('Vue navigation : $e'));
                    },
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12.h,
                  right: AppDimens.screenPadding.w,
                  child: GestureDetector(
                    onTap: _stopNavigation,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(LucideIcons.x,
                          size: 18.r, color: AppColors.dark),
                    ),
                  ),
                ),
                // ⏳ Test : simule le trajet sans se déplacer
                if (kDebugMode)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12.h,
                    left: AppDimens.screenPadding.w,
                    child: GestureDetector(
                      onTap: () async {
                        await _navService.startSimulation();
                        if (mounted) {
                          _toast('Simulation lancée (vitesse ×5)');
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusFull),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.20),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.play,
                                size: 13.r, color: AppColors.dark),
                            SizedBox(width: 5.w),
                            Text('Simuler',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.dark)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _NavigatingPanel(
                    mission: mission,
                    arrived: _arrived,
                    busy: _confirmingStep,
                    onStepAction: mission.isPickedUp
                        ? () => _onDelivered(mission)
                        : () => _onPickedUp(mission.id),
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              // ── Carte ────────────────────────────────────────
              Positioned.fill(
                child: GoogleMapsMapView(
                  initialCameraPosition: CameraPosition(
                    target: pickup ??
                        (me != null
                            ? LatLng(
                                latitude: me.latitude,
                                longitude: me.longitude)
                            : const LatLng(
                                latitude: 14.6928, longitude: -17.4467)),
                    zoom: 14,
                  ),
                  onViewCreated: (c) {
                    _mapController = c;
                    c.setMyLocationEnabled(true).catchError(
                        (e) => debugPrint('Carte mission : $e'));
                  },
                  initialZoomControlsEnabled: false,
                  initialCompassEnabled: false,
                  initialMapToolbarEnabled: false,
                ),
              ),

              // ── Bandeau haut ─────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _TopBar(
                  code: mission.code,
                  onQuit: _quitForTesting,
                ),
              ),

              // ── Panneau bas ──────────────────────────────────
              Align(
                alignment: Alignment.bottomCenter,
                child: _MissionPanel(
                  mission: mission,
                  isStartingNavigation: _startingNavigation,
                  busy: _confirmingStep,
                  onNavigate: destination == null
                      ? null
                      : () => _startNavigation(
                          destination, mission.currentAddress),
                  onExternalMaps: destination == null
                      ? null
                      : () => _openExternalMaps(
                          destination.latitude, destination.longitude),
                  onCall: _call,
                  onStepAction: mission.isPickedUp
                      ? () => _onDelivered(mission)
                      : () => _onPickedUp(mission.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Libellé du bouton d'action selon l'étape et le type de mission.
String stepActionLabel(Mission mission) {
  if (mission.isPickedUp) {
    return mission.isLivraison ? 'J\'ai livré le colis' : 'Course terminée';
  }
  return mission.isLivraison ? 'J\'ai récupéré le colis' : 'J\'ai récupéré';
}

// ── Barre basse compacte pendant le guidage ───────────────────────
class _NavigatingPanel extends StatelessWidget {
  final Mission mission;
  final bool arrived;
  final bool busy;
  final VoidCallback onStepAction;

  const _NavigatingPanel({
    required this.mission,
    required this.arrived,
    required this.busy,
    required this.onStepAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.lg.w,
        AppDimens.lg.h,
        AppDimens.lg.w,
        MediaQuery.of(context).padding.bottom + AppDimens.lg.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Le SDK a détecté l'arrivée : on invite à valider l'étape
          if (arrived) ...[
            Row(
              children: [
                Icon(LucideIcons.checkCircle2,
                    size: 15.r, color: AppColors.success),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    mission.isPickedUp
                        ? 'Vous êtes arrivé chez le destinataire'
                        : 'Vous êtes arrivé au point de récupération',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimens.md.h),
          ],
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight.h,
            child: ElevatedButton(
              onPressed: busy ? null : onStepAction,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    arrived ? AppColors.success : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              child: busy
                  ? SizedBox(
                      height: 20.r,
                      width: 20.r,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.packageCheck, size: 18.r),
                        SizedBox(width: 8.w),
                        Text(
                          stepActionLabel(mission),
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bandeau supérieur (hors guidage) ──────────────────────────────
class _TopBar extends StatelessWidget {
  final String code;
  final VoidCallback onQuit;

  const _TopBar({required this.code, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10.h,
        left: AppDimens.screenPadding.w,
        right: AppDimens.screenPadding.w,
        bottom: 12.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.dark.withValues(alpha: 0.55),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7.r,
                  height: 7.r,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  code,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.dark),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Sortie de secours réservée aux tests
          if (kDebugMode)
            GestureDetector(
              onTap: onQuit,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.x,
                    size: 17.r, color: AppColors.grey600),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Panneau d'information et d'action (hors guidage) ──────────────
class _MissionPanel extends StatelessWidget {
  final Mission mission;
  final bool isStartingNavigation;
  final VoidCallback? onNavigate;
  final VoidCallback? onExternalMaps;
  final void Function(String phone) onCall;
  final bool busy;
  final VoidCallback onStepAction;

  const _MissionPanel({
    required this.mission,
    required this.isStartingNavigation,
    required this.busy,
    required this.onNavigate,
    required this.onExternalMaps,
    required this.onCall,
    required this.onStepAction,
  });

  /// Interlocuteur de l'étape en cours : expéditeur avant la
  /// récupération, destinataire pendant la livraison.
  ({String label, String? name, String? phone}) get _contact {
    if (!mission.isLivraison) {
      return (
        label: 'Client',
        name: mission.customerFullName,
        phone: mission.customerTelephone,
      );
    }
    if (mission.isPickedUp) {
      return (
        label: 'Destinataire',
        name: null,
        phone: mission.telephoneDestinataire,
      );
    }
    return (
      label: 'Expéditeur',
      name: mission.customerFullName,
      phone: mission.telephoneExpediteur ?? mission.customerTelephone,
    );
  }

  /// 773809954 → 77 380 99 54
  static String formatPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 9) return raw;
    return '${d.substring(0, 2)} ${d.substring(2, 5)} '
        '${d.substring(5, 7)} ${d.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contact;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppDimens.lg.w,
        AppDimens.lg.h,
        AppDimens.lg.w,
        MediaQuery.of(context).padding.bottom + AppDimens.lg.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Étape + montant
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    mission.isPickedUp
                        ? 'Étape 2 sur 2 · Livraison'
                        : 'Étape 1 sur 2 · Récupération',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${mission.montantFormate} ${mission.devise}',
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.dark),
                ),
              ],
            ),
            SizedBox(height: AppDimens.lg.h),

            // Adresse de récupération
            _InfoBlock(
              icon: LucideIcons.mapPin,
              iconColor: AppColors.secondary,
              label: mission.isPickedUp ? 'Livrer à' : 'Récupérer à',
              value: mission.currentAddress,
              actionLabel: isStartingNavigation ? '...' : 'Y aller',
              actionIcon: LucideIcons.navigation,
              onAction: isStartingNavigation ? null : onNavigate,
            ),

            // Repli vers Google Maps pour le guidage vocal
            if (onExternalMaps != null)
              Padding(
                padding: EdgeInsets.only(left: 50.w, top: 4.h),
                child: GestureDetector(
                  onTap: onExternalMaps,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.externalLink,
                          size: 12.r, color: AppColors.grey500),
                      SizedBox(width: 4.w),
                      Text(
                        'Ouvrir dans Google Maps',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
              ),

            if (contact.phone != null && contact.phone!.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimens.md.h),
                child: Divider(height: 1, color: AppColors.grey200),
              ),
              _InfoBlock(
                icon: LucideIcons.user,
                iconColor: AppColors.primary,
                label: contact.label,
                value: contact.name?.isNotEmpty == true
                    ? '${contact.name}\n${formatPhone(contact.phone!)}'
                    : formatPhone(contact.phone!),
                actionLabel: 'Appeler',
                actionIcon: LucideIcons.phone,
                onAction: () => onCall(contact.phone!),
              ),
            ],

            if (mission.instructions.isNotEmpty) ...[
              SizedBox(height: AppDimens.md.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppDimens.md.r),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Text(
                  mission.instructions,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey800),
                ),
              ),
            ],

            SizedBox(height: AppDimens.lg.h),

            // Action principale
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight.h,
              child: ElevatedButton(
                onPressed: busy ? null : onStepAction,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.packageCheck, size: 18.r),
                    SizedBox(width: 8.w),
                    Text(
                      stepActionLabel(mission),
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bloc d'information avec action ────────────────────────────────
class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  const _InfoBlock({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Icon(icon, size: 18.r, color: iconColor),
        ),
        SizedBox(width: AppDimens.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey500)),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.dark),
              ),
            ],
          ),
        ),
        SizedBox(width: AppDimens.sm.w),
        OutlinedButton(
          onPressed: onAction,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.dark,
            side: const BorderSide(color: AppColors.grey300),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            minimumSize: Size(0, 38.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(actionIcon, size: 14.r, color: AppColors.dark),
              SizedBox(width: 5.w),
              Text(
                actionLabel,
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Erreur de chargement ──────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.xl.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.wifiOff, size: 44.r, color: AppColors.grey300),
            SizedBox(height: AppDimens.lg.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.grey500),
            ),
            SizedBox(height: AppDimens.lg.h),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
            TextButton(
              onPressed: onQuit,
              child: Text('Quitter la mission',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey500)),
            ),
          ],
        ),
      ),
    );
  }
}
