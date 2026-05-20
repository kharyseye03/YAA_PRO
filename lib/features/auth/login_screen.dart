import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import 'providers/auth_notifier.dart';

// ── Label avec astérisque (même style que register) ─────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.grey800),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(
                  color: AppColors.secondary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ── InputDecoration (même style que register) ────────────────────
InputDecoration _inputDeco({String? hint}) => InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.lg, vertical: AppDimens.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.grey300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      filled: true,
      fillColor: AppColors.white,
    );

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
          username: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (success && mounted) context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo ────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                     Image.asset(
                          'assets/images/logo-pro3.jpeg',
                          width: 200.w,
                          height: 200.h,
                     ),
                    ],
                  ),
                ),

                // ── Titre ───────────────────────────────────
                RichText(
                  text: TextSpan(
                    text: 'Bon retour\n',
                    style: AppTextStyles.h2,
                    children: [
                      TextSpan(
                        text: 'chez vous 👋',
                        style: AppTextStyles.h2
                            .copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppDimens.xs.h),
                Text(
                  'Connectez-vous pour accéder à votre espace.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.grey600),
                ),

                SizedBox(height: AppDimens.xxl.h),

                // ── Email ───────────────────────────────────
                const _Label('Adresse email'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDeco(hint: 'exemple@email.com'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                SizedBox(height: AppDimens.lg.h),

                // ── Mot de passe ────────────────────────────
                const _Label('Mot de passe'),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: _inputDeco(hint: 'Votre mot de passe').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey500,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Mot de passe requis' : null,
                ),
                SizedBox(height: AppDimens.md.h),

                // ── Mot de passe oublié ─────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () =>
                        context.goNamed(RouteNames.forgotPassword),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),

                // ── Erreur ──────────────────────────────────
                if (state.error != null) ...[
                  SizedBox(height: AppDimens.lg.h),
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
                          child: Text(
                            state.error!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: AppDimens.xxxl.h),

                // ── Bouton connexion ────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _login,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white),
                          )
                        : const Text('Se connecter'),
                  ),
                ),

                SizedBox(height: AppDimens.lg.h),

                // ── Lien inscription ────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ? ',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey600),
                      ),
                      GestureDetector(
                        onTap: () => context.goNamed(RouteNames.register),
                        child: Text(
                          'S\'inscrire',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppDimens.xl.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
