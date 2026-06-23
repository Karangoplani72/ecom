import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// BUYER UI KIT
/// ─────────────────────────────────────────────────────────────────────
/// Single source of truth for the buyer-facing design language: colors,
/// gradients, shadows ("2.5D" elevation), spacing, radii, typography and
/// a set of reusable premium widgets (cards, buttons, chips, steppers,
/// empty/error/loading states). Every buyer screen should source its
/// visual tokens from here instead of declaring local one-off constants,
/// so the entire buyer experience reads as one consistent product.
///
/// Presentation-only. Contains zero business logic, zero Firebase calls,
/// zero navigation decisions — those always stay in the screens/widgets
/// that consume this kit.
/// ═══════════════════════════════════════════════════════════════════════

// ───────────────────────────── Palette ─────────────────────────────────
class BuyerColors {
  BuyerColors._();

  static const Color primary = Color(0xFFE91E8C);
  static const Color primaryDeep = Color(0xFFAD1457);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color secondaryDeep = Color(0xFF7B1FA2);

  static const Color blush = Color(0xFFFCE4EC);
  static const Color blushSoft = Color(0xFFFFF1F6);
  static const Color cream = Color(0xFFFFF8F9);
  static const Color surface = Colors.white;

  static const Color ink = Color(0xFF1A1A2E);
  static const Color inkMuted = Color(0xFF6E6E80);
  static const Color inkFaint = Color(0xFFAAAAB8);

  static const Color border = Color(0x14241B3D);
  static const Color borderStrong = Color(0x29241B3D);

  static const Color success = Color(0xFF2E9E5B);
  static const Color successBg = Color(0xFFE6F6EC);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3E2);
  static const Color danger = Color(0xFFE63950);
  static const Color dangerBg = Color(0xFFFCE8EA);

  static const Color glassFill = Color(0xCCFFFFFF);
  static const Color overlayDark = Color(0x661A1A2E);
}

// ──────────────────────────── Gradients ─────────────────────────────────
class BuyerGradients {
  BuyerGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BuyerColors.primary, BuyerColors.secondary],
  );

  static const LinearGradient premium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BuyerColors.primary, Color(0xFFC2185B), BuyerColors.secondaryDeep],
  );

  static const LinearGradient disabled = LinearGradient(
    colors: [Color(0xFFDDDDDD), Color(0xFFCBCBCB)],
  );

  static const LinearGradient sheen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
  );

  static LinearGradient imageFade({double opacity = 0.42}) => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Colors.black.withValues(alpha: opacity),
      Colors.transparent,
    ],
  );

  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
    colors: [Color(0xFFF1E4EA), Color(0xFFFBF4F7), Color(0xFFF1E4EA)],
    stops: [0.1, 0.5, 0.9],
  );
}

// ──────────────────────────── Shadows (2.5D) ─────────────────────────────
class BuyerShadows {
  BuyerShadows._();

  /// Resting elevation — soft ambient glow + tight contact shadow.
  static List<BoxShadow> soft([Color tint = BuyerColors.ink]) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: tint.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  /// Lifted elevation — used on press-out, hover, or focal cards.
  static List<BoxShadow> lifted([Color tint = BuyerColors.primary]) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.22),
      blurRadius: 28,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: BuyerColors.ink.withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Pressed-in elevation — tighter & lower, communicates a depressed state.
  static List<BoxShadow> pressed([Color tint = BuyerColors.primary]) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.16),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> glow([Color tint = BuyerColors.primary]) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.35),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> fab([Color tint = BuyerColors.primary]) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.30),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

// ───────────────────────────── Geometry ─────────────────────────────────
class BuyerRadii {
  BuyerRadii._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 26;
  static const double xxl = 32;
  static const double pill = 999;
}

class BuyerSpace {
  BuyerSpace._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;
}

// ──────────────────────────── Typography ─────────────────────────────────
class BuyerText {
  BuyerText._();

  static TextStyle display({Color color = BuyerColors.ink}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  static TextStyle headline({Color color = BuyerColors.ink}) =>
      GoogleFonts.playfairDisplay(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.25,
      );

  static TextStyle title({Color color = BuyerColors.ink}) => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1.3,
  );

  static TextStyle body({Color color = BuyerColors.inkMuted}) =>
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.45,
      );

  static TextStyle label({Color color = BuyerColors.ink}) => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.2,
  );

  static TextStyle caption({Color color = BuyerColors.inkFaint}) =>
      GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle price({
    Color color = BuyerColors.primary,
    double size = 16,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
  );
}

// ════════════════════════════ WIDGETS ════════════════════════════════════

/// Generic press-interaction wrapper: scales down + intensifies shadow on
/// press. Purely presentational — `onTap` fires exactly the callback it is
/// given, with no added side effects.
class BuyerPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const BuyerPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.97,
  });

  @override
  State<BuyerPressable> createState() => _BuyerPressableState();
}

class _BuyerPressableState extends State<BuyerPressable> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Standard elevated "2.5D" card surface. Wrap any buyer content block in
/// this for a consistent rounded-white-card-with-depth look.
class BuyerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color color;
  final List<BoxShadow>? shadow;
  final Border? border;

  const BuyerCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = BuyerRadii.lg,
    this.color = BuyerColors.surface,
    this.shadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? BuyerShadows.soft(),
        border: border,
      ),
      child: child,
    );
  }
}

/// Small icon-and-label pill — used for stock badges, order/status labels,
/// category tags, etc.
class BuyerStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final Color? background;
  final double fontSize;

  const BuyerStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.background,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? color,
        borderRadius: BorderRadius.circular(BuyerRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: fontSize + 2,
              color: background != null ? color : Colors.white,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: background != null ? color : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted circular icon button — wishlist hearts, back buttons, overflow
/// actions floating above imagery.
class BuyerGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color? fillColor;
  final double size;

  const BuyerGlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.iconColor = BuyerColors.primary,
    this.fillColor,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fillColor ?? BuyerColors.glassFill,
          shape: BoxShape.circle,
          boxShadow: BuyerShadows.soft(),
        ),
        child: Icon(icon, size: size * 0.5, color: iconColor),
      ),
    );
  }
}

/// Primary call-to-action button with brand gradient, disabled + loading
/// states. Replaces ad-hoc gradient Containers scattered across screens.
class BuyerPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  final IconData? icon;
  final Gradient? gradient;
  final double fontSize;

  const BuyerPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 50,
    this.icon,
    this.gradient,
    this.fontSize = 14,
  });

  bool get _disabled => onPressed == null || loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _disabled ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: _disabled
              ? BuyerGradients.disabled
              : (gradient ?? BuyerGradients.primary),
          borderRadius: BorderRadius.circular(BuyerRadii.sm),
          boxShadow: _disabled ? null : BuyerShadows.lifted(),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: fontSize + 4, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: fontSize,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary / outline button — used for "Continue as Guest", filters, etc.
class BuyerSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color color;

  const BuyerSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
    this.color = BuyerColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BuyerRadii.sm),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped quantity stepper. Pure UI — increment/decrement callbacks
/// and enabled-state are fully controlled by the caller, so all stock /
/// cart business rules stay exactly where they already live.
class BuyerQuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final double height;

  const BuyerQuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: BuyerColors.blush,
        borderRadius: BorderRadius.circular(BuyerRadii.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onDecrement,
              icon: Icon(
                Icons.remove_rounded,
                size: 16,
                color: onDecrement == null
                    ? BuyerColors.inkFaint
                    : BuyerColors.primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: BuyerColors.ink,
              ),
            ),
          ),
          Expanded(
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onIncrement,
              icon: Icon(
                onIncrement == null ? Icons.block_rounded : Icons.add_rounded,
                size: 16,
                color: onIncrement == null
                    ? BuyerColors.inkFaint
                    : BuyerColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent section header used across Home / Listing screens —
/// title + optional trailing action ("See all").
class BuyerSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BuyerSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: BuyerText.headline()),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: BuyerText.label(color: BuyerColors.primary),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: BuyerColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Consistent empty-state block — empty cart, empty wishlist, no orders,
/// no search results, etc. Presentation only; the caller decides what
/// triggers it and what the action does.
class BuyerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const BuyerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [BuyerColors.blush, BuyerColors.blushSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: BuyerShadows.soft(),
              ),
              child: Icon(icon, size: 40, color: BuyerColors.primary),
            ),
            const SizedBox(height: 22),
            Text(title, style: BuyerText.title(), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: BuyerText.body(), textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: 200,
                child: BuyerPrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent error-state block for StreamBuilder/FutureBuilder error
/// branches, with an optional retry affordance.
class BuyerErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const BuyerErrorState({
    super.key,
    this.message = 'Something went wrong. Please try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: BuyerColors.dangerBg,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 32,
                color: BuyerColors.danger,
              ),
            ),
            const SizedBox(height: 18),
            Text(message, style: BuyerText.body(), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: 160,
                child: BuyerSecondaryButton(label: 'Retry', onPressed: onRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lightweight shimmer loader — no external package dependency. Wrap any
/// placeholder box with this for an animated loading sheen.
class BuyerShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const BuyerShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = BuyerRadii.xs,
  });

  @override
  State<BuyerShimmer> createState() => _BuyerShimmerState();
}

class _BuyerShimmerState extends State<BuyerShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
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
      builder: (context, _) {
        final dx = (_controller.value * 2.6) - 1.3;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + dx, -0.2),
              end: Alignment(1.0 + dx, 0.2),
              colors: const [
                Color(0xFFF1E4EA),
                Color(0xFFFCF5F8),
                Color(0xFFF1E4EA),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton mimicking the ProductCard layout — used while grids/streams
/// are loading their first snapshot.
class BuyerSkeletonProductCard extends StatelessWidget {
  const BuyerSkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BuyerColors.surface,
        borderRadius: BorderRadius.circular(BuyerRadii.lg),
        boxShadow: BuyerShadows.soft(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(BuyerRadii.lg),
              ),
              child: const BuyerShimmer(height: double.infinity, radius: 0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BuyerShimmer(height: 13, width: 110),
                const SizedBox(height: 8),
                const BuyerShimmer(height: 10, width: 60),
                const SizedBox(height: 10),
                const BuyerShimmer(height: 16, width: 70),
                const SizedBox(height: 10),
                BuyerShimmer(height: 32, radius: BuyerRadii.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft decorative background blobs for hero / header sections — purely
/// cosmetic, painted behind real content to give the "2.5D" ambient depth.
class BuyerBackdrop extends StatelessWidget {
  final double height;

  const BuyerBackdrop({super.key, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _blob(180, BuyerColors.secondary.withValues(alpha: 0.16)),
          ),
          Positioned(
            top: 20,
            left: -50,
            child: _blob(140, BuyerColors.primary.withValues(alpha: 0.14)),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }
}
