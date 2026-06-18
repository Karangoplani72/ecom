import 'package:flutter/material.dart';

/// A wrapper widget that enforces industry-standard responsiveness.
///
/// On Mobile: Occupies full width.
/// On Tablet/Laptop/Web: Constrains content to a readable max-width and centers it.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;
  final bool usePagePadding;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 1024, // Industry standard for desktop content
    this.backgroundColor,
    this.usePagePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: usePagePadding ? 20.0 : 0.0,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
