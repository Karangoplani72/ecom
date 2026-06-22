import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

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
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                blurRadius: 32,
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
