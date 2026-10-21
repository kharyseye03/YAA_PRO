import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/constants.dart';
import '../../model/notification/app_notification.dart';
import '../auth/providers/auth_notifier.dart';
import '../orders/providers/orders_provider.dart';
import '../shell/main_shell.dart';
import 'providers/notifications_provider.dart';

/// Historique des notifications reçues par le coursier.
///
/// Les notifications Android disparaissent dès qu'on les balaie : sans
/// cet écran, un coursier qui a raté une course n'a aucun moyen de
/// savoir ce qui lui a été proposé.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  void _rafraichir() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(notificationsNonLuesProvider);
  }

  Future<void> _ouvrir(AppNotification notif) async {
    if (!notif.lue) {
      try {
        await ref.read(apiServiceProvider).marquerNotificationLue(notif.id);
        _rafraichir();
      } catch (_) {
        // Marquer comme lue est secondaire : on ouvre quand même.
      }
    }
    if (!mounted) return;

    // Une annulation ne mène nulle part — la course n'existe plus. Une
    // nouvelle course mène à la liste, où elle est peut-être encore
    // disponible.
    if (!notif.estAnnulation) {
      ref.invalidate(availableOrdersProvider);
      ref.read(shellIndexProvider.notifier).state = 1;
      Navigator.of(context).pop();
    }
  }

  Future<void> _supprimer(AppNotification notif) async {
    try {
      await ref.read(apiServiceProvider).supprimerNotification(notif.id);
      _rafraichir();
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''));
      _rafraichir();
    }
  }

  Future<void> _toutMarquerLu() async {
    try {
      await ref.read(apiServiceProvider).marquerToutesNotificationsLues();
      _rafraichir();
    } catch (e) {
      if (mounted) _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _toutSupprimer() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Tout supprimer ?',
            style: AppTextStyles.labelLarge
                .copyWith(fontWeight: FontWeight.w700)),
        content: Text(
          'Vos notifications seront effacées définitivement.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.grey600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirme != true) return;
    try {
      await ref.read(apiServiceProvider).supprimerToutesNotifications();
      _rafraichir();
    } catch (e) {
      if (mounted) _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final liste = notifications.valueOrNull ?? const <AppNotification>[];
    final aDesNonLues = liste.any((n) => !n.lue);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── En-tête ───────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12.h,
              left: AppDimens.screenPadding.w,
              right: AppDimens.screenPadding.w,
              bottom: 12.h,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 38.r,
                    height: 38.r,
                    child: Icon(Icons.chevron_left_rounded,
                        color: AppColors.dark, size: 22.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Notifications',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                ),
                if (liste.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: Icon(LucideIcons.moreVertical,
                        size: 20.r, color: AppColors.grey700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    onSelected: (choix) => choix == 'lues'
                        ? _toutMarquerLu()
                        : _toutSupprimer(),
                    itemBuilder: (_) => [
                      if (aDesNonLues)
                        PopupMenuItem(
                          value: 'lues',
                          child: Text('Tout marquer comme lu',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.dark)),
                        ),
                      PopupMenuItem(
                        value: 'supprimer',
                        child: Text('Tout supprimer',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Liste ─────────────────────────────────────────
          Expanded(
            child: notifications.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => _Vide(
                icone: LucideIcons.wifiOff,
                titre: 'Chargement impossible',
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: _rafraichir,
              ),
              data: (items) {
                if (items.isEmpty) {
                  return _Vide(
                    icone: LucideIcons.bellOff,
                    titre: 'Aucune notification',
                    message: 'Les courses proposées et les annulations '
                        'apparaîtront ici.',
                    onRetry: _rafraichir,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _rafraichir(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppDimens.screenPadding.w,
                      AppDimens.lg.h,
                      AppDimens.screenPadding.w,
                      AppDimens.xxxl.h +
                          MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppDimens.sm.h),
                    itemBuilder: (_, i) => Dismissible(
                      key: ValueKey(items[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: AppDimens.lg.w),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusLg),
                        ),
                        child: Icon(LucideIcons.trash2,
                            color: AppColors.error, size: 20.r),
                      ),
                      onDismissed: (_) => _supprimer(items[i]),
                      child: _Ligne(
                        notif: items[i],
                        onTap: () => _ouvrir(items[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Une notification ─────────────────────────────────────────────
class _Ligne extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;

  const _Ligne({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Couleur par nature : une annulation ne doit pas se confondre
    // avec une course à prendre.
    final accent =
        notif.estAnnulation ? AppColors.error : AppColors.secondary;
    final icone =
        notif.estAnnulation ? LucideIcons.xCircle : LucideIcons.package;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(AppDimens.md.r),
        decoration: BoxDecoration(
          // Une non lue est sur fond blanc, une lue se fond dans la
          // page : la différence se voit d'un coup d'œil.
          color: notif.lue ? AppColors.surface : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(
            color: notif.lue ? AppColors.grey200 : accent.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(icone, color: accent, size: 18.r),
            ),
            SizedBox(width: AppDimens.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.titre,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.dark,
                            fontWeight:
                                notif.lue ? FontWeight.w600 : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notif.lue)
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    notif.message,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.grey700),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notif.anciennete,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Liste vide ou en erreur ──────────────────────────────────────
class _Vide extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String message;
  final VoidCallback onRetry;

  const _Vide({
    required this.icone,
    required this.titre,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.xxl.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 42.r, color: AppColors.grey300),
            SizedBox(height: AppDimens.lg.h),
            Text(titre,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.dark)),
            SizedBox(height: AppDimens.xs.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
            ),
            SizedBox(height: AppDimens.lg.h),
            TextButton(
              onPressed: onRetry,
              child: Text('Actualiser',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}
