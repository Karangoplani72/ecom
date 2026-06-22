import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingObject {
  final String imagePath;
  final double width;
  final double height;
  final double dx;
  final double dy;
  final double delay;
  final double depth; // Used for parallax later if needed

  FloatingObject({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.dx,
    required this.dy,
    this.delay = 0.0,
    this.depth = 1.0,
  });
}

class Auth25DLayout extends StatelessWidget {
  final Widget formContent;
  final bool isDark;
  final String title;
  final String subtitle;
  final String centerObjectPath;
  final List<FloatingObject> floatingObjects;

  const Auth25DLayout({
    super.key,
    required this.formContent,
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.centerObjectPath,
    this.floatingObjects = const [],
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    // Premium Color System
    final bgColor = isDark ? const Color(0xFF161622) : const Color(0xFFF6F6FE);
    final textColor = isDark ? Colors.white : const Color(0xFF161622);

    return Scaffold(
      backgroundColor: bgColor,
      body: isMobile
          ? _buildMobileLayout(context, bgColor, textColor)
          : _buildDesktopLayout(context, bgColor, textColor),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Color bgColor, Color textColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Top
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            child: _buildHeroScene(context),
          ),
          // Form Bottom
          Container(
            decoration: BoxDecoration(
              color: bgColor,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 32),
                  formContent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Color bgColor, Color textColor) {
    return Row(
      children: [
        // Left side: 2.5D Hero Scene
        Expanded(
          flex: 1,
          child: Container(
            color: isDark ? const Color(0xFF101018) : const Color(0xFFF0F0FF),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildHeroScene(context),
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
                              color: textColor.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right side: Form
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
                  child: isDark ? formContent : _buildLightModeFormWrapper(context, formContent),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLightModeFormWrapper(BuildContext context, Widget child) {
    // In light mode, the desktop form can be wrapped in a soft glassmorphic card for extra premium feel
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A5ACD).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF161622),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF161622).withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildHeroScene(BuildContext context) {
    return Hero25DScene(
      isDark: isDark,
      centerObjectPath: centerObjectPath,
      floatingObjects: floatingObjects,
    );
  }
}

class Hero25DScene extends StatefulWidget {
  final bool isDark;
  final String centerObjectPath;
  final List<FloatingObject> floatingObjects;

  const Hero25DScene({
    super.key,
    required this.isDark,
    required this.centerObjectPath,
    required this.floatingObjects,
  });

  @override
  State<Hero25DScene> createState() => _Hero25DSceneState();
}

class _Hero25DSceneState extends State<Hero25DScene> with SingleTickerProviderStateMixin {
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

  Widget _buildFallbackImage(String path, double w, double h) {
    // Error builder provides a styled fallback if the user hasn't downloaded the images yet
    return Image.asset(
      path,
      width: w,
      height: h,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white12 : Colors.black12,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.isDark ? Colors.black : Colors.deepPurple).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Center(
            child: Icon(Icons.image_not_supported_outlined, color: widget.isDark ? Colors.white54 : Colors.black54),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cx = constraints.maxWidth / 2;
        final cy = constraints.maxHeight / 2 + 40; // Shift down slightly

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            // Eased float value from -1 to 1
            final floatVal = math.sin(t * math.pi) * 10;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Ambient Glow
                Positioned(
                  left: cx - 150,
                  top: cy - 150,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isDark ? const Color(0xFF8B5CF6) : const Color(0xFFC4B5FD)).withValues(alpha: widget.isDark ? 0.3 : 0.6),
                          blurRadius: 100,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. The 2.5D Platform (Elevated Disc)
                Positioned(
                  left: cx - 120,
                  top: cy + 40,
                  child: Container(
                    width: 240,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(120), // Ellipse shape
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isDark
                            ? [const Color(0xFF2D2D3A), const Color(0xFF1A1A24)]
                            : [const Color(0xFFE2E2F0), const Color(0xFFD4D4E8)],
                      ),
                      boxShadow: [
                        // Inner top highlight
                        BoxShadow(
                          color: widget.isDark ? Colors.white24 : Colors.white,
                          blurRadius: 2,
                          offset: const Offset(0, -1),
                        ),
                        // Drop shadow
                        BoxShadow(
                          color: widget.isDark ? Colors.black54 : const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Central Object
                Positioned(
                  left: cx - 90,
                  top: cy - 120 + floatVal,
                  child: _buildFallbackImage(widget.centerObjectPath, 180, 180),
                ),

                // 4. Floating Secondary Objects
                ...widget.floatingObjects.map((obj) {
                  // Different frequency/phase for each object based on delay
                  final objFloat = math.sin((t + obj.delay) * math.pi * 2) * 15 * obj.depth;
                  
                  return Positioned(
                    left: cx + obj.dx,
                    top: cy + obj.dy + objFloat,
                    child: _buildFallbackImage(obj.imagePath, obj.width, obj.height),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}
