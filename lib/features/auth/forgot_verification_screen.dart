import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/app_router.dart';

class ForgotVerificationScreen extends StatelessWidget {
  final String email;
  const ForgotVerificationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        child: Column(
          children: [
            const SizedBox(height: AppDimens.xl),
            Text(
              'Code envoyé à $email',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => context.goNamed(
                RouteNames.resetPassword,
                extra: email,
              ),
              child: const Text(AppStrings.next),
            ),
            const SizedBox(height: AppDimens.xl),
          ],
        ),
      ),
    );
  }
}
