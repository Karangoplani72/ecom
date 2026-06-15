import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecom/core/theme/app_theme.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';

class EnterpriseMarketplaceApp extends ConsumerWidget {
  const EnterpriseMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the GoRouter provider to handle all navigation, deep linking, and guard checks
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: "Anjali's Nail Art",
      debugShowCheckedModeBanner: false, // Hide the debug banner for a clean look

      // Apply our centralized luxury design system
      theme: AppTheme.lightTheme,

      // Pass the router configuration
      routerConfig: goRouter,
    );
  }
}