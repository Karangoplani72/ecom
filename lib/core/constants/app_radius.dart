import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const xs = Radius.circular(6);
  static const sm = Radius.circular(10);
  static const md = Radius.circular(14);
  static const lg = Radius.circular(18);
  static const xl = Radius.circular(24);

  static const borderXS = BorderRadius.all(xs);
  static const borderSM = BorderRadius.all(sm);
  static const borderMD = BorderRadius.all(md);
  static const borderLG = BorderRadius.all(lg);
  static const borderXL = BorderRadius.all(xl);
}