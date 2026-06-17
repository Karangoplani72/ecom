import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ecom/core/theme/app_theme.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';

class EnterpriseMarketplaceApp extends ConsumerWidget {
  const EnterpriseMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LuxeMarket',
      debugShowCheckedModeBanner: false,

      // Premium Blue Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      routerConfig: router,
    );
  }
}