import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/api/api_config.dart';
import '../../core/constants/constants.dart';
import 'providers/accept_mission.dart';
import 'providers/orders_provider.dart';
import 'widgets/produits_commande_block.dart';

// ── Données de la commande ──────────────────────────────────────
class OrderDetailArgs {
  /// Identifiant technique de la mission (pour l'acceptation)
  final int missionId;
  final String id;
  final String amount;
  final String distance;
  final String estimatedTime;
  final String pickup;
  final String delivery;
  final int timerSeconds;
  final String category;
  // Établissement (point de récupération)
  final String? merchantName;
  final String? merchantAddress;
  final String? merchantPhone;
  // Client (point de livraison)
  final String? clientName;
  final String? clientPhone;
  final String? clientNotes;

  const OrderDetailArgs({
    this.missionId = 0,
    required this.id,
    required this.amount,
    required this.distance,
    required this.estimatedTime,
    required this.pickup,
    required this.delivery,
    required this.timerSeconds,
    required this.category,
    this.merchantName,
    this.merchantAddress,
    this.merchantPhone,
    this.clientName,
    this.clientPhone,
    this.clientNotes,
  });
}

// ── Mock utilisé quand aucune donnée n'est passée ───────────────
const _mockOrder = OrderDetailArgs(
  id: '#CMD-2024-001',
  amount: '2 300',
  distance: '3.2 km',
  estimatedTime: '12 min',
  pickup: 'Marché Sandaga',
  delivery: 'Cité Keur Gorgui',
  timerSeconds: 45,
  category: 'Restaurant',
  merchantName: 'Chez Fatou Restaurant',
  merchantAddress: 'Marché Sandaga, Plateau, Dakar',
  merchantPhone: '+221 33 821 45 67',
  clientName: 'Aissatou Diallo',
  clientPhone: '+221 77 456 78 90',
  clientNotes: 'Appeler à l\'arrivée. Code portail : 1234',
);

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderDetailArgs? order;
  const OrderDetailScreen({super.key, this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() =>
      _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _isAccepting = false;

  OrderDetailArgs? get order => widget.order;

  Future<void> _onAccept(int missionId) async {
    setState(() => _isAccepting = true);
    final success = await acceptMission(context, ref, missionId);
    if (!mounted) return;
    setState(() => _isAccepting = false);
    if (success) Navigator.of(context).pop();
  }

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
    final o = order ?? _mockOrder;
    final mins = o.timerSeconds ~/ 60;
    final secs = o.timerSeconds % 60;
    final timerStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
    final timerUrgent = o.timerSeconds < 60;
    final catColor = _catColors(o.category);

    // Contacts, commerçant et instructions ne figurent que dans le
    // détail de la mission : on le charge en plus de la liste.
    final detail = o.missionId == 0
        ? null
        : ref.watch(missionDetailProvider(o.missionId)).valueOrNull;
    final structure = detail?.structure;

    final pickupName = structure?.nom ??
        (detail?.telephoneExpediteur != null ? 'Expéditeur' : null);
    final pickupPhone =
        structure?.telephone ?? detail?.telephoneExpediteur;

    final clientName = detail?.customerFullName;
    final clientPhone =
        detail?.telephoneDestinataire ?? detail?.customerTelephone;

    final instructions = detail?.instructions;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Corps scrollable ──────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Map banner ─────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260.h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/map2.png',
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay bas → transparent
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.scaffold.withValues(alpha: 0.95),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Timer badge centré en bas du banner
                      Positioned(
                        bottom: 16.h,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 7.h),
                            decoration: BoxDecoration(
                              color: timerUrgent
                                  ? AppColors.errorLight
                                  : AppColors.warningLight,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusFull),
                              border: Border.all(
                                color: timerUrgent
                                    ? AppColors.error.withValues(alpha: 0.3)
                                    : AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.timer,
                                    size: 13.r,
                                    color: timerUrgent
                                        ? AppColors.error
                                        : AppColors.warning),
                                SizedBox(width: 5.w),
                                Text(
                                  'Expire dans $timerStr',
                                  style: TextStyle(
                                    fontFamily: 'Archivo',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: timerUrgent
                                        ? AppColors.error
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── White content card ──────────────────────────
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, -20.h),
                  child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.scaffold,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: AppDimens.lg.h),

                      // ── Catégorie + ID ──────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDimens.screenPadding.w),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: catColor.bg,
                                borderRadius: BorderRadius.circular(
                                    AppDimens.radiusFull),
                              ),
                              child: Text(
                                o.category,
                                style: TextStyle(
                                  fontFamily: 'Archivo',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: catColor.text,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              o.id,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.grey500),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDimens.sm.h),

                      // ── Montant ─────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDimens.screenPadding.w),
                        child: Text(
                          '${o.amount} GNF',
                          style: TextStyle(
                            fontFamily: 'Archivo',
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimens.sm.h),

                      // ── Distance + Temps ────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppDimens.screenPadding.w),
                        child: Row(
                          children: [
                            _InfoPill(
                              icon: LucideIcons.mapPin,
                              label: o.distance,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: AppDimens.sm.w),
                            _InfoPill(
                              icon: LucideIcons.clock,
                              label: o.estimatedTime,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDimens.xl.h),

                      // ── Section : Itinéraire ────────────────
                      _SectionCard(
                        title: 'Itinéraire',
                        icon: LucideIcons.navigation,
                        child: _RouteSection(
                          pickup: o.pickup,
                          delivery: o.delivery,
                        ),
                      ),
                      SizedBox(height: AppDimens.md.h),

                      // ── Section : Récupérer chez ────────────
                      // Le commerçant pour une commande, l'expéditeur
                      // sinon. L'adresse n'est pas répétée : elle est
                      // déjà dans l'itinéraire.
                      if (pickupName != null)
                        _SectionCard(
                          title: 'Récupérer chez',
                          icon: LucideIcons.store,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ContactSection(
                                name: pickupName,
                                phone: pickupPhone,
                                logoUrl: structure?.logoFile != null
                                    ? ApiConfig.getImageUrl(
                                        structure!.logoFile!)
                                    : null,
                                avatarColor: AppColors.primarySurface,
                                avatarIconColor: AppColors.primary,
                                avatarIcon: Icons.storefront_rounded,
                              ),
                              // Ce qu'il y a à prendre au comptoir, sous
                              // l'enseigne où il faut aller le chercher.
                              if (detail?.commandeStructureId != null) ...[
                                SizedBox(height: AppDimens.md.h),
                                ProduitsCommandeBlock(
                                  commandeStructureId:
                                      detail!.commandeStructureId!,
                                  accent: AppColors.secondary,
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (pickupName != null)
                        SizedBox(height: AppDimens.md.h),

                      // ── Section : Livrer à ──────────────────
                      if (clientName != null)
                        _SectionCard(
                          title: 'Livrer à',
                          icon: LucideIcons.user,
                          child: _ContactSection(
                            name: clientName,
                            phone: clientPhone,
                            avatarColor: AppColors.secondaryLight
                                .withValues(alpha: 0.15),
                            avatarIconColor: AppColors.secondary,
                            avatarIcon: Icons.person_rounded,
                          ),
                        ),

                      // ── Section : Instructions ──────────────
                      if (instructions != null &&
                          instructions.isNotEmpty) ...[
                        SizedBox(height: AppDimens.md.h),
                        _SectionCard(
                          title: 'Instructions',
                          icon: LucideIcons.clipboardList,
                          child: Text(
                            instructions,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.grey800),
                          ),
                        ),
                      ],

                      // Espace pour les boutons fixes
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
                ), // fin Transform.translate
              ),
            ],
          ),

          // ── Back button + Header ──────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8.h,
            left: AppDimens.screenPadding.w,
            right: AppDimens.screenPadding.w,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: AppColors.dark.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.arrowLeft,
                        color: AppColors.white, size: 20.r),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.55),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    'Détails commande',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Boutons fixes en bas ──────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppDimens.screenPadding.w,
                AppDimens.md.h,
                AppDimens.screenPadding.w,
                MediaQuery.of(context).padding.bottom + AppDimens.md.h,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _isAccepting
                          ? null
                          : () {
                              if (o.missionId != 0) {
                                refuseMission(ref, o.missionId);
                              }
                              Navigator.of(context).pop();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.grey600,
                        side: const BorderSide(color: AppColors.grey300),
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      child: Text(
                        'Refuser',
                        style: TextStyle(
                          fontFamily: 'Archivo',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimens.sm.w),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _isAccepting || o.missionId == 0
                          ? null
                          : () => _onAccept(o.missionId),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50.h),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      child: _isAccepting
                          ? SizedBox(
                              height: 20.r,
                              width: 20.r,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.white),
                            )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 18.r),
                          SizedBox(width: 6.w),
                          Text(
                            'Accepter la course',
                            style: TextStyle(
                              fontFamily: 'Archivo',
                              fontSize: 14.sp,
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
          ),
        ],
      ),
    );
  }
}

// ── Pill info (distance / temps) ────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: color),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Archivo',
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card générique ───────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: AppDimens.screenPadding.w),
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
            Row(
              children: [
                Icon(icon, size: 16.r, color: AppColors.dark),
                SizedBox(width: 7.w),
                Text(title,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.dark,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            SizedBox(height: AppDimens.md.h),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Itinéraire ───────────────────────────────────────────────────
class _RouteSection extends StatelessWidget {
  final String pickup;
  final String delivery;
  const _RouteSection({required this.pickup, required this.delivery});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icônes + ligne
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
            Container(width: 1.5, height: 32.h, color: AppColors.grey200),
            Icon(LucideIcons.mapPin,
                color: AppColors.secondary, size: 18.r),
          ],
        ),
        SizedBox(width: AppDimens.md.w),
        // Textes
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Départ',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey500)),
              SizedBox(height: 1.h),
              Text(pickup,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.dark)),
              SizedBox(height: 16.h),
              Text('Arrivée',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey500)),
              SizedBox(height: 1.h),
              Text(delivery,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.dark)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section contact générique (marchand ou client) ───────────────
class _ContactSection extends StatelessWidget {
  final String name;
  final String? phone;
  final Color avatarColor;
  final Color avatarIconColor;
  final IconData avatarIcon;

  /// Logo du commerçant, affiché à la place de l'icône quand il existe.
  final String? logoUrl;

  const _ContactSection({
    required this.name,
    required this.avatarColor,
    required this.avatarIconColor,
    required this.avatarIcon,
    this.phone,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Avatar
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
                image: logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(logoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: logoUrl != null
                  ? null
                  : Icon(avatarIcon, color: avatarIconColor, size: 22.r),
            ),
            SizedBox(width: AppDimens.md.w),
            Expanded(
              child: Text(name,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.dark)),
            ),
            // Bouton appel
            if (phone != null)
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.phone_rounded,
                      color: AppColors.success, size: 18.r),
                ),
              ),
          ],
        ),
        // Numéro de téléphone en texte
        if (phone != null) ...[
          SizedBox(height: AppDimens.sm.h),
          Padding(
            padding: EdgeInsets.only(left: 42.r + AppDimens.md.w),
            child: Text(phone!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey700)),
          ),
        ],
      ],
    );
  }
}
