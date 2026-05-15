import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import 'providers/auth_notifier.dart';

// ── Formatter téléphone : XX XXX XX XX (max 9 chiffres) ────────
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1
  final _step1Key = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _docType = 'CIN';
  // Contrôleurs séparés pour CIN et Passeport → ne se vident pas au switch
  final _cinCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();

  // Step 2
  final _step2Key = GlobalKey<FormState>();
  String _vehicleType = 'MOTO';
  String _bikeType = 'CLASSIQUE';
  final _brandCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  String? _carteGrisePath;

  // Step 3
  final _step3Key = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  TextEditingController get _activeDocCtrl =>
      _docType == 'CIN' ? _cinCtrl : _passportCtrl;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cinCtrl.dispose();
    _passportCtrl.dispose();
    _brandCtrl.dispose();
    _licenseCtrl.dispose();
    _plateCtrl.dispose();
    _insuranceCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    final valid = _currentStep == 0
        ? _step1Key.currentState!.validate()
        : _step2Key.currentState!.validate();
    if (!valid) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
  }

  void _prevStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    if (!_step3Key.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).registerDriver(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telephone: _phoneCtrl.text.replaceAll(' ', ''),
          address: _addressCtrl.text.trim(),
          docType: _docType,
          docNumber: _activeDocCtrl.text.trim(),
          vehicleType: _vehicleType == 'VELO' ? 'VELO_$_bikeType' : _vehicleType,
          brand: _brandCtrl.text.trim(),
          licenseNumber: _licenseCtrl.text.trim(),
          plate: _plateCtrl.text.trim(),
          insurance: _insuranceCtrl.text.trim(),
          carteGrisePath: _carteGrisePath,
          password: _passwordCtrl.text,
        );
    if (success && mounted) {
      context.goNamed(RouteNames.verification, extra: _emailCtrl.text.trim());
    }
  }

  Future<void> _pickCarteGrise() async {
    final file =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _carteGrisePath = file.path);
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
          onPressed: () =>
              _currentStep > 0 ? _prevStep() : context.goNamed(RouteNames.onboarding),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Step1(
            formKey: _step1Key,
            firstNameCtrl: _firstNameCtrl,
            lastNameCtrl: _lastNameCtrl,
            phoneCtrl: _phoneCtrl,
            emailCtrl: _emailCtrl,
            addressCtrl: _addressCtrl,
            docType: _docType,
            cinCtrl: _cinCtrl,
            passportCtrl: _passportCtrl,
            onDocTypeChanged: (v) => setState(() => _docType = v),
            onNext: _nextStep,
          ),
          _Step2(
            formKey: _step2Key,
            vehicleType: _vehicleType,
            bikeType: _bikeType,
            brandCtrl: _brandCtrl,
            licenseCtrl: _licenseCtrl,
            plateCtrl: _plateCtrl,
            insuranceCtrl: _insuranceCtrl,
            carteGrisePath: _carteGrisePath,
            onVehicleTypeChanged: (v) => setState(() => _vehicleType = v),
            onBikeTypeChanged: (v) => setState(() => _bikeType = v!),
            onPickCarteGrise: _pickCarteGrise,
            onNext: _nextStep,
          ),
          _Step3(
            formKey: _step3Key,
            passwordCtrl: _passwordCtrl,
            confirmCtrl: _confirmCtrl,
            obscure1: _obscure1,
            obscure2: _obscure2,
            isLoading: state.isLoading,
            error: state.error,
            onToggleObscure1: () => setState(() => _obscure1 = !_obscure1),
            onToggleObscure2: () => setState(() => _obscure2 = !_obscure2),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Widget label avec astérisque ────────────────────────────────
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
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700),
            )
          ],
        ),
      ),
    );
  }
}

// ── InputDecoration sans icône ──────────────────────────────────
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

// ── STEP 1 ─────────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController addressCtrl;
  final String docType;
  final TextEditingController cinCtrl;
  final TextEditingController passportCtrl;
  final ValueChanged<String> onDocTypeChanged;
  final VoidCallback onNext;

  const _Step1({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.addressCtrl,
    required this.docType,
    required this.cinCtrl,
    required this.passportCtrl,
    required this.onDocTypeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final activeCtrl = docType == 'CIN' ? cinCtrl : passportCtrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 0, AppDimens.screenPadding, AppDimens.xl),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Créez votre\n',
                style: AppTextStyles.h2,
                children: [
                  TextSpan(
                    text: 'compte livreur',
                    style: AppTextStyles.h2.copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            Text('Renseignez vos informations personnelles.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppDimens.xxl),

            // Prénom + Nom
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Prénom'),
                      TextFormField(
                        controller: firstNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDeco(hint: 'Mamadou'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Nom'),
                      TextFormField(
                        controller: lastNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDeco(hint: 'Diallo'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.lg),

            // Téléphone
            const _Label('Téléphone'),
            TextFormField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [_PhoneFormatter()],
              decoration: _inputDeco(hint: '77 123 45 67'),
              validator: (v) {
                final digits = v?.replaceAll(' ', '') ?? '';
                if (digits.isEmpty) return 'Téléphone requis';
                if (digits.length != 9) return '9 chiffres requis';
                return null;
              },
            ),
            const SizedBox(height: AppDimens.lg),

            // Email
            const _Label('Email'),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDeco(hint: 'exemple@email.com'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email requis';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: AppDimens.lg),

            // Adresse
            const _Label('Adresse'),
            TextFormField(
              controller: addressCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco(hint: 'Rue, Quartier, Ville'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Adresse requise' : null,
            ),
            const SizedBox(height: AppDimens.xxl),

            // Type de document
            const _Label('Type de document d\'identité'),
            Row(
              children: [
                _DocToggle(
                  label: 'CIN',
                  selected: docType == 'CIN',
                  onTap: () => onDocTypeChanged('CIN'),
                ),
                const SizedBox(width: AppDimens.md),
                _DocToggle(
                  label: 'Passeport',
                  selected: docType == 'PASSPORT',
                  onTap: () => onDocTypeChanged('PASSPORT'),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.lg),

            _Label(docType == 'CIN' ? 'Numéro CIN' : 'Numéro Passeport'),
            TextFormField(
              controller: activeCtrl,
              keyboardType: docType == 'CIN'
                  ? TextInputType.number
                  : TextInputType.text,
              textCapitalization: docType == 'PASSPORT'
                  ? TextCapitalization.characters
                  : TextCapitalization.none,
              inputFormatters: docType == 'CIN'
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(9),
                    ],
              decoration: _inputDeco(
                hint: docType == 'CIN'
                    ? 'Numéro à 13 chiffres'
                    : 'Ex: AB1234567',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Numéro requis';
                if (docType == 'PASSPORT' && v.length > 9) {
                  return 'Maximum 9 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimens.xxxl),

            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Continuer'),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Déjà un compte ? ',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.grey600)),
                  GestureDetector(
                    onTap: () => context.goNamed(RouteNames.login),
                    child: Text('Se connecter',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}

// ── STEP 2 ─────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String vehicleType;
  final String bikeType;
  final TextEditingController brandCtrl;
  final TextEditingController licenseCtrl;
  final TextEditingController plateCtrl;
  final TextEditingController insuranceCtrl;
  final String? carteGrisePath;
  final ValueChanged<String> onVehicleTypeChanged;
  final ValueChanged<String?> onBikeTypeChanged;
  final VoidCallback onPickCarteGrise;
  final VoidCallback onNext;

  const _Step2({
    required this.formKey,
    required this.vehicleType,
    required this.bikeType,
    required this.brandCtrl,
    required this.licenseCtrl,
    required this.plateCtrl,
    required this.insuranceCtrl,
    required this.carteGrisePath,
    required this.onVehicleTypeChanged,
    required this.onBikeTypeChanged,
    required this.onPickCarteGrise,
    required this.onNext,
  });

  bool get _isBike => vehicleType == 'VELO';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 0, AppDimens.screenPadding, AppDimens.xl),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Votre ',
                style: AppTextStyles.h2,
                children: [
                  TextSpan(
                    text: 'véhicule',
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            Text('Sélectionnez votre moyen de transport.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppDimens.xxl),

            // Sélecteur véhicule
            const _Label('Type de véhicule'),
            Row(
              children: [
                _VehicleCard(
                  icon: Icons.pedal_bike_rounded,
                  label: 'Vélo',
                  selected: vehicleType == 'VELO',
                  color: AppColors.success,
                  onTap: () => onVehicleTypeChanged('VELO'),
                ),
                const SizedBox(width: AppDimens.md),
                _VehicleCard(
                  icon: Icons.two_wheeler_rounded,
                  label: 'Moto',
                  selected: vehicleType == 'MOTO',
                  color: AppColors.secondary,
                  onTap: () => onVehicleTypeChanged('MOTO'),
                ),
                const SizedBox(width: AppDimens.md),
                _VehicleCard(
                  icon: Icons.directions_car_rounded,
                  label: 'Voiture',
                  selected: vehicleType == 'VOITURE',
                  color: AppColors.primary,
                  onTap: () => onVehicleTypeChanged('VOITURE'),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.xl),

            // Vélo → dropdown type
            if (_isBike) ...[
              const _Label('Type de vélo'),
              DropdownButtonFormField<String>(
                value: bikeType, // ignore: deprecated_member_use
                decoration: _inputDeco(),
                items: const [
                  DropdownMenuItem(
                      value: 'CLASSIQUE', child: Text('Vélo classique')),
                  DropdownMenuItem(
                      value: 'ELECTRIQUE', child: Text('Vélo électrique')),
                  DropdownMenuItem(
                      value: 'CARGO', child: Text('Vélo cargo')),
                  DropdownMenuItem(
                      value: 'VTT', child: Text('VTT')),
                ],
                onChanged: onBikeTypeChanged,
              ),
            ],

            // Moto / Voiture → champs complets
            if (!_isBike) ...[
              const _Label('Marque'),
              TextFormField(
                controller: brandCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDeco(hint: 'Ex: Honda, Toyota...'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Marque requise' : null,
              ),
              const SizedBox(height: AppDimens.lg),

              const _Label('Numéro de permis'),
              TextFormField(
                controller: licenseCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDeco(hint: 'Numéro de permis de conduire'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: AppDimens.lg),

              const _Label('Immatriculation'),
              TextFormField(
                controller: plateCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDeco(hint: 'Ex: DK 1234 AB'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: AppDimens.lg),

              const _Label('Numéro d\'assurance'),
              TextFormField(
                controller: insuranceCtrl,
                decoration: _inputDeco(hint: 'Numéro de police d\'assurance'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: AppDimens.lg),

              // Upload carte grise
              const _Label('Carte grise'),
              GestureDetector(
                onTap: onPickCarteGrise,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimens.lg),
                  decoration: BoxDecoration(
                    color: carteGrisePath != null
                        ? AppColors.primarySurface
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                      color: carteGrisePath != null
                          ? AppColors.primary
                          : AppColors.grey300,
                      width: carteGrisePath != null ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: carteGrisePath != null
                              ? AppColors.primary
                              : AppColors.grey100,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                        child: Icon(
                          carteGrisePath != null
                              ? Icons.check_rounded
                              : Icons.upload_rounded,
                          color: carteGrisePath != null
                              ? AppColors.white
                              : AppColors.grey500,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppDimens.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            carteGrisePath != null
                                ? 'Fichier chargé'
                                : 'Charger la carte grise',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: carteGrisePath != null
                                  ? AppColors.primary
                                  : AppColors.dark,
                            ),
                          ),
                          Text(
                            carteGrisePath != null
                                ? 'Appuyez pour changer'
                                : 'JPG, PNG ou PDF',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppDimens.xxxl),

            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed: onNext,
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STEP 3 ─────────────────────────────────────────────────────
class _Step3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscure1;
  final bool obscure2;
  final bool isLoading;
  final String? error;
  final VoidCallback onToggleObscure1;
  final VoidCallback onToggleObscure2;
  final VoidCallback onSubmit;

  const _Step3({
    required this.formKey,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscure1,
    required this.obscure2,
    required this.isLoading,
    required this.error,
    required this.onToggleObscure1,
    required this.onToggleObscure2,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding, 0, AppDimens.screenPadding, AppDimens.xl),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Sécurisez\n',
                style: AppTextStyles.h2,
                children: [
                  TextSpan(
                    text: 'votre compte',
                    style: AppTextStyles.h2
                        .copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.xs),
            Text('Choisissez un mot de passe fort pour protéger votre espace.',
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppDimens.xxl),

            const _Label('Mot de passe'),
            TextFormField(
              controller: passwordCtrl,
              obscureText: obscure1,
              onChanged: (_) {},
              decoration: _inputDeco(hint: 'Minimum 8 caractères').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure1
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey500,
                    size: 20,
                  ),
                  onPressed: onToggleObscure1,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (v.length < 8) return 'Minimum 8 caractères';
                return null;
              },
            ),
            const SizedBox(height: AppDimens.lg),

            const _Label('Confirmer le mot de passe'),
            TextFormField(
              controller: confirmCtrl,
              obscureText: obscure2,
              decoration: _inputDeco(hint: 'Répétez le mot de passe').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure2
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.grey500,
                    size: 20,
                  ),
                  onPressed: onToggleObscure2,
                ),
              ),
              validator: (v) {
                if (v != passwordCtrl.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),

            if (error != null) ...[
              const SizedBox(height: AppDimens.lg),
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: Text(error!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimens.xxxl),

            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.white),
                      )
                    : const Text('Créer mon compte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets réutilisables ───────────────────────────────────────

class _DocToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DocToggle(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.xl, vertical: AppDimens.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.grey300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? AppColors.white : AppColors.grey700,
          ),
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: selected ? color : AppColors.grey300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? color : AppColors.grey400,
                  size: AppDimens.iconXl),
              const SizedBox(height: AppDimens.xs),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? color : AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
