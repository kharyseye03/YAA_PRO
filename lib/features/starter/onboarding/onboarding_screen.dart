import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/app_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Bienvenue sur\n${AppStrings.appName}',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.lg),
              Text(
                AppStrings.appTagline,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.goNamed(RouteNames.login),
                child: const Text(AppStrings.login),
              ),
              const SizedBox(height: AppDimens.md),
              OutlinedButton(
                onPressed: () => context.goNamed(RouteNames.register),
                child: const Text(AppStrings.register),
              ),
              const SizedBox(height: AppDimens.xl),
            ],
          ),
        ),
      ),
    );
  }
}
