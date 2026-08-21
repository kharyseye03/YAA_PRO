import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import 'forgot_verification_screen.dart';
import 'providers/auth_notifier.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

/// Canal par lequel le livreur veut recevoir son code.
enum _Canal { email, telephone }

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  /// L'email est ouvert par défaut : c'est le canal historique.
  _Canal _canal = _Canal.email;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Bascule de canal. On vide le champ abandonné : il ne sera pas
  /// envoyé, et le laisser rempli laisserait croire qu'il compte.
  void _basculer(_Canal canal) {
    if (_canal == canal) return;
    setState(() {
      _canal = canal;
      _emailCtrl.clear();
      _phoneCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _canal == _Canal.email ? _emailCtrl.text.trim() : '';
    final telephone = _canal == _Canal.telephone
        ? _phoneCtrl.text.replaceAll(' ', '')
        : '';

    final success = await ref
        .read(authProvider.notifier)
        .forgotPassword(email: email, telephone: telephone);
    if (success && mounted) {
      context.goNamed(
        RouteNames.forgotVerification,
        extra: ForgotVerificationArgs(email: email, telephone: telephone),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.dark),
          onPressed: () => context.goNamed(RouteNames.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimens.lg),
                Text('Mot de passe\noublié ?', style: AppTextStyles.h2),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'Choisissez comment recevoir votre code de '
                  'réinitialisation.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey600),
                ),
                const SizedBox(height: AppDimens.xl),

                // ── Par email ───────────────────────────────
                _CanalPanel(
                  titre: 'Par email',
                  icone: Icons.email_outlined,
                  ouvert: _canal == _Canal.email,
                  onTap: () => _basculer(_Canal.email),
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Adresse email',
                      hintText: 'exemple@email.com',
                    ),
                    // Seul le canal ouvert est validé : le champ replié
                    // est vide et ne doit pas bloquer l'envoi.
                    validator: (v) {
                      if (_canal != _Canal.email) return null;
                      if (v == null || v.trim().isEmpty) {
                        return 'Email requis';
                      }
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppDimens.md),

                // ── Par téléphone ───────────────────────────
                _CanalPanel(
                  titre: 'Par téléphone',
                  icone: Icons.smartphone_outlined,
                  ouvert: _canal == _Canal.telephone,
                  onTap: () => _basculer(_Canal.telephone),
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone',
                      hintText: '622 12 34 56',
                    ),
                    validator: (v) {
                      if (_canal != _Canal.telephone) return null;
                      final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                      if (digits.isEmpty) return 'Téléphone requis';
                      if (digits.length != 9) return '9 chiffres requis';
                      return null;
                    },
                  ),
                ),

                if (state.error != null) ...[
                  const SizedBox(height: AppDimens.lg),
                  Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: Text(state.error!,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.white),
                          )
                        : const Text('Envoyer le code'),
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Panneau dépliable d'un canal de récupération ─────────────────
/// Un seul panneau est ouvert à la fois : le canal ouvert est celui
/// qui sera utilisé pour l'envoi du code.
class _CanalPanel extends StatelessWidget {
  final String titre;
  final IconData icone;
  final bool ouvert;
  final VoidCallback onTap;
  final Widget child;

  const _CanalPanel({
    required this.titre,
    required this.icone,
    required this.ouvert,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: ouvert ? AppColors.white : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(
          color: ouvert ? AppColors.primary : AppColors.grey300,
          width: ouvert ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.md),
              child: Row(
                children: [
                  Icon(icone,
                      size: 20,
                      color:
                          ouvert ? AppColors.primary : AppColors.grey500),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: Text(
                      titre,
                      style: AppTextStyles.labelMedium.copyWith(
                        color:
                            ouvert ? AppColors.dark : AppColors.grey600,
                      ),
                    ),
                  ),
                  // Un rond plein plutôt qu'un chevron : le geste est un
                  // choix entre deux options, pas un dépliage libre.
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ouvert
                            ? AppColors.primary
                            : AppColors.grey400,
                        width: 1.5,
                      ),
                    ),
                    child: ouvert
                        ? Center(
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
          if (ouvert)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.md, 0, AppDimens.md, AppDimens.md),
              child: child,
            ),
        ],
      ),
    );
  }
}
