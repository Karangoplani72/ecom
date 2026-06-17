import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_text_field.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
          onSuccess: () {
            // Router redirect handles navigation.
          },
        );
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isSending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your account email and we will send you a reset link.',
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: resetEmailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (!_emailRegex.hasMatch(email)) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a valid email address'),
                              ),
                            );
                            return;
                          }
                          setDialogState(() => isSending = true);
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: email,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Password reset link sent to $email',
                                ),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => isSending = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.message ?? 'Failed to send reset link',
                                ),
                              ),
                            );
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue shopping',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : _showForgotPasswordDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    AppPrimaryButton(
                      text: 'Log In',
                      isLoading: authState.isLoading,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: authState.isLoading
                              ? null
                              : () => context.push('/signup'),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
