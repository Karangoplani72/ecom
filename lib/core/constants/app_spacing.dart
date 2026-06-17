import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  static const pagePadding = EdgeInsets.all(md);

  static const screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const cardPadding = EdgeInsets.all(md);

  static const listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
}