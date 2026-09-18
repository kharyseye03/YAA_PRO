import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import '../home/providers/location_provider.dart';
import 'providers/auth_notifier.dart';
import 'verification_screen.dart';

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 5 || i == 7) buffer.write(' ');
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
  bool _locating = false;
  String _docType = 'CIN';
  // Contrôleurs séparés pour CIN et Passeport → ne se vident pas au switch
  final _cinCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();

  // Step 2
  final _step2Key = GlobalKey<FormState>();
  String _vehicleType = 'MOTO';
  final _brandCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  final _couleurCtrl = TextEditingController();
  final _carteGriseCtrl = TextEditingController();

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
    _couleurCtrl.dispose();
    _carteGriseCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1Key.currentState!.validate()) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      // Étape véhicule → soumission du formulaire
      _submit();
    }
  }

  /// Remplit l'adresse à partir de la position GPS.
  ///
  /// Le champ reste modifiable : le géocodeur natif ne connaît souvent
  /// que le quartier et la ville, le livreur précise s'il le souhaite.
  Future<void> _useMyLocation() async {
    if (_locating) return;
    FocusScope.of(context).unfocus();
    setState(() => _locating = true);

    final service = ref.read(locationServiceProvider);
    String? message;
    try {
      final position = await service
          .getCurrentPosition()
          .timeout(const Duration(seconds: 15));
      final label =
          await service.reverseGeocode(position.latitude, position.longitude);
      if (label != null) {
        _addressCtrl.text = label;
      } else {
        message = 'Adresse introuvable. Saisissez-la manuellement.';
      }
    } on Exception catch (e) {
      // Les refus (GPS éteint, permission) ont déjà un texte lisible ;
      // le reste (délai dépassé…) reçoit un message générique.
      final texte = e.toString();
      message = texte.startsWith('Exception: ')
          ? texte.substring('Exception: '.length)
          : 'Position introuvable. Saisissez l\'adresse manuellement.';
    }

    if (!mounted) return;
    setState(() => _locating = false);
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _prevStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
  }

  /// Valeur de l'enum TypeVehicule attendue par le backend :
  /// MOTO, VEHICULE ou CARGO.
  String get _vehiculeEnum => switch (_vehicleType) {
        'VOITURE' => 'VEHICULE',
        'CARGO' => 'CARGO',
        _ => 'MOTO',
      };

  Future<void> _submit() async {
    if (!_step2Key.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).registerDriver(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          telephone: _phoneCtrl.text.replaceAll(' ', ''),
          address: _addressCtrl.text.trim(),
          docType: _docType == 'CIN' ? 'CNI' : 'PASSEPORT',
          docNumber: _activeDocCtrl.text.trim(),
          vehicule: _vehiculeEnum,
          brand: _brandCtrl.text.trim(),
          licenseNumber: _licenseCtrl.text.trim(),
          plate: _plateCtrl.text.trim(),
          insurance: _insuranceCtrl.text.trim(),
          couleur: _couleurCtrl.text.trim(),
          carteGrise: _carteGriseCtrl.text.trim(),
        );
    if (success && mounted) {
      context.goNamed(
        RouteNames.verification,
        extra: VerificationArgs(
          email: _emailCtrl.text.trim(),
          telephone: _phoneCtrl.text.replaceAll(' ', ''),
        ),
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
        /*leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.dark),
          onPressed: () =>
              _currentStep > 0 ? _prevStep() : context.goNamed(RouteNames.onboarding),
        ),*/
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
            locating: _locating,
            onLocate: _useMyLocation,
            onNext: _nextStep,
          ),
          _Step2(
            formKey: _step2Key,
            vehicleType: _vehicleType,
            brandCtrl: _brandCtrl,
            licenseCtrl: _licenseCtrl,
            plateCtrl: _plateCtrl,
            insuranceCtrl: _insuranceCtrl,
            couleurCtrl: _couleurCtrl,
            carteGriseCtrl: _carteGriseCtrl,
            isLoading: state.isLoading,
            error: state.error,
            onVehicleTypeChanged: (v) => setState(() => _vehicleType = v),
            onBack: _prevStep,
            onNext: _nextStep,
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

// ── Deux champs côte à côte ─────────────────────────────────────
// Alignés en haut : un message d'erreur sous l'un ne décale pas l'autre.
class _FieldPair extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _FieldPair({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppDimens.md),
        Expanded(child: right),
      ],
    );
  }
}

// ── Champ obligatoire avec son label ────────────────────────────
class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  /// Numéro de document : majuscules, lettres, chiffres, espaces,
  /// tirets et barres obliques, 25 caractères au plus. Assez souple
  /// pour les anciens et nouveaux formats.
  final bool reference;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.reference = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        TextFormField(
          controller: controller,
          textCapitalization: reference
              ? TextCapitalization.characters
              : TextCapitalization.words,
          inputFormatters: reference
              ? [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-/]')),
                  LengthLimitingTextInputFormatter(25),
                  _UpperCaseFormatter(),
                ]
              : null,
          decoration: _inputDeco(hint: hint),
          validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
        ),
      ],
    );
  }
}

class _ContinueLabel extends StatelessWidget {
  const _ContinueLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Continuer'),
        SizedBox(width: AppDimens.sm),
        Icon(Icons.arrow_forward_rounded, size: 20),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

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
  final bool locating;
  final VoidCallback onLocate;
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
    required this.locating,
    required this.onLocate,
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
                text: 'Créez votre ',
                style: AppTextStyles.h2,
                children: [
                  TextSpan(
                    text: 'compte pro',
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
              decoration: _inputDeco(hint: '622 12 34 56'),
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
              decoration: _inputDeco(hint: 'Quartier, Ville').copyWith(
                // Fond orange clair : le bouton se distingue du champ
                // et se lit comme quelque chose sur quoi appuyer.
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Material(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    child: InkWell(
                      onTap: locating ? null : onLocate,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      child: SizedBox(
                        width: 44,
                        child: Center(
                          child: locating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.secondary),
                                )
                              : const Icon(Icons.my_location_rounded,
                                  color: AppColors.secondary, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Adresse requise' : null,
            ),
            // L'icône seule ne suffit pas à tout le monde : le lien
            // dit en toutes lettres ce qu'elle fait.
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: locating ? null : onLocate,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.location_on_rounded, size: 16),
                label: Text(
                  locating
                      ? 'Recherche de votre position…'
                      : 'Utiliser ma position actuelle',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.secondary),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.xl),

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
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(13),
                    ]
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
                child: const _ContinueLabel(),
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
  final TextEditingController brandCtrl;
  final TextEditingController licenseCtrl;
  final TextEditingController plateCtrl;
  final TextEditingController insuranceCtrl;
  final TextEditingController couleurCtrl;
  final TextEditingController carteGriseCtrl;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onVehicleTypeChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _Step2({
    required this.formKey,
    required this.vehicleType,
    required this.brandCtrl,
    required this.licenseCtrl,
    required this.plateCtrl,
    required this.insuranceCtrl,
    required this.couleurCtrl,
    required this.carteGriseCtrl,
    required this.isLoading,
    required this.error,
    required this.onVehicleTypeChanged,
    required this.onBack,
    required this.onNext,
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
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Retour',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: AppColors.dark),
                ),
                const SizedBox(width: AppDimens.xs),
                RichText(
                  text: TextSpan(
                    text: 'Votre ',
                    style: AppTextStyles.h2,
                    children: [
                      TextSpan(
                        text: 'véhicule',
                        style:
                            AppTextStyles.h2.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.xs),
            Text('Sélectionnez votre moyen de transport.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppDimens.xxl),

            // Sélecteur véhicule
            const _Label('Type de véhicule'),
            // IntrinsicHeight : les trois cartes gardent la même hauteur
            // même si un sous-titre passe sur deux lignes.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _VehicleCard(
                      image: 'assets/images/moto.png',
                      label: 'Moto',
                      description: 'Rapide et flexible',
                      selected: vehicleType == 'MOTO',
                      onTap: () => onVehicleTypeChanged('MOTO'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: _VehicleCard(
                      image: 'assets/images/voiture.png',
                      label: 'Voiture',
                      description: 'Longues distances',
                      selected: vehicleType == 'VOITURE',
                      onTap: () => onVehicleTypeChanged('VOITURE'),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: _VehicleCard(
                      image: 'assets/images/cargo.png',
                      label: 'Cargo',
                      description: 'Gros volumes',
                      selected: vehicleType == 'CARGO',
                      onTap: () => onVehicleTypeChanged('CARGO'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.xxl),

            // Titre de section
            Row(
              children: [
                const Icon(Icons.assignment_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppDimens.sm),
                Text('Informations du véhicule',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.primary)),
                const SizedBox(width: AppDimens.md),
                const Expanded(child: Divider(color: AppColors.grey200)),
              ],
            ),
            const SizedBox(height: AppDimens.lg),

            // Le véhicule lui-même
            _FieldPair(
              left: _LabeledField(
                label: 'Marque',
                controller: brandCtrl,
                hint: vehicleType == 'MOTO' ? 'Yamaha' : 'Toyota',
              ),
              right: _LabeledField(
                label: 'Couleur',
                controller: couleurCtrl,
                hint: 'Noir',
              ),
            ),
            const SizedBox(height: AppDimens.lg),

            // Ses papiers : plaque et carte grise vont ensemble.
            // Format des plaques depuis 2021 : AB-123 [02] pour les
            // voitures, AB 012 A [02] pour les motos — le nombre final
            // est le code de la région (02 = Conakry). Les anciennes
            // plaques circulent encore : ce n'est qu'un exemple, aucun
            // format n'est imposé.
            _FieldPair(
              left: _LabeledField(
                label: 'Immatriculation',
                controller: plateCtrl,
                hint: vehicleType == 'MOTO' ? 'AB-012-A-02' : 'AB-123-02',
                reference: true,
              ),
              right: _LabeledField(
                label: 'Carte grise',
                controller: carteGriseCtrl,
                hint: 'N° de carte',
                reference: true,
              ),
            ),
            const SizedBox(height: AppDimens.lg),

            // Les papiers du conducteur. Aucun format officiel publié
            // pour ces numéros : on indique où le trouver, sans exemple
            // inventé qui induirait en erreur.
            _FieldPair(
              left: _LabeledField(
                label: 'N° de permis',
                controller: licenseCtrl,
                hint: 'Sur le permis',
                reference: true,
              ),
              right: _LabeledField(
                label: 'N° d\'assurance',
                controller: insuranceCtrl,
                hint: 'N° de police',
                reference: true,
              ),
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
                onPressed: isLoading ? null : onNext,
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.white),
                      )
                    : const _ContinueLabel(),
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
  final String image;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.image,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        // Léger grossissement de la carte choisie : le changement se
        // voit même du coin de l'œil.
        scale: selected ? 1.0 : 0.98,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.xs, vertical: AppDimens.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySurface : AppColors.grey100,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.grey100,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Les images ont un fond transparent : elles se posent
              // aussi bien sur le gris clair que sur le bleu de sélection.
              SizedBox(
                height: 64,
                child: Image.asset(image, fit: BoxFit.contain),
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.primary : AppColors.dark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey500, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
