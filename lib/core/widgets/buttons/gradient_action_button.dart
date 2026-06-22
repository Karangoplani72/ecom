import 'package:flutter/material.dart';

class GradientActionButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const GradientActionButton({
    super.key,
    required this.text,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF6A5ACD), Color(0xFFC040FF)], // Deep Purple to Pink/Purple
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC040FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Center(
                child: isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              if (!isLoading)
                Positioned(
                  right: 8,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFC040FF), size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
