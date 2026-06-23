import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// PREMIUM ANTI-GRAVITY & GLASSMORPHISM WIDGETS
// ============================================================================

// 1. OrbBackgroundWidget
class OrbBackgroundWidget extends StatefulWidget {
  const OrbBackgroundWidget({super.key});

  @override
  State<OrbBackgroundWidget> createState() => _OrbBackgroundWidgetState();
}

class _OrbBackgroundWidgetState extends State<OrbBackgroundWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  final List<Map<String, dynamic>> _orbConfigs = [
    {
      'color': const Color(0xFFA855F7),
      'size': 120.0,
      'top': 0.08,
      'left': 0.04,
      'dur': 6000,
      'delay': 0.0,
      'opacity': 0.28,
    },
    {
      'color': const Color(0xFFEC4899),
      'size': 80.0,
      'top': 0.55,
      'right': 0.06,
      'dur': 8000,
      'delay': 2.0,
      'opacity': 0.22,
    },
    {
      'color': const Color(0xFF7C3AED),
      'size': 100.0,
      'top': 0.30,
      'left': 0.70,
      'dur': 7000,
      'delay': 1.0,
      'opacity': 0.20,
    },
    {
      'color': const Color(0xFFC084FC),
      'size': 60.0,
      'top': 0.75,
      'left': 0.20,
      'dur': 9000,
      'delay': 3.0,
      'opacity': 0.18,
    },
    {
      'color': const Color(0xFFEC4899),
      'size': 90.0,
      'top': 0.15,
      'right': 0.30,
      'dur': 6000,
      'delay': 4.0,
      'opacity': 0.15,
    },
    {
      'color': const Color(0xFF7C3AED),
      'size': 70.0,
      'top': 0.65,
      'right': 0.40,
      'dur': 8000,
      'delay': 1.5,
      'opacity': 0.20,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controllers = _orbConfigs.map((config) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: config['dur'] as int),
      )..forward();

      c.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          c.reverse();
        } else if (status == AnimationStatus.dismissed) {
          c.forward();
        }
      });

      if (config['delay'] > 0) {
        c.value = (config['delay'] as double) / 10.0;
      }
      return c;
    }).toList();
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Stack(
        children: List.generate(_orbConfigs.length, (index) {
          final config = _orbConfigs[index];
          final color = config['color'] as Color;
          final size = config['size'] as double;
          final opacity = config['opacity'] as double;
          final controller = _controllers[index];

          return Positioned(
            top: config.containsKey('top')
                ? MediaQuery.of(context).size.height * (config['top'] as double)
                : null,
            left: config.containsKey('left')
                ? MediaQuery.of(context).size.width * (config['left'] as double)
                : null,
            right: config.containsKey('right')
                ? MediaQuery.of(context).size.width *
                      (config['right'] as double)
                : null,
            bottom: config.containsKey('bottom')
                ? MediaQuery.of(context).size.height *
                      (config['bottom'] as double)
                : null,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                final floatY = math.sin(controller.value * math.pi * 2) * 20;
                final floatX = math.cos(controller.value * math.pi * 2) * 15;
                return Transform.translate(
                  offset: Offset(floatX, floatY),
                  child: child,
                );
              },
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: opacity),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// 2. FloatingProductWidget
class FloatingProductWidget extends StatefulWidget {
  final Widget child;
  final double floatHeight;
  final Duration duration;
  final double tiltDegrees;

  const FloatingProductWidget({
    super.key,
    required this.child,
    this.floatHeight = 16.0,
    this.duration = const Duration(seconds: 3),
    this.tiltDegrees = 1.0,
  });

  @override
  State<FloatingProductWidget> createState() => _FloatingProductWidgetState();
}

class _FloatingProductWidgetState extends State<FloatingProductWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _translateY = Tween<double>(
      begin: 0.0,
      end: -widget.floatHeight,
    ).animate(curvedAnimation);
    _rotate = Tween<double>(
      begin: -widget.tiltDegrees * math.pi / 180,
      end: widget.tiltDegrees * math.pi / 180,
    ).animate(curvedAnimation);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!MediaQuery.of(context).disableAnimations) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.translationValues(0.0, _translateY.value, 0.0)
              ..rotateZ(_rotate.value),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// 3. GlowingPedestalWidget
class GlowingPedestalWidget extends StatefulWidget {
  final double width;
  final double height;

  const GlowingPedestalWidget({super.key, this.width = 220, this.height = 56});

  @override
  State<GlowingPedestalWidget> createState() => _GlowingPedestalWidgetState();
}

class _GlowingPedestalWidgetState extends State<GlowingPedestalWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _glowOpacity = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!MediaQuery.of(context).disableAnimations) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return _buildPedestal(1.0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _buildPedestal(_glowOpacity.value);
      },
    );
  }

  Widget _buildPedestal(double glow) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.elliptical(widget.width / 2, widget.height / 2),
        ),
        gradient: const RadialGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95), Colors.transparent],
          stops: [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: glow * 0.6),
            blurRadius: 40,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: glow * 0.3),
            blurRadius: 80,
            spreadRadius: 8,
          ),
        ],
      ),
    );
  }
}

// 4. GlassCardWidget
class GlassCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const GlassCardWidget({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// 5. ShimmerBox
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.09),
              isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ],
            stops: [0.0, _shimmerCtrl.value, 1.0],
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// 6. GradientButton
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.width,
    this.gradient,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultGradient = const LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    );
    final buttonGradient = widget.gradient ?? defaultGradient;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null && !widget.isLoading) _ctrl.forward();
      },
      onTapUp: (_) {
        if (widget.onTap != null && !widget.isLoading) {
          _ctrl.reverse();
          widget.onTap!();
        }
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.96).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
        ),
        child: Container(
          width: widget.width ?? double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: widget.onTap == null ? null : buttonGradient,
            color: widget.onTap == null
                ? Colors.white.withValues(alpha: 0.08)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onTap == null
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    color: widget.onTap == null ? Colors.white54 : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

// 7. GradientText
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient? gradient;

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradient = const LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    );

    return ShaderMask(
      shaderCallback: (bounds) =>
          (gradient ?? defaultGradient).createShader(bounds),
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

// 8. PulsingDot
class PulsingDot extends StatefulWidget {
  final double size;
  final Color color;

  const PulsingDot({
    super.key,
    this.size = 12.0,
    this.color = const Color(0xFFEC4899),
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: widget.size * 2.2,
                  height: widget.size * 2.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.8),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 9. AnimatedCounter
class AnimatedCounter extends StatelessWidget {
  final int count;
  final TextStyle style;

  const AnimatedCounter({
    super.key,
    required this.count,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.5),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        '$count',
        key: ValueKey<int>(count),
        style: style,
      ),
    );
  }
}
