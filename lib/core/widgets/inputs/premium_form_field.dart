import 'package:flutter/material.dart';

class PremiumFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final String? label;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool isDark;
  final ValueChanged<String>? onChanged;

  const PremiumFormField({
    super.key,
    this.controller,
    required this.hint,
    this.label,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.isDark = false,
    this.onChanged,
  });

  @override
  State<PremiumFormField> createState() => _PremiumFormFieldState();
}

class _PremiumFormFieldState extends State<PremiumFormField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF9F9FC);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white30 : Colors.black38;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            style: TextStyle(color: textColor),
            validator: widget.validator,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: hintColor, size: 20) : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: hintColor, size: 20),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }
}
