import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import 'providers/auth_notifier.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).createPassword(
          email: widget.email,
          newPassword: _passwordCtrl.text,
        );
    if (success && mounted) context.goNamed(RouteNames.login);
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
          onPressed: () => Navigator.pop(context),
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
                Text('Nouveau\nmot de passe', style: AppTextStyles.h2),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'Choisissez un nouveau mot de passe sécurisé.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey600),
                ),
                const SizedBox(height: AppDimens.xxxl),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure1,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.grey500),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey500,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.lg),

                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.grey500),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey500,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.lg),

                Row(
                  children: [
                    Icon(
                      _passwordCtrl.text.length >= 8
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 16,
                      color: _passwordCtrl.text.length >= 8
                          ? AppColors.success
                          : AppColors.grey400,
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Text(
                      'Minimum 8 caractères',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _passwordCtrl.text.length >= 8
                            ? AppColors.success
                            : AppColors.grey500,
                      ),
                    ),
                  ],
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
                        : const Text('Réinitialiser'),
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
