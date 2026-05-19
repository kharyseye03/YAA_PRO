import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/constants.dart';
import 'core/utils/app_router.dart';

void main() {
  runApp(const ProviderScope(child: YaaProApp()));
}

class YaaProApp extends StatelessWidget {
  const YaaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Taille de référence : iPhone 14 Pro
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) => MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}
