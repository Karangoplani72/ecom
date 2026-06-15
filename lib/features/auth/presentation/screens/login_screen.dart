import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _executeLogin() {
    FocusScope.of(context).unfocus(); // Dismiss keyboard

    ref.read(authControllerProvider.notifier).loginWithCredentials(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      onFailure: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorCoral,
          ),
        );
      },
      onSuccess: () {
        // GoRouter's redirect listener will automatically intercept this
        // successful state change and route the user to their respective dashboard!
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the auth state to show a loading spinner when authenticating
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Luxury Branding Header
                const Icon(Icons.spa, size: 64, color: AppTheme.blushPink),
                const SizedBox(height: 16),
                const Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.charcoalText,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'Sign in to continue your journey',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.slateGreyText, fontSize: 16),
                ),
                const SizedBox(height: 48),

                // Input Fields utilizing our AppTheme decorations
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.roseGold),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.roseGold),
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Action Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _executeLogin,
                    child: isLoading
                        ? const CircularProgressIndicator(color: AppTheme.surfaceWhite)
                        : const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}