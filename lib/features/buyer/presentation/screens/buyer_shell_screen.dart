import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/core/widgets/app_bottom_nav_bar.dart';

class BuyerShellScreen extends StatelessWidget {
  final Widget child;

  const BuyerShellScreen({
    super.key,
    required this.child,
  });

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/buyer/products')) {
      return 1;
    }

    if (location.startsWith('/buyer/profile')) {
      return 2;
    }

    if (location.startsWith('/buyer/menu')) {
      return 3;
    }

    return 0;
  }

  void _onDestinationSelected(
      BuildContext context,
      int index,
      ) {
    switch (index) {
      case 0:
        context.go('/buyer/home');
        break;

      case 1:
        context.go('/buyer/products');
        break;

      case 2:
        context.go('/buyer/profile');
        break;

      case 3:
        context.go('/buyer/menu');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex =
    _calculateIndex(context);

    return Scaffold(
      body: child,

      bottomNavigationBar: AppBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          _onDestinationSelected(
            context,
            index,
          );
        },
      ),
    );
  }
}