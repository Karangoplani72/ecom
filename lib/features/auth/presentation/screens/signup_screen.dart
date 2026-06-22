import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/core/widgets/inputs/premium_form_field.dart';
import 'package:ecom/core/widgets/buttons/gradient_action_button.dart';
import 'package:ecom/features/auth/presentation/widgets/auth_3d_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _showError('Please agree to the Terms & Conditions');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .registerWithCredentials(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          onFailure: (message) {
            if (!mounted) return;
            _showError(message);
          },
          onSuccess: () {
            if (!mounted) return;
            context.go('/');
          },
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Auth3DLayout(
      isDark: isDark,
      showBackButton: true,
      title: 'Create Account',
      subtitle: 'Join us and start shopping',
      centerObject: const Painted3DUserAvatar(size: 130),
      floatingObjects: [
        // Shield - right side
        FloatingObject3D(
          child: const Painted3DShield(size: 45),
          dx: 90,
          dy: -30,
          delay: 0.2,
          depth: 1.0,
        ),
        // Gift box - left
        FloatingObject3D(
          child: const Painted3DGiftBox(size: 50, color: Color(0xFF6C63FF)),
          dx: -110,
          dy: 10,
          delay: 0.5,
          depth: 0.8,
        ),
        // Heart - top right
        FloatingObject3D(
          child: const Painted3DHeart(size: 25),
          dx: 100,
          dy: -100,
          delay: 0.7,
          depth: 1.3,
        ),
        // Small sphere - bottom right
        FloatingObject3D(
          child: const PaintedSphere(size: 18, baseColor: Color(0xFFEC4899)),
          dx: 80,
          dy: 70,
          delay: 0.4,
          depth: 0.9,
        ),
        // Small sphere - top left
        FloatingObject3D(
          child: const PaintedSphere(size: 14, baseColor: Color(0xFF8B5CF6)),
          dx: -80,
          dy: -70,
          delay: 0.9,
          depth: 1.1,
        ),
      ],
      formContent: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumFormField(
              controller: _nameController,
              hint: 'Full Name',
              prefixIcon: Icons.person_outline_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            PremiumFormField(
              controller: _emailController,
              hint: 'Email Address',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            PremiumFormField(
              controller: _passwordController,
              hint: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            PremiumFormField(
              controller: _confirmPasswordController,
              hint: 'Confirm Password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            // Terms & Conditions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    activeColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    side: BorderSide(
                      color: isDark ? Colors.white30 : Colors.black26,
                      width: 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      text: 'I agree to the ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: const Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            GradientActionButton(
              text: 'Create Account',
              isLoading: authState.isLoading,
              onPressed: _signup,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: const Color(0xFF8B5CF6),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
