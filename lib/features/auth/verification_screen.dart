import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';
import 'providers/auth_notifier.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    final success = await ref.read(authProvider.notifier).verifyOtp(
          email: widget.email,
          otp: _otp,
        );
    if (success && mounted) context.goNamed(RouteNames.home);
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 6) { _verify(); }
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
          onPressed: () => context.goNamed(RouteNames.register),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimens.lg),
              Text('Vérification', style: AppTextStyles.h2),
              const SizedBox(height: AppDimens.sm),
              RichText(
                text: TextSpan(
                  text: 'Un code à 6 chiffres a été envoyé à ',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.grey600),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.dark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.xxxl),

              // Champs OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextFormField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: AppTextStyles.h3,
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                          borderSide: const BorderSide(
                              color: AppColors.grey300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (v) => _onChanged(v, i),
                    ),
                  );
                }),
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

              const SizedBox(height: AppDimens.xxl),

              // Renvoyer
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Renvoyer le code dans $_secondsLeft s',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.grey500),
                      )
                    : TextButton(
                        onPressed: () {
                          ref
                              .read(authProvider.notifier)
                              .resendCode(email: widget.email);
                          _startTimer();
                        },
                        child: const Text('Renvoyer le code'),
                      ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: state.isLoading || _otp.length < 6
                      ? null
                      : _verify,
                  child: state.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.white),
                        )
                      : const Text('Vérifier'),
                ),
              ),
              const SizedBox(height: AppDimens.xl),
            ],
          ),
        ),
      ),
    );
  }
}
