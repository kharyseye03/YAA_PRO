import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/map_marker.dart';
import '../../core/widgets/slide_to_confirm.dart';
import '../../model/order/mission.dart';
import '../../model/order/mission_labels.dart';
import '../../model/order/nav_route.dart';
import '../../service/maps/navigation_service.dart';
import '../auth/providers/auth_notifier.dart';
import '../home/providers/location_provider.dart';
import '../orders/providers/orders_provider.dart';
import '../orders/widgets/produits_commande_block.dart';
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

  /// Les marqueurs ne dépendent que de la mission : ils sont posés dès
  /// que la carte est prête. Le tracé, lui, attend l'itinéraire et peut
  /// donc arriver plus tard — ou jamais si l'API est indisponible.
  bool _markersDrawn = false;
  bool _routeDrawn = false;

  /// Guidage turn-by-turn natif Google en cours.
  bool _navigating = false;
  bool _startingNavigation = false;
  bool _confirmingStep = false;

  /// Le SDK a signalé l'arrivée à destination : on met l'action de
  /// l'étape en avant.
  bool _arrived = false;

  /// On quitte l'écran : plus aucune vue carte n'est construite.
  ///
  /// Le plugin plante (« GoogleMap not initialized yet ») si une vue
  /// carte est détruite avant d'avoir fini de s'initialiser, ce qui
  /// arrive quand on arrête le guidage juste avant de sortir.
  bool _closing = false;

  final _navService = NavigationService();
  StreamSubscription<OnArrivalEvent>? _arrivalSub;

  /// Marqueurs personnalisés, préparés une seule fois.
  Future<({ImageDescriptor depart, ImageDescriptor arrivee})>? _markerIcons;

  @override
  void initState() {
    super.initState();
    // Détection automatique de l'arrivée au point de l'étape
    _arrivalSub = GoogleMapsNavigator.setOnArrivalListener((_) {
      if (mounted) setState(() => _arrived = true);
    });
    _markerIcons = _loadMarkerIcons();
  }

  Future<({ImageDescriptor depart, ImageDescriptor arrivee})>
      _loadMarkerIcons() async {
    final depart = await createMarkerImage(
        AppColors.dark, Icons.location_on_outlined);
    final arrivee = await createMarkerImage(
        AppColors.secondary, Icons.location_on_outlined);
    return (depart: depart, arrivee: arrivee);
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
    if (controller == null || _navigating || !mounted) return;

    final tracePoints = [...routes.active.polyline, ...routes.preview];
    final etapes = [
      if (pickup != null) pickup,
      if (dropoff != null) dropoff,
    ];
    if (tracePoints.isEmpty && etapes.isEmpty) return;

    try {
      // Les repères viennent des coordonnées de la mission : ils
      // s'affichent même quand l'itinéraire est indisponible.
      if (!_markersDrawn && etapes.isNotEmpty) {
        _markersDrawn = true;
        final icons = await _markerIcons;
        await controller.addMarkers([
          if (pickup != null)
            MarkerOptions(
              position: pickup,
              icon: icons?.depart ?? ImageDescriptor.defaultImage,
              anchor: const MarkerAnchor(u: 0.5, v: 1),
              infoWindow: const InfoWindow(title: 'Récupération'),
            ),
          if (dropoff != null)
            MarkerOptions(
              position: dropoff,
              icon: icons?.arrivee ?? ImageDescriptor.defaultImage,
              anchor: const MarkerAnchor(u: 0.5, v: 1),
              infoWindow: const InfoWindow(title: 'Livraison'),
            ),
        ]);
      }

      if (!_routeDrawn && tracePoints.isNotEmpty) {
        _routeDrawn = true;
        await controller.addPolylines([
          // Aperçu du trajet de la course (étape 1 seulement)
          if (routes.preview.isNotEmpty)
            PolylineOptions(
              points: routes.preview,
              strokeColor: AppColors.primary,
              strokeWidth: 5,
              strokeJointType: StrokeJointType.round,
            ),
          // Étape en cours : ma position → destination du moment
          if (routes.active.polyline.isNotEmpty)
            PolylineOptions(
              points: routes.active.polyline,
              strokeColor: AppColors.dark,
              strokeWidth: 6,
              strokeJointType: StrokeJointType.round,
            ),
        ]);
      }

      // À défaut d'itinéraire, on cadre sur les deux points d'étape :
      // le livreur voit où il doit aller, même sans tracé.
      await _frameRoute(tracePoints.isNotEmpty ? tracePoints : etapes);
    } catch (e) {
      debugPrint('Carte mission indisponible : $e');
      _markersDrawn = false;
      _routeDrawn = false;
    }
  }

  /// Efface repères et tracés avant de redessiner l'étape suivante :
  /// `addMarkers` empile sans remplacer, on se retrouverait sinon avec
  /// les marqueurs de l'étape 1 sous ceux de l'étape 2.
  Future<void> _resetMapOverlays() async {
    _markersDrawn = false;
    _routeDrawn = false;
    _framed = false;
    final controller = _mapController;
    if (controller == null) return;
    try {
      await controller.clearMarkers();
      await controller.clearPolylines();
    } catch (e) {
      debugPrint('Nettoyage de la carte : $e');
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
      // Le nouveau statut fait basculer l'écran sur l'étape 2 :
      // le guidage repartira vers le point de livraison
      if (_navigating) {
        await _navService.stopGuidance();
        if (mounted) setState(() => _navigating = false);
      }
      await _resetMapOverlays();
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
      await _leaveScreen();
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

  /// Quitte proprement l'écran : la carte est d'abord retirée de
  /// l'arbre, puis le guidage arrêté, puis la mission libérée.
  Future<void> _leaveScreen() async {
    if (mounted) setState(() => _closing = true);
    if (_navigating) {
      await _navService.stopGuidance();
      _navigating = false;
    }
    await _finishMission();
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
    if (confirmed == true) await _leaveScreen();
  }

  @override
  Widget build(BuildContext context) {
    // Sortie en cours : aucune vue carte tant que l'écran vit encore
    if (_closing) {
      return const Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

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
                .addPostFrameCallback((_) => _leaveScreen());
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
                if (!kReleaseMode)
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

              // ── Panneau bas fixe ─────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _MissionPanel(
                  mission: mission,
                  route: routes.active,
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
                    MissionLabels.of(mission).arrivalMessage,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimens.md.h),
          ],
          SlideToConfirm(
            label: MissionLabels.of(mission).actionButton,
            icon: LucideIcons.packageCheck,
            color: mission.isPickedUp
                ? AppColors.success
                : AppColors.secondary,
            busy: busy,
            onConfirm: onStepAction,
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
          if (!kReleaseMode)
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
  final NavRoute route;
  final bool isStartingNavigation;
  final VoidCallback? onNavigate;
  final VoidCallback? onExternalMaps;
  final void Function(String phone) onCall;
  final bool busy;
  final VoidCallback onStepAction;

  const _MissionPanel({
    required this.mission,
    required this.route,
    required this.isStartingNavigation,
    required this.busy,
    required this.onNavigate,
    required this.onExternalMaps,
    required this.onCall,
    required this.onStepAction,
  });

  /// Interlocuteur de l'étape en cours, selon le type de service.
  ({String label, String? name, String? phone}) get _contact => (
        label: MissionLabels.of(mission).contactLabel,
        name: MissionLabels.contactNameOf(mission),
        phone: MissionLabels.contactPhoneOf(mission),
      );

  /// 622123456 → 622 12 34 56
  static String formatPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 9) return raw;
    return '${d.substring(0, 3)} ${d.substring(3, 5)} '
        '${d.substring(5, 7)} ${d.substring(7)}';
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contact;
    // Orange tant qu'il va récupérer, vert quand il va livrer
    final accent =
        mission.isPickedUp ? AppColors.success : AppColors.secondary;

    return Container(
      width: double.infinity,
      // Le panneau ne se déplie plus : sa hauteur suit son contenu.
      // Le plafond n'est là que pour les missions très bavardes
      // (instructions longues), où le contenu défile sur place.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.62,
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
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(AppDimens.lg.w, AppDimens.lg.h,
                  AppDimens.lg.w, AppDimens.md.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Progression : deux segments, colorés selon l'étape
            _StepProgress(isPickedUp: mission.isPickedUp, accent: accent),
            SizedBox(height: AppDimens.md.h),

            // Étape en cours + montant mis en avant
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    mission.isPickedUp ? 'LIVRAISON' : 'RÉCUPÉRATION',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Text(
                  mission.montantFormate,
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                    height: 1,
                  ),
                ),
                SizedBox(width: 4.w),
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text(
                    mission.devise,
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.grey600),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimens.lg.h),

            // Adresse de l'étape en cours
            _InfoBlock(
              icon: LucideIcons.mapPin,
              iconColor: accent,
              label: MissionLabels.of(mission).addressLabel,
              value: mission.currentAddress,
              actionLabel: isStartingNavigation ? '...' : 'Démarrer',
              actionIcon: LucideIcons.navigation,
              onAction: isStartingNavigation ? null : onNavigate,
            ),

            // Temps et distance jusqu'à la destination de l'étape
            if (!route.isEmpty)
              Padding(
                padding: EdgeInsets.only(left: 54.w, top: 6.h),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock,
                        size: 14.r, color: AppColors.dark),
                    SizedBox(width: 5.w),
                    Text(
                      '${route.durationLabel} · ${route.distanceLabel}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.dark),
                    ),
                  ],
                ),
              ),

            // Repli vers Google Maps pour le guidage vocal
            if (onExternalMaps != null)
              Padding(
                padding: EdgeInsets.only(left: 54.w, top: 4.h),
                child: GestureDetector(
                  onTap: onExternalMaps,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.externalLink,
                          size: 13.r, color: AppColors.grey600),
                      SizedBox(width: 4.w),
                      Text(
                        'Ouvrir dans Google Maps',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.grey600),
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
              _ContactBlock(
                label: contact.label,
                name: contact.name,
                phone: formatPhone(contact.phone!),
                accent: accent,
                onCall: () => onCall(contact.phone!),
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

            // Ce qu'il y a à récupérer chez le commerçant. Inutile une
            // fois la commande en main : à l'étape 2 le coursier livre.
            if (!mission.isPickedUp &&
                mission.commandeStructureId != null) ...[
              SizedBox(height: AppDimens.md.h),
              ProduitsCommandeBlock(
                commandeStructureId: mission.commandeStructureId!,
                accent: accent,
              ),
            ],

                ],
              ),
            ),
          ),

          // ── Action principale, toujours visible ────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.lg.w,
              0,
              AppDimens.lg.w,
              MediaQuery.of(context).padding.bottom + AppDimens.md.h,
            ),
            child: SlideToConfirm(
              label: MissionLabels.of(mission).actionButton,
              icon: LucideIcons.packageCheck,
              color: accent,
              busy: busy,
              onConfirm: onStepAction,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progression de la mission ─────────────────────────────────────
class _StepProgress extends StatelessWidget {
  final bool isPickedUp;
  final Color accent;

  const _StepProgress({required this.isPickedUp, required this.accent});

  @override
  Widget build(BuildContext context) {
    Widget segment(bool rempli) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 5.h,
            decoration: BoxDecoration(
              color: rempli ? accent : AppColors.grey200,
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
        );

    return Row(
      children: [
        segment(true),
        SizedBox(width: 6.w),
        segment(isPickedUp),
      ],
    );
  }
}

// ── Interlocuteur de l'étape ──────────────────────────────────────
class _ContactBlock extends StatelessWidget {
  final String label;
  final String? name;
  final String phone;
  final Color accent;
  final VoidCallback onCall;

  const _ContactBlock({
    required this.label,
    required this.name,
    required this.phone,
    required this.accent,
    required this.onCall,
  });

  /// « Khary SEYE » → « KS »
  String get _initiales {
    final mots = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((m) => m.isEmpty);
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first[0].toUpperCase();
    return (mots.first[0] + mots.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final aUnNom = name?.isNotEmpty == true;

    return Row(
      children: [
        Container(
          width: 44.r,
          height: 44.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: aUnNom
              ? Text(
                  _initiales,
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                )
              : Icon(LucideIcons.user, size: 20.r, color: accent),
        ),
        SizedBox(width: AppDimens.md.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey600)),
              SizedBox(height: 1.h),
              Text(
                aUnNom ? name! : phone,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.dark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (aUnNom)
                Text(phone,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey700)),
            ],
          ),
        ),
        SizedBox(width: AppDimens.sm.w),
        // Appeler : cible large, atteignable au pouce
        GestureDetector(
          onTap: onCall,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
              color: AppColors.dark,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.phone,
                size: 19.r, color: AppColors.white),
          ),
        ),
      ],
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
        // Lancer le guidage est l'action la plus fréquente de l'écran :
        // bouton plein, à la couleur de l'étape, pour qu'il saute aux yeux
        ElevatedButton(
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: iconColor,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: iconColor.withValues(alpha: 0.45),
            disabledForegroundColor: AppColors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            minimumSize: Size(0, 44.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(actionIcon, size: 16.r, color: AppColors.white),
              SizedBox(width: 6.w),
              Text(
                actionLabel,
                style: TextStyle(
                  fontFamily: 'Archivo',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
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
