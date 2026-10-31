import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Serif (Cormorant Garamond) untuk suara merek, sans (Plus Jakarta Sans) untuk data.
class AppText {
  static TextStyle serif(
    double size, {
    FontWeight w = FontWeight.w700,
    Color color = AppColors.ink,
    double? height,
    FontStyle? style,
    double? letterSpacing,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height,
        fontStyle: style,
        letterSpacing: letterSpacing,
      );

  static TextStyle sans(
    double size, {
    FontWeight w = FontWeight.w500,
    Color color = AppColors.ink,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: w,
        color: color,
        height: height,
        decoration: decoration,
        letterSpacing: letterSpacing,
      );
}
