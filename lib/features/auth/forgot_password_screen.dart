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

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();

    // Le service téléphone n'est pas encore dispo côté back :
    // on n'utilise que l'email pour le moment.
    final success = await ref
        .read(authProvider.notifier)
        .forgotPassword(email: email, telephone: '');
    if (success && mounted) {
      context.goNamed(
        RouteNames.forgotVerification,
        extra: ForgotVerificationArgs(email: email, telephone: ''),
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
                  'Entrez votre adresse email. Nous vous enverrons un code pour réinitialiser votre mot de passe.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey600),
                ),
                const SizedBox(height: AppDimens.xxxl),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    hintText: 'exemple@email.com',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.grey500),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
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
