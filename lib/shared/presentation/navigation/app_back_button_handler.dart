import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'navigation_history_provider.dart';

class AppBackButtonHandler extends ConsumerStatefulWidget {
  final Widget child;

  const AppBackButtonHandler({super.key, required this.child});

  @override
  ConsumerState<AppBackButtonHandler> createState() => _AppBackButtonHandlerState();
}

class _AppBackButtonHandlerState extends ConsumerState<AppBackButtonHandler> {
  DateTime? _lastBackPress;

  Future<void> _handlePop() async {
    // 1. Try to pop the internal nested navigator first (e.g. pushed routes or dialogs)
    final rootNavigator = Navigator.maybeOf(context);
    if (rootNavigator != null && rootNavigator.canPop()) {
      rootNavigator.pop();
      return;
    }

    // 2. Check global navigation history
    final previousRoute = ref.read(navigationHistoryProvider.notifier).popRoute();

    if (previousRoute != null) {
      // Navigate to the previous top-level route in history
      context.go(previousRoute);
      return;
    }

    // 3. Double-back to exit if at the absolute root of history
    final now = DateTime.now();
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Exit the app
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handlePop();
        }
      },
      child: widget.child,
    );
  }
}
