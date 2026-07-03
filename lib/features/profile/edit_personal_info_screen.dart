import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api/api_config.dart';
import '../../core/constants/constants.dart';
import '../auth/providers/auth_notifier.dart';
import '../auth/providers/driver_provider.dart';

// ── Label (même style que register/login) ────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style:
              AppTextStyles.labelSmall.copyWith(color: AppColors.grey800),
        ),
      ),
    );
  }
}

// ── InputDecoration (même style que register/login) ──────────────
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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        borderSide: const BorderSide(color: AppColors.grey200),
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

class EditPersonalInfoScreen extends ConsumerStatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  ConsumerState<EditPersonalInfoScreen> createState() =>
      _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState
    extends ConsumerState<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  File? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final driver = ref.read(driverDetailProvider).valueOrNull;
    _firstNameController =
        TextEditingController(text: driver?.firstName ?? '');
    _lastNameController = TextEditingController(text: driver?.lastName ?? '');
    _emailController = TextEditingController(text: driver?.email ?? '');
    _phoneController = TextEditingController(text: driver?.telephone ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) setState(() => _pickedImage = File(picked.path));
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.code == 'channel-error'
          ? 'Caméra non disponible sur ce simulateur. Utilisez un vrai appareil.'
          : 'Impossible d\'accéder à la ${source == ImageSource.camera ? 'caméra' : 'galerie'} : ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimens.lg),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Choisir une photo',
                  style: AppTextStyles.h4
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppDimens.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Galerie',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Caméra',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28.r),
          ),
          const SizedBox(height: AppDimens.sm),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(apiServiceProvider).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            telephone: _phoneController.text.trim(),
            imagePath: _pickedImage?.path,
          );
      ref.invalidate(driverDetailProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(driverDetailProvider).valueOrNull;
    final imageUrl =
        _pickedImage == null && driver?.imageFileName != null
            ? ApiConfig.getImageUrl(driver!.imageFileName!)
            : null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.screenPadding.w),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: AppDimens.xxl.h),

                    // ── Avatar ───────────────────────────────
                    GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Stack(
                        children: [
                          Container(
                            width: 88.r,
                            height: 88.r,
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.grey200, width: 2),
                              image: _pickedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_pickedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: _pickedImage == null && imageUrl == null
                                ? Icon(Icons.person_rounded,
                                    color: AppColors.grey400, size: 44.r)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32.r,
                              height: 32.r,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.white, width: 2),
                              ),
                              child: Icon(Icons.camera_alt_outlined,
                                  color: AppColors.white, size: 16.r),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppDimens.xxxl.h),

                    const _Label('Prénom'),
                    TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDeco(),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Champ requis'
                          : null,
                    ),
                    SizedBox(height: AppDimens.lg.h),

                    const _Label('Nom'),
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDeco(),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Champ requis'
                          : null,
                    ),
                    SizedBox(height: AppDimens.lg.h),

                    const _Label('Email'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      decoration: _inputDeco(),
                    ),
                    SizedBox(height: AppDimens.lg.h),

                    const _Label('Téléphone'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: false,
                      decoration: _inputDeco(),
                    ),
                    SizedBox(height: AppDimens.xxl.h),
                  ],
                ),
              ),
            ),
          ),

          // ── Bouton Enregistrer ───────────────────────
          Container(
            padding: EdgeInsets.only(
              left: AppDimens.screenPadding.w,
              right: AppDimens.screenPadding.w,
              top: 12.h,
              bottom: MediaQuery.of(context).padding.bottom + 12.h,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.grey200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                child: Text(
                    _isSaving ? 'Enregistrement...' : 'Enregistrer'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12.h,
            left: AppDimens.screenPadding.w,
            right: AppDimens.screenPadding.w,
            bottom: 16.h,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.dark,
                    size: 22.r,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Modifier mes informations',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.grey200),
      ],
    );
  }
}
