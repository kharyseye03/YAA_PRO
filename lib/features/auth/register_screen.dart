import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import 'providers/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _vehiclePlateCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _cniCtrl = TextEditingController();

  String _selectedVehicle = 'MOTO';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _vehiclePlateCtrl.dispose();
    _licenseCtrl.dispose();
    _cniCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).registerDriver(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telephone: _phoneCtrl.text.trim(),
      vehicleType: _selectedVehicle,
      vehiclePlate: _vehiclePlateCtrl.text.trim(),
      licenseNumber: _licenseCtrl.text.trim(),
      cniNumber: _cniCtrl.text.trim(),
    );

    if (success && mounted) {
      context.goNamed(
        RouteNames.verification,
        extra: _emailCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.register)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informations personnelles', style: AppTextStyles.h4),
              const SizedBox(height: AppDimens.lg),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(
                          labelText: AppStrings.firstName),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(
                          labelText: AppStrings.lastName),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.lg),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: AppStrings.phone),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Téléphone requis' : null,
              ),
              const SizedBox(height: AppDimens.lg),

              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: AppStrings.email),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: AppDimens.xxxl),

              Text('Informations du véhicule', style: AppTextStyles.h4),
              const SizedBox(height: AppDimens.lg),

              DropdownButtonFormField<String>(
                value: _selectedVehicle,
                decoration: const InputDecoration(
                    labelText: AppStrings.vehicleType),
                items: const [
                  DropdownMenuItem(
                      value: 'MOTO', child: Text(AppStrings.vehicleMoto)),
                  DropdownMenuItem(
                      value: 'VOITURE', child: Text(AppStrings.vehicleCar)),
                  DropdownMenuItem(
                      value: 'VELO', child: Text(AppStrings.vehicleBike)),
                ],
                onChanged: (v) =>
                    setState(() => _selectedVehicle = v ?? 'MOTO'),
              ),
              const SizedBox(height: AppDimens.lg),

              TextFormField(
                controller: _vehiclePlateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: AppStrings.vehiclePlate),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Numéro d\'immatriculation requis' : null,
              ),
              const SizedBox(height: AppDimens.lg),

              TextFormField(
                controller: _licenseCtrl,
                decoration: const InputDecoration(
                    labelText: AppStrings.licenseNumber),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Numéro de permis requis' : null,
              ),
              const SizedBox(height: AppDimens.lg),

              TextFormField(
                controller: _cniCtrl,
                decoration: const InputDecoration(
                    labelText: AppStrings.cniNumber),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Numéro CNI requis' : null,
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
                  child: Text(
                    state.error!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error),
                  ),
                ),
              ],

              const SizedBox(height: AppDimens.xxxl),
              ElevatedButton(
                onPressed: state.isLoading ? null : _register,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text(AppStrings.next),
              ),

              const SizedBox(height: AppDimens.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppStrings.alreadyHaveAccount,
                      style: AppTextStyles.bodyMedium),
                  TextButton(
                    onPressed: () => context.goNamed(RouteNames.login),
                    child: const Text(AppStrings.login),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.xl),
            ],
          ),
        ),
      ),
    );
  }
}
