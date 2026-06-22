import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FloatingParticle {
  final String imagePath;
  final double width;
  final double height;
  final double dx;
  final double dy;
  final double delay;
  final double depth;

  FloatingParticle({
    required this.imagePath,
    required this.width,
    required this.height,
    required this.dx,
    required this.dy,
    this.delay = 0.0,
    this.depth = 1.0,
  });
}

class Premium25DScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final bool isDark;
  final List<FloatingParticle> particles;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool disableParticlesOnMobile;

  const Premium25DScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.isDark = false,
    this.particles = const [],
    this.bottomNavigationBar,
    this.drawer,
    this.disableParticlesOnMobile = true, // To avoid visual overload on small screens
  });

  @override
  State<Premium25DScaffold> createState() => _Premium25DScaffoldState();
}

class _Premium25DScaffoldState extends State<Premium25DScaffold> with SingleTickerProviderStateMixin {
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
    Widget fallback() {
      // Render a pretty gradient sphere as fallback instead of an ugly error icon
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          shape: w == h ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: w != h ? BorderRadius.circular(w * 0.3) : null,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.9,
            colors: [
              (widget.isDark ? const Color(0xFF9B8FFF) : const Color(0xFFC4B5FD)).withValues(alpha: 0.6),
              (widget.isDark ? const Color(0xFF6C63FF) : const Color(0xFF8B5CF6)).withValues(alpha: 0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      );
    }

    // Immediately return the fallback for known missing assets to prevent Web HTTP 404 logs
    if (path.startsWith('assets/images/25d_')) {
      return fallback();
    }

    final isSvg = path.toLowerCase().endsWith('.svg');
    if (isSvg) {
      // Use a FutureBuilder to check if the asset exists before trying to load it
      return FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString(path).catchError((_) => ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && 
              snapshot.hasData && 
              snapshot.data!.isNotEmpty) {
            return SizedBox(
              width: w,
              height: h,
              child: SvgPicture.asset(
                path,
                width: w,
                height: h,
                fit: BoxFit.contain,
              ),
            );
          }
          return fallback();
        },
      );
    }

    return Image.asset(
      path,
      width: w,
      height: h,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;
    
    final showParticles = widget.particles.isNotEmpty && (!isMobile || !widget.disableParticlesOnMobile);

    final bgColor = widget.isDark ? const Color(0xFF161622) : const Color(0xFFF6F6FE);
    final glowColor = (widget.isDark ? const Color(0xFF8B5CF6) : const Color(0xFFC4B5FD)).withValues(alpha: widget.isDark ? 0.2 : 0.4);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      drawer: widget.drawer,
      appBar: widget.appBar,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 120, spreadRadius: 20),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: glowColor, blurRadius: 120, spreadRadius: 10),
                ],
              ),
            ),
          ),

          // Particles Layer
          if (showParticles)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: widget.particles.map((obj) {
                    final objFloat = math.sin((t + obj.delay) * math.pi * 2) * 10 * obj.depth;
                    return Positioned(
                      left: obj.dx,
                      top: obj.dy + objFloat,
                      child: _buildFallbackImage(obj.imagePath, obj.width, obj.height),
                    );
                  }).toList(),
                );
              },
            ),

          // Main Content
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: widget.body,
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
