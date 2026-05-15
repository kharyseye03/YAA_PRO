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
  ConsumerState<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final List<String> _code = List.filled(6, '');
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
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
    super.dispose();
  }

  String get _otp => _code.join();

  Future<void> _verify() async {
    if (_otp.length < 6) return;

    final success = await ref.read(authProvider.notifier).verifyOtp(
      email: widget.email,
      otp: _otp,
    );

    if (success && mounted) {
      context.goNamed(RouteNames.password, extra: widget.email);
    }
  }

  void _onKeyPress(String key) {
    final idx = _code.indexWhere((c) => c.isEmpty);
    if (idx == -1) return;
    setState(() => _code[idx] = key);
    if (_otp.length == 6) _verify();
  }

  void _onDelete() {
    final idx = _code.lastIndexWhere((c) => c.isNotEmpty);
    if (idx == -1) return;
    setState(() => _code[idx] = '');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: AppDimens.xl),
            Text(
              'Code envoyé à\n${widget.email}',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.xxxl),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 44,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _code[i].isNotEmpty
                          ? AppColors.primary
                          : AppColors.grey300,
                      width: 1.5,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusMd),
                    color: AppColors.white,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _code[i],
                    style: AppTextStyles.h3,
                  ),
                );
              }),
            ),

            if (state.error != null) ...[
              const SizedBox(height: AppDimens.lg),
              Text(
                state.error!,
                style:
                    AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],

            const SizedBox(height: AppDimens.xxl),
            _secondsLeft > 0
                ? Text(
                    'Renvoyer le code dans $_secondsLeft s',
                    style: AppTextStyles.bodyMedium,
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

            const Spacer(),
            _NumPad(onKey: _onKeyPress, onDelete: _onDelete),
            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;

  const _NumPad({required this.onKey, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0'];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      children: [
        ...keys.map((k) => k.isEmpty
            ? const SizedBox()
            : TextButton(
                onPressed: () => onKey(k),
                child: Text(k, style: AppTextStyles.h3),
              )),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.backspace_outlined),
        ),
      ],
    );
  }
}
