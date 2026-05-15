import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import 'providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (success && mounted) {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimens.huge),
                Text(AppStrings.login, style: AppTextStyles.h2),
                const SizedBox(height: AppDimens.sm),
                Text(
                  'Connectez-vous à votre compte livreur',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppDimens.xxxl),

                TextFormField(
                  controller: _usernameCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppStrings.email,
                    hintText: 'votre@email.com',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Email requis' : null,
                ),
                const SizedBox(height: AppDimens.lg),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: AppStrings.password,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Mot de passe requis' : null,
                ),
                const SizedBox(height: AppDimens.sm),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.goNamed(RouteNames.forgotPassword),
                    child: const Text(AppStrings.forgotPassword),
                  ),
                ),

                if (state.error != null) ...[
                  const SizedBox(height: AppDimens.md),
                  Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    child: Text(
                      state.error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppDimens.xxl),
                ElevatedButton(
                  onPressed: state.isLoading ? null : _login,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text(AppStrings.login),
                ),

                const SizedBox(height: AppDimens.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.noAccount,
                        style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.goNamed(RouteNames.register),
                      child: const Text(AppStrings.register),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
