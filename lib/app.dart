import 'package:ecom/core/providers/connectivity_provider.dart';
import 'package:ecom/core/providers/theme_provider.dart';
import 'package:ecom/core/theme/app_theme.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:ecom/shared/presentation/widgets/offline_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';

class EcomApp extends ConsumerWidget {
  const EcomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    final isConnected = ref.watch(isConnectedProvider).value ?? true;

    return MaterialApp.router(
      title: 'ecom',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      routerConfig: router,
      builder: (context, child) {
        if (!isConnected) {
          return const OfflineOverlay();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
