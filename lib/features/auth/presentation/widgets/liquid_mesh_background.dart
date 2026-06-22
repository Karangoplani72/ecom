import 'dart:math' as math;
import 'package:ecom/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class LiquidMeshBackground extends StatefulWidget {
  final bool isDark;
  const LiquidMeshBackground({super.key, required this.isDark});

  @override
  State<LiquidMeshBackground> createState() => _LiquidMeshBackgroundState();
}

class _LiquidMeshBackgroundState extends State<LiquidMeshBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LiquidPainter(
            animation: _controller.value,
            isDark: widget.isDark,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double animation;
  final bool isDark;

  _LiquidPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    
    // Background base
    canvas.drawRect(
      rect,
      Paint()..color = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FA),
    );

    // Common blur for liquid effect
    final paintBlur = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 150)
      ..blendMode = isDark ? BlendMode.screen : BlendMode.multiply;

    final t = animation * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    // Blob 1: Top Left - Primary Color
    final blob1Path = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(
          w * 0.3 + math.sin(t) * w * 0.2,
          h * 0.3 + math.cos(t * 0.8) * h * 0.2,
        ),
        width: w * 0.6 + math.sin(t * 1.5) * 100,
        height: h * 0.6 + math.cos(t * 1.2) * 100,
      ));
    
    // Blob 2: Bottom Right - Secondary/Accent Color
    final blob2Path = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(
          w * 0.7 + math.cos(t * 1.1) * w * 0.2,
          h * 0.7 + math.sin(t * 0.9) * h * 0.2,
        ),
        width: w * 0.7 + math.cos(t * 1.3) * 150,
        height: h * 0.7 + math.sin(t * 1.4) * 150,
      ));

    // Blob 3: Center tracking - Third Color
    final blob3Path = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(
          w * 0.5 + math.sin(t * 0.7) * w * 0.3,
          h * 0.5 + math.cos(t * 1.1) * h * 0.3,
        ),
        width: w * 0.5,
        height: h * 0.5,
      ));

    // Colors adjusted for vibrant glassmorphism contrast
    canvas.drawPath(
      blob1Path,
      paintBlur..color = isDark ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.3),
    );
    canvas.drawPath(
      blob2Path,
      paintBlur..color = isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.5) : const Color(0xFF8B5CF6).withValues(alpha: 0.25),
    );
    canvas.drawPath(
      blob3Path,
      paintBlur..color = isDark ? const Color(0xFFEC4899).withValues(alpha: 0.4) : const Color(0xFFEC4899).withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.isDark != isDark;
  }
}
