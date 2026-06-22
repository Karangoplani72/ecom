import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ecom/core/widgets/inputs/premium_form_field.dart';
import 'package:ecom/core/widgets/buttons/gradient_action_button.dart';
import 'package:ecom/features/auth/presentation/widgets/auth_3d_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authControllerProvider.notifier)
        .loginWithCredentials(
          _emailController.text.trim(),
          _passwordController.text,
          onFailure: (message) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          onSuccess: () {},
        );
  }

  Widget _buildSocialButton(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B30) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF6C63FF).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              color: isDark ? Colors.white : Colors.black87,
              size: icon == Icons.g_mobiledata ? 32 : 24,
            ),
          ),
        ),
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
      title: 'Welcome Back!',
      subtitle: 'Login to continue shopping',
      centerObject: const Painted3DShoppingBag(size: 140, color: Color(0xFF9B7DFF)),
      floatingObjects: [
        // Gift box - left
        FloatingObject3D(
          child: const Painted3DGiftBox(size: 55, color: Color(0xFF6C63FF)),
          dx: -120,
          dy: -10,
          delay: 0.3,
          depth: 0.8,
        ),
        // Percent badge - right
        FloatingObject3D(
          child: const Painted3DPercentBadge(size: 45),
          dx: 90,
          dy: -20,
          delay: 0.6,
          depth: 1.2,
        ),
        // Small purple sphere - top right
        FloatingObject3D(
          child: const PaintedSphere(size: 28, baseColor: Color(0xFF8B5CF6)),
          dx: 110,
          dy: -90,
          delay: 0.1,
          depth: 1.5,
        ),
        // Small pink sphere - bottom left
        FloatingObject3D(
          child: const PaintedSphere(size: 20, baseColor: Color(0xFFEC4899)),
          dx: -90,
          dy: 60,
          delay: 0.8,
          depth: 0.6,
        ),
      ],
      formContent: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumFormField(
              controller: _emailController,
              hint: 'Email or Phone',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            PremiumFormField(
              controller: _passwordController,
              hint: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      height: 22,
                      width: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? true),
                        activeColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        side: BorderSide(
                          color: isDark ? Colors.white30 : Colors.black26,
                          width: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Remember me',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: const Color(0xFF8B5CF6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            GradientActionButton(
              text: 'Login',
              onPressed: _login,
              isLoading: authState.isLoading,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(Icons.g_mobiledata, 'Google', () {}),
                const SizedBox(width: 20),
                _buildSocialButton(Icons.apple, 'Apple', () {}),
                const SizedBox(width: 20),
                _buildSocialButton(Icons.facebook_rounded, 'Facebook', () {}),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/signup'),
                  child: Text(
                    'Register',
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
