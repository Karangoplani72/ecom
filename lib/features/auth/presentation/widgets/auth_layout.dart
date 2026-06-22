import 'dart:math' as math;
import 'package:ecom/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatefulWidget {
  final Widget formContent;
  final List<Widget> showcaseCards;

  const AuthLayout({
    super.key,
    required this.formContent,
    required this.showcaseCards,
  });

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _showcaseFade;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _showcaseFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          // 1. Animated background gradients
          Positioned.fill(
            child: _AnimatedAuthBackground(
              orbitController: _orbitController,
              pulseController: _pulseController,
              isDark: isDark,
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: isWide
                ? _buildWebLayout(isDark, size)
                : _buildMobileLayout(isDark, size),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(bool isDark, Size size) {
    return Row(
      children: [
        // Left: Auth Form
        Expanded(
          flex: 4,
          child: SlideTransition(
            position: _formSlide,
            child: FadeTransition(
              opacity: _formFade,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                child: widget.formContent,
              ),
            ),
          ),
        ),

        // Right: 3D Showcase
        Expanded(
          flex: 6,
          child: FadeTransition(
            opacity: _showcaseFade,
            child: _FloatingAuthShowcase(
              orbitController: _orbitController,
              floatController: _floatController,
              pulseController: _pulseController,
              cards: widget.showcaseCards,
              compact: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, Size size) {
    return Stack(
      children: [
        // Background 3D Showcase (behind form on mobile)
        Positioned(
          top: size.height * 0.05,
          left: 0,
          right: 0,
          height: size.height * 0.4,
          child: FadeTransition(
            opacity: _showcaseFade,
            child: _FloatingAuthShowcase(
              orbitController: _orbitController,
              floatController: _floatController,
              pulseController: _pulseController,
              cards: widget.showcaseCards,
              compact: true,
            ),
          ),
        ),

        // Foreground Form
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: size.height * 0.35,
              left: 24,
              right: 24,
              bottom: 40,
            ),
            child: SlideTransition(
              position: _formSlide,
              child: FadeTransition(
                opacity: _formFade,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : AppColors.surfaceLight.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark.withValues(alpha: 0.5) : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: widget.formContent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedAuthBackground extends StatelessWidget {
  final AnimationController orbitController;
  final AnimationController pulseController;
  final bool isDark;

  const _AnimatedAuthBackground({
    required this.orbitController,
    required this.pulseController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([orbitController, pulseController]),
      builder: (context, child) {
        final orbitVal = orbitController.value;
        final pulseVal = pulseController.value;
        final size = MediaQuery.of(context).size;

        return Stack(
          children: [
            Positioned(
              left: size.width * 0.2 + math.sin(orbitVal * 2 * math.pi) * 100,
              top: size.height * 0.2 + math.cos(orbitVal * 2 * math.pi) * 80,
              child: Container(
                width: 500 + pulseVal * 50,
                height: 500 + pulseVal * 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: size.width * 0.1 + math.cos((orbitVal + 0.5) * 2 * math.pi) * 120,
              bottom: size.height * 0.1 + math.sin((orbitVal + 0.5) * 2 * math.pi) * 90,
              child: Container(
                width: 600 + pulseVal * 40,
                height: 600 + pulseVal * 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.12 : 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FloatingAuthShowcase extends StatelessWidget {
  final AnimationController orbitController;
  final AnimationController floatController;
  final AnimationController pulseController;
  final List<Widget> cards;
  final bool compact;

  const _FloatingAuthShowcase({
    required this.orbitController,
    required this.floatController,
    required this.pulseController,
    required this.cards,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([orbitController, floatController, pulseController]),
      builder: (context, child) {
        final orbit = orbitController.value;
        final float = floatController.value;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Center Card (index 0)
            if (cards.isNotEmpty)
              _buildAuthCard(
                rotateY: math.sin(orbit * 2 * math.pi) * 0.08,
                rotateX: math.cos(orbit * 2 * math.pi) * 0.04,
                translateY: math.sin(float * math.pi) * 12,
                scale: compact ? 0.8 : 1.0,
                child: cards[0],
              ),

            // Top Right Card (index 1)
            if (cards.length > 1)
              Align(
                alignment: compact ? const Alignment(0.6, -0.7) : const Alignment(0.4, -0.5),
                child: _buildAuthCard(
                  rotateY: math.sin((orbit + 0.3) * 2 * math.pi) * 0.12,
                  rotateX: math.cos((orbit + 0.3) * 2 * math.pi) * 0.06,
                  translateY: math.sin((float + 0.3) * math.pi) * 15,
                  scale: compact ? 0.5 : 0.65,
                  child: cards[1],
                ),
              ),

            // Bottom Left Card (index 2)
            if (cards.length > 2)
              Align(
                alignment: compact ? const Alignment(-0.6, 0.7) : const Alignment(-0.4, 0.5),
                child: _buildAuthCard(
                  rotateY: math.sin((orbit + 0.6) * 2 * math.pi) * 0.15,
                  rotateX: math.cos((orbit + 0.6) * 2 * math.pi) * 0.08,
                  translateY: math.sin((float + 0.7) * math.pi) * 10,
                  scale: compact ? 0.45 : 0.6,
                  child: cards[2],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAuthCard({
    required double rotateY,
    required double rotateX,
    required double translateY,
    required double scale,
    required Widget child,
  }) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(rotateY)
      ..rotateX(rotateX);
    matrix.storage[13] += translateY;

    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: Transform.scale(
        scale: scale,
        child: child,
      ),
    );
  }
}
