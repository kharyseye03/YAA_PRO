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

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
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

    if (success && mounted) {
      context.goNamed(RouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: AppDimens.xl),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requis';
                  if (v.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.lg),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
                validator: (v) {
                  if (v != _passwordCtrl.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              if (state.error != null) ...[
                const SizedBox(height: AppDimens.lg),
                Text(
                  state.error!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                child: const Text(AppStrings.confirm),
              ),
              const SizedBox(height: AppDimens.xl),
            ],
          ),
        ),
      ),
    );
  }
}
