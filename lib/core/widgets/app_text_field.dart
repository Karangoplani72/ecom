import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}