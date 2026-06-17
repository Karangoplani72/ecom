import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 96,
                    color: colorScheme.primary,
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'LuxeMarket',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Premium marketplace for buyers, sellers and enterprise commerce.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 56),

                  AppPrimaryButton(
                    text: 'Get Started',
                    onPressed: () {
                      context.go('/login');
                    },
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      context.go('/buyer/home');
                    },
                    child: const Text('Browse as Guest'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
