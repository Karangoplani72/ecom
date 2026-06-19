import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ecom/core/providers/theme_provider.dart';
import 'package:ecom/core/theme/app_theme.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';

class EcomApp extends ConsumerWidget {
  const EcomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'ecom',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      routerConfig: router,
    );
  }
}