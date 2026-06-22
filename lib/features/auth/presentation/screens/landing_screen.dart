import 'dart:math' as math;
import 'dart:ui';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _orbitController;
  late AnimationController _pulseController;
  late AnimationController _floatController;

  // Entrance animations
  late Animation<double> _logoFade;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _cardsFade;
  late Animation<double> _ctaFade;
  late Animation<Offset> _ctaSlide;

  @override
  void initState() {
    super.initState();

    // Main entrance sequence
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Continuous orbit for floating elements
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Pulse glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Float bob
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Staggered entrance
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
      ),
    );
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.15, 0.5, curve: Curves.easeOutCubic),
          ),
        );
    _cardsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );
    _ctaFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _ctaSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
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
    final isWide = size.width > 800;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // === LAYER 0: Animated gradient background ===
          _AnimatedBackground(
            orbitController: _orbitController,
            pulseController: _pulseController,
            isDark: isDark,
          ),

          // === LAYER 1: Floating 3D particles ===
          ..._buildFloatingParticles(isDark),

          // === MAIN CONTENT ===
          SafeArea(
            child: isWide
                ? _buildWebLayout(isDark, size)
                : _buildMobileLayout(isDark, size),
          ),
        ],
      ),
    );
  }

  // ─── WEB / TABLET LAYOUT (side-by-side) ───
  Widget _buildWebLayout(bool isDark, Size size) {
    return Row(
      children: [
        // Left: Text + CTA
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(isDark),
                const Spacer(flex: 3),
                _buildHeroText(isDark, isWeb: true),
                const SizedBox(height: 40),
                _buildCTA(isDark, isWeb: true),
                const SizedBox(height: 28),
                _buildSocialProof(isDark),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),

        // Right: 3D floating product showcase
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 48.0, top: 32.0, bottom: 32.0),
            child: ClipRect(
              child: FadeTransition(
                opacity: _cardsFade,
                child: _Floating3DShowcase(
                  orbitController: _orbitController,
                  floatController: _floatController,
                  pulseController: _pulseController,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── MOBILE LAYOUT (stacked) ───
  Widget _buildMobileLayout(bool isDark, Size size) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildLogo(isDark),
            const SizedBox(height: 32),

            // 3D showcase (compact for mobile)
            FadeTransition(
              opacity: _cardsFade,
              child: SizedBox(
                height: size.height * 0.38,
                child: _Floating3DShowcase(
                  orbitController: _orbitController,
                  floatController: _floatController,
                  pulseController: _pulseController,
                  isDark: isDark,
                  compact: true,
                ),
              ),
            ),

            const SizedBox(height: 32),
            _buildHeroText(isDark),
            const SizedBox(height: 36),
            _buildCTA(isDark),
            const SizedBox(height: 32),
            _buildSocialProof(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── LOGO ───
  Widget _buildLogo(bool isDark) {
    return FadeTransition(
      opacity: _logoFade,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.premiumDarkGradient
                  : AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppShadows.primaryGlow,
            ),
            child: const Icon(
              Icons.diamond_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LuxeMarket',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO TEXT ───
  Widget _buildHeroText(bool isDark, {bool isWeb = false}) {
    return SlideTransition(
      position: _heroSlide,
      child: FadeTransition(
        opacity: _heroFade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Premium Marketplace',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              isWeb ? 'Shop the\nFuture, Today.' : 'Shop the\nFuture,\nToday.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isWeb ? 56 : 42,
                height: 1.08,
                letterSpacing: -2,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Immersive 3D product previews. Premium curation.\nA shopping experience unlike any other.',
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                height: 1.6,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CTA BUTTONS ───
  Widget _buildCTA(bool isDark, {bool isWeb = false}) {
    return SlideTransition(
      position: _ctaSlide,
      child: FadeTransition(
        opacity: _ctaFade,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Primary CTA
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final glowOpacity = 0.2 + (_pulseController.value * 0.15);
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: glowOpacity),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(isWeb ? 320 : double.infinity, 60),
                  maximumSize: Size(isWeb ? 400 : double.infinity, 60),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Secondary CTA
            OutlinedButton(
              onPressed: () => context.go('/buyer/home'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                minimumSize: Size(isWeb ? 320 : double.infinity, 56),
                maximumSize: Size(isWeb ? 400 : double.infinity, 56),
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppColors.borderLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Browse as Guest',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SOCIAL PROOF ───
  Widget _buildSocialProof(bool isDark) {
    return FadeTransition(
      opacity: _ctaFade,
      child: Row(
        children: [
          // Stacked avatars
          SizedBox(
            width: 88,
            height: 36,
            child: Stack(
              children: List.generate(3, (i) {
                final colors = [
                  AppColors.primary,
                  AppColors.secondary,
                  const Color(0xFF8B5CF6),
                ];
                return Positioned(
                  left: i * 24.0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i],
                      border: Border.all(
                        color: isDark
                            ? AppColors.backgroundDark
                            : AppColors.backgroundLight,
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '50K+ Happy Shoppers',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (_) => const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '4.9',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FLOATING PARTICLES ───
  List<Widget> _buildFloatingParticles(bool isDark) {
    return List.generate(6, (i) {
      final positions = [
        const [0.1, 0.2],
        const [0.85, 0.15],
        const [0.75, 0.7],
        const [0.15, 0.65],
        const [0.5, 0.1],
        const [0.9, 0.5],
      ];
      final sizes = [6.0, 4.0, 8.0, 5.0, 3.0, 7.0];
      return AnimatedBuilder(
        animation: _orbitController,
        builder: (context, child) {
          final t = (_orbitController.value + i * 0.166) % 1.0;
          final dx = math.sin(t * 2 * math.pi) * 12;
          final dy = math.cos(t * 2 * math.pi) * 8;
          return Positioned(
            left: MediaQuery.of(context).size.width * positions[i][0] + dx,
            top: MediaQuery.of(context).size.height * positions[i][1] + dy,
            child: Container(
              width: sizes[i],
              height: sizes[i],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.25 : 0.15,
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

// =============================================================================
// ANIMATED BACKGROUND
// =============================================================================
class _AnimatedBackground extends StatelessWidget {
  final AnimationController orbitController;
  final AnimationController pulseController;
  final bool isDark;

  const _AnimatedBackground({
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
            // Primary blob - orbits gently
            Positioned(
              left: -120 + math.sin(orbitVal * 2 * math.pi) * 40,
              top: -80 + math.cos(orbitVal * 2 * math.pi) * 30,
              child: Container(
                width: 420 + pulseVal * 30,
                height: 420 + pulseVal * 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),

            // Secondary blob - counter orbit
            Positioned(
              right: -140 + math.cos(orbitVal * 2 * math.pi) * 50,
              bottom: -120 + math.sin(orbitVal * 2 * math.pi) * 35,
              child: Container(
                width: 500 + pulseVal * 20,
                height: 500 + pulseVal * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFF8B5CF6,
                      ).withValues(alpha: isDark ? 0.18 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Accent highlight
            Positioned(
              left: size.width * 0.4 + math.sin(orbitVal * 4 * math.pi) * 20,
              top: size.height * 0.3,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(
                        alpha: isDark ? 0.12 : 0.06,
                      ),
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

// =============================================================================
// 3D FLOATING PRODUCT SHOWCASE
// =============================================================================
class _Floating3DShowcase extends StatelessWidget {
  final AnimationController orbitController;
  final AnimationController floatController;
  final AnimationController pulseController;
  final bool isDark;
  final bool compact;

  const _Floating3DShowcase({
    required this.orbitController,
    required this.floatController,
    required this.pulseController,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        orbitController,
        floatController,
        pulseController,
      ]),
      builder: (context, child) {
        final orbit = orbitController.value;
        final float = floatController.value;
        final pulse = pulseController.value;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // === CENTER CARD (main product - largest) ===
            _build3DCard(
              orbit: orbit,
              float: float,
              pulse: pulse,
              rotateY: math.sin(orbit * 2 * math.pi) * 0.08,
              rotateX: math.cos(orbit * 2 * math.pi) * 0.04,
              translateY: math.sin(float * math.pi) * 12,
              scale: compact ? 0.85 : 1.0,
              child: _ProductCard3D(
                icon: Icons.watch_outlined,
                title: 'Chronograph Elite',
                price: '₹2,499',
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                accentColor: const Color(0xFFE8D5B7),
                isDark: isDark,
                compact: compact,
              ),
            ),

            // === TOP-LEFT CARD (floating) ===
            Align(
              alignment: compact ? const Alignment(-0.9, -0.8) : const Alignment(-0.7, -0.6),
              child: _build3DCard(
                orbit: orbit,
                float: float,
                pulse: pulse,
                rotateY: math.sin((orbit + 0.33) * 2 * math.pi) * 0.15,
                rotateX: math.cos((orbit + 0.33) * 2 * math.pi) * 0.08,
                translateY: math.sin((float + 0.4) * math.pi) * 16,
                scale: compact ? 0.55 : 0.7,
                child: _ProductCard3D(
                  icon: Icons.headset_outlined,
                  title: 'Studio Pro',
                  price: '₹899',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  accentColor: Colors.white,
                  isDark: isDark,
                  compact: compact,
                ),
              ),
            ),

            // === BOTTOM-RIGHT CARD (floating) ===
            Align(
              alignment: compact ? const Alignment(0.9, 0.8) : const Alignment(0.7, 0.6),
              child: _build3DCard(
                orbit: orbit,
                float: float,
                pulse: pulse,
                rotateY: math.sin((orbit + 0.66) * 2 * math.pi) * 0.12,
                rotateX: math.cos((orbit + 0.66) * 2 * math.pi) * 0.06,
                translateY: math.sin((float + 0.7) * math.pi) * 14,
                scale: compact ? 0.5 : 0.65,
                child: _ProductCard3D(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Luxe Tote',
                  price: '₹1,299',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  accentColor: const Color(0xFFD4F4DD),
                  isDark: isDark,
                  compact: compact,
                ),
              ),
            ),

            // === FLOATING ORBIT RING ===
            if (!compact)
              Positioned.fill(
                child: CustomPaint(
                  painter: _OrbitRingPainter(
                    progress: orbit,
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.12 : 0.08,
                    ),
                  ),
                ),
              ),

            // === FLOATING BADGES ===
            Align(
              alignment: compact ? const Alignment(0.6, -0.9) : const Alignment(0.5, -0.8),
              child: Transform.translate(
                offset: Offset(
                  math.sin((orbit + 0.5) * 2 * math.pi) * 6,
                  math.cos(float * math.pi) * 8,
                ),
                child: _FloatingBadge(
                  icon: Icons.verified,
                  label: 'Authentic',
                  color: AppColors.success,
                  isDark: isDark,
                  compact: compact,
                ),
              ),
            ),

            Align(
              alignment: compact ? const Alignment(-0.6, 0.9) : const Alignment(-0.5, 0.8),
              child: Transform.translate(
                offset: Offset(
                  math.cos((orbit + 0.25) * 2 * math.pi) * 8,
                  math.sin(float * math.pi) * 6,
                ),
                child: _FloatingBadge(
                  icon: Icons.local_shipping_outlined,
                  label: 'Free Ship',
                  color: AppColors.secondary,
                  isDark: isDark,
                  compact: compact,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _build3DCard({
    required double orbit,
    required double float,
    required double pulse,
    required double rotateY,
    required double rotateX,
    required double translateY,
    required double scale,
    required Widget child,
  }) {
    // Create perspective transform matrix
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Perspective
      ..rotateY(rotateY)
      ..rotateX(rotateX);
    matrix.storage[13] += translateY; // Y translation

    return Transform(
      transform: matrix,
      alignment: Alignment.center,
      child: Transform.scale(scale: scale, child: child),
    );
  }
}

// =============================================================================
// 3D PRODUCT CARD WIDGET
// =============================================================================
class _ProductCard3D extends StatelessWidget {
  final IconData icon;
  final String title;
  final String price;
  final LinearGradient gradient;
  final Color accentColor;
  final bool isDark;
  final bool compact;

  const _ProductCard3D({
    required this.icon,
    required this.title,
    required this.price,
    required this.gradient,
    required this.accentColor,
    required this.isDark,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = compact ? 180.0 : 220.0;
    final cardHeight = compact ? 240.0 : 300.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Gradient background
            Positioned.fill(
              child: Container(decoration: BoxDecoration(gradient: gradient)),
            ),

            // Inner glass highlight
            Positioned(
              top: -cardHeight * 0.3,
              left: -cardWidth * 0.2,
              child: Container(
                width: cardWidth * 0.8,
                height: cardHeight * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(compact ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product icon area
                  Expanded(
                    child: Center(
                      child: Icon(
                        icon,
                        size: compact ? 56 : 80,
                        color: accentColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ),

                  // Product info
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 14 : 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: compact ? 18 : 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(compact ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: compact ? 14 : 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ORBIT RING PAINTER
// =============================================================================
class _OrbitRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _OrbitRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radiusX = size.width * 0.38;
    final radiusY = size.height * 0.25;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw elliptical orbit with dashes
    final path = Path();
    for (int i = 0; i < 360; i += 8) {
      final angle = i * math.pi / 180;
      final x = center.dx + radiusX * math.cos(angle);
      final y = center.dy + radiusY * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else if (i % 16 == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw orbiting dot
    final dotAngle = progress * 2 * math.pi;
    final dotX = center.dx + radiusX * math.cos(dotAngle);
    final dotY = center.dy + radiusY * math.sin(dotAngle);
    canvas.drawCircle(
      Offset(dotX, dotY),
      4,
      Paint()..color = color.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// =============================================================================
// FLOATING BADGE
// =============================================================================
class _FloatingBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool compact;

  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 10 : 14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 6 : 10,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.06,
            ),
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.08,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 14 : 16, color: color),
              SizedBox(width: compact ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
