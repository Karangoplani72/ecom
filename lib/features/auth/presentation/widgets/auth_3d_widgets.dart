import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A premium 3D-style floating sphere painted entirely with Flutter.
/// Uses radial gradients and shadows to achieve a realistic 3D look.
class PaintedSphere extends StatelessWidget {
  final double size;
  final Color baseColor;
  final Color highlightColor;

  const PaintedSphere({
    super.key,
    required this.size,
    required this.baseColor,
    this.highlightColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SpherePainter(
        baseColor: baseColor,
        highlightColor: highlightColor,
      ),
    );
  }
}

class _SpherePainter extends CustomPainter {
  final Color baseColor;
  final Color highlightColor;

  _SpherePainter({required this.baseColor, required this.highlightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Shadow
    canvas.drawCircle(
      center + const Offset(2, 4),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Base sphere with radial gradient
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [
          highlightColor.withValues(alpha: 0.9),
          baseColor,
          baseColor.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);

    // Specular highlight
    final specPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.5),
        radius: 0.4,
        colors: [
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * 0.85, specPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A 3D-style shopping bag icon painted with Flutter
class Painted3DShoppingBag extends StatelessWidget {
  final double size;
  final Color color;

  const Painted3DShoppingBag({
    super.key,
    this.size = 120,
    this.color = const Color(0xFF9B7DFF),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.2),
      painter: _ShoppingBagPainter(color: color),
    );
  }
}

class _ShoppingBagPainter extends CustomPainter {
  final Color color;
  _ShoppingBagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.35, w * 0.8, h * 0.62),
        const Radius.circular(16),
      ));
    canvas.drawShadow(shadowPath, Colors.black.withValues(alpha: 0.3), 15, false);

    // Bag body - gradient
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.6),
      const Radius.circular(16),
    );
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color,
          Color.lerp(color, Colors.purple.shade900, 0.4)!,
        ],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Light reflection strip
    final reflectPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.35, h * 0.6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.35, h * 0.6),
        const Radius.circular(16),
      ),
      reflectPaint,
    );

    // Handle
    final handlePaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.3)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    final handlePath = Path()
      ..moveTo(w * 0.3, h * 0.32)
      ..quadraticBezierTo(w * 0.3, h * 0.1, w * 0.5, h * 0.08)
      ..quadraticBezierTo(w * 0.7, h * 0.1, w * 0.7, h * 0.32);
    canvas.drawPath(handlePath, handlePaint);

    // Cart icon on bag
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cartX = w * 0.38;
    final cartY = h * 0.52;
    final cartW = w * 0.24;
    final cartH = h * 0.15;

    // Cart body
    final cartPath = Path()
      ..moveTo(cartX, cartY)
      ..lineTo(cartX + cartW * 0.1, cartY + cartH)
      ..lineTo(cartX + cartW * 0.9, cartY + cartH)
      ..lineTo(cartX + cartW, cartY);
    canvas.drawPath(cartPath, iconPaint);

    // Cart wheels
    canvas.drawCircle(Offset(cartX + cartW * 0.25, cartY + cartH + 5), 3, iconPaint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cartX + cartW * 0.75, cartY + cartH + 5), 3, iconPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A 3D-style gift box
class Painted3DGiftBox extends StatelessWidget {
  final double size;
  final Color color;

  const Painted3DGiftBox({
    super.key,
    this.size = 60,
    this.color = const Color(0xFF6C63FF),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GiftBoxPainter(color: color),
    );
  }
}

class _GiftBoxPainter extends CustomPainter {
  final Color color;
  _GiftBoxPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.25, w * 0.88, h * 0.72),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Box body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.3, w * 0.9, h * 0.65),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.3)!],
        ).createShader(bodyRect.outerRect),
    );

    // Light reflection
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.3, w * 0.4, h * 0.65),
        const Radius.circular(6),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // Lid
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.22, w, h * 0.15),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      lidRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.white, 0.2)!,
            color,
          ],
        ).createShader(lidRect.outerRect),
    );

    // Ribbon vertical
    canvas.drawRect(
      Rect.fromLTWH(w * 0.43, h * 0.22, w * 0.14, h * 0.73),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // Ribbon horizontal
    canvas.drawRect(
      Rect.fromLTWH(w * 0.05, h * 0.53, w * 0.9, h * 0.08),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );

    // Bow
    final bowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final bowPath = Path()
      ..moveTo(w * 0.5, h * 0.22)
      ..quadraticBezierTo(w * 0.3, h * 0.05, w * 0.35, h * 0.18)
      ..moveTo(w * 0.5, h * 0.22)
      ..quadraticBezierTo(w * 0.7, h * 0.05, w * 0.65, h * 0.18);
    canvas.drawPath(bowPath, bowPaint..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A percentage badge (discount tag)
class Painted3DPercentBadge extends StatelessWidget {
  final double size;

  const Painted3DPercentBadge({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6B8A), Color(0xFFFF4D6D)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D6D).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '%',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.45,
          ),
        ),
      ),
    );
  }
}

/// A 3D user avatar (for signup screen)
class Painted3DUserAvatar extends StatelessWidget {
  final double size;

  const Painted3DUserAvatar({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _UserAvatarPainter(),
    );
  }
}

class _UserAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.85), width: w * 0.7, height: h * 0.15),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Body (rounded bottom)
    final bodyPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.45, w * 0.7, h * 0.45),
        const Radius.circular(20),
      ));
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9B8FFF), Color(0xFF7B6FE0)],
        ).createShader(Rect.fromLTWH(w * 0.15, h * 0.45, w * 0.7, h * 0.45)),
    );

    // Light on body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.45, w * 0.3, h * 0.45),
        const Radius.circular(20),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // Head
    canvas.drawCircle(
      Offset(cx, h * 0.3),
      w * 0.2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.0,
          colors: [
            const Color(0xFFB8ACFF),
            const Color(0xFF8B7FE0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, h * 0.3), radius: w * 0.2)),
    );

    // Head highlight
    canvas.drawCircle(
      Offset(cx - w * 0.05, h * 0.25),
      w * 0.08,
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A shield check icon (for signup screen)
class Painted3DShield extends StatelessWidget {
  final double size;

  const Painted3DShield({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.1,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF4A42D4)],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.verified_user_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}

/// A floating heart for the signup scene
class Painted3DHeart extends StatelessWidget {
  final double size;

  const Painted3DHeart({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HeartPainter(),
    );
  }
}

class _HeartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final heartPath = Path()
      ..moveTo(w * 0.5, h * 0.35)
      ..cubicTo(w * 0.5, h * 0.2, w * 0.15, h * 0.05, w * 0.15, h * 0.35)
      ..cubicTo(w * 0.15, h * 0.55, w * 0.5, h * 0.85, w * 0.5, h * 0.9)
      ..cubicTo(w * 0.5, h * 0.85, w * 0.85, h * 0.55, w * 0.85, h * 0.35)
      ..cubicTo(w * 0.85, h * 0.05, w * 0.5, h * 0.2, w * 0.5, h * 0.35);

    canvas.drawPath(
      heartPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF6B9D), Color(0xFFE84393)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Specular highlight
    canvas.drawCircle(
      Offset(w * 0.35, h * 0.3),
      w * 0.1,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ─── The Premium 3D Auth Layout ───────────────────────────────────────────

class FloatingObject3D {
  final Widget child;
  final double dx;
  final double dy;
  final double delay;
  final double depth;

  FloatingObject3D({
    required this.child,
    required this.dx,
    required this.dy,
    this.delay = 0.0,
    this.depth = 1.0,
  });
}

class Auth3DLayout extends StatelessWidget {
  final Widget formContent;
  final bool isDark;
  final String title;
  final String subtitle;
  final Widget centerObject;
  final List<FloatingObject3D> floatingObjects;
  final bool showBackButton;

  const Auth3DLayout({
    super.key,
    required this.formContent,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.centerObject,
    this.floatingObjects = const [],
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    final bgColor = isDark ? const Color(0xFF0D0B1E) : const Color(0xFFF0ECFF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Ambient background blobs
          _AmbientBackground(isDark: isDark),
          // Main content
          isMobile
              ? _buildMobileLayout(context, bgColor)
              : _buildDesktopLayout(context, bgColor),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Color bgColor) {
    final textColor = isDark ? Colors.white : const Color(0xFF161622);
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Back button
            if (showBackButton)
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            // Hero 3D Scene
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.38,
              width: double.infinity,
              child: Hero3DScene(
                isDark: isDark,
                centerObject: centerObject,
                floatingObjects: floatingObjects,
              ),
            ),
            // Title + subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Form
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: formContent,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Color bgColor) {
    final textColor = isDark ? Colors.white : const Color(0xFF161622);
    return Row(
      children: [
        // Left: 3D Scene
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF080614) : const Color(0xFFE8E2FF),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Hero3DScene(
                    isDark: isDark,
                    centerObject: centerObject,
                    floatingObjects: floatingObjects,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textColor.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right: Form
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
                  child: formContent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─── Ambient Background ───────────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  final bool isDark;
  const _AmbientBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Top-right blob
        Positioned(
          right: -60,
          top: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF8B5CF6) : const Color(0xFFC4B5FD)).withValues(alpha: isDark ? 0.15 : 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom-left blob
        Positioned(
          left: -80,
          bottom: size.height * 0.2,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFFEC4899) : const Color(0xFFFBCFE8)).withValues(alpha: isDark ? 0.1 : 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Center-right blob
        Positioned(
          right: -40,
          top: size.height * 0.5,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? const Color(0xFF6366F1) : const Color(0xFFA5B4FC)).withValues(alpha: isDark ? 0.12 : 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─── Hero 3D Scene ────────────────────────────────────────────────────────

class Hero3DScene extends StatefulWidget {
  final bool isDark;
  final Widget centerObject;
  final List<FloatingObject3D> floatingObjects;

  const Hero3DScene({
    super.key,
    required this.isDark,
    required this.centerObject,
    required this.floatingObjects,
  });

  @override
  State<Hero3DScene> createState() => _Hero3DSceneState();
}

class _Hero3DSceneState extends State<Hero3DScene> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cx = constraints.maxWidth / 2;
        final cy = constraints.maxHeight / 2 + 20;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final floatVal = math.sin(t * math.pi) * 12;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Ambient glow under center object
                Positioned(
                  left: cx - 100,
                  top: cy - 80,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isDark ? const Color(0xFF8B5CF6) : const Color(0xFFC4B5FD))
                              .withValues(alpha: widget.isDark ? 0.35 : 0.5),
                          blurRadius: 80,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // 3D Platform (elliptical disc with gradient)
                Positioned(
                  left: cx - 90,
                  top: cy + 50,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(0.5),
                    alignment: Alignment.center,
                    child: Container(
                      width: 180,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(90),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: widget.isDark
                              ? [const Color(0xFF2D2B3D), const Color(0xFF1A1828)]
                              : [const Color(0xFFDDD8F8), const Color(0xFFCBC4F0)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isDark
                                ? const Color(0xFF6C63FF).withValues(alpha: 0.25)
                                : const Color(0xFF6C63FF).withValues(alpha: 0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center 3D object (floating)
                Positioned(
                  left: cx - 70,
                  top: cy - 80 + floatVal,
                  child: widget.centerObject,
                ),

                // Floating secondary objects
                ...widget.floatingObjects.map((obj) {
                  final objFloat = math.sin((t + obj.delay) * math.pi * 2) * 15 * obj.depth;
                  return Positioned(
                    left: cx + obj.dx,
                    top: cy + obj.dy + objFloat,
                    child: obj.child,
                  );
                }),

                // Tiny metallic spheres for atmosphere
                ..._buildAtmosphericSpheres(cx, cy, t),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildAtmosphericSpheres(double cx, double cy, double t) {
    final spheres = <_TinySphereData>[
      _TinySphereData(dx: -80, dy: -30, size: 8, delay: 0.2, color: const Color(0xFFC0C0D0)),
      _TinySphereData(dx: 100, dy: -60, size: 6, delay: 0.5, color: const Color(0xFFB0B0C0)),
      _TinySphereData(dx: 120, dy: 30, size: 10, delay: 0.8, color: const Color(0xFFD0D0E0)),
      _TinySphereData(dx: -100, dy: 50, size: 5, delay: 0.3, color: const Color(0xFFA0A0B0)),
      _TinySphereData(dx: 60, dy: 80, size: 7, delay: 0.6, color: const Color(0xFFE0D0F0)),
      _TinySphereData(dx: -60, dy: -80, size: 9, delay: 0.9, color: const Color(0xFFD0C0E0)),
    ];

    return spheres.map((s) {
      final bob = math.sin((t + s.delay) * math.pi * 2) * 8;
      return Positioned(
        left: cx + s.dx,
        top: cy + s.dy + bob,
        child: PaintedSphere(
          size: s.size,
          baseColor: s.color,
          highlightColor: Colors.white,
        ),
      );
    }).toList();
  }
}

class _TinySphereData {
  final double dx, dy, size, delay;
  final Color color;
  _TinySphereData({required this.dx, required this.dy, required this.size, required this.delay, required this.color});
}
