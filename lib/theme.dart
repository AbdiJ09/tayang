import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warm-dark: arang hangat, linen, satu aksen kuningan.
class Palette {
  static const bg = Color(0xFF12100E);
  static const ink = Color(0xFFEDE6DA);
  static const muted = Color(0xFF8F877B);
  static const faint = Color(0xFF5C564E);
  static const hairline = Color(0xFF2E2925);
  static const brass = Color(0xFFB8935A);
}

class Txt {
  static TextStyle display(double size, {FontStyle? style, Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w500,
        fontStyle: style,
        height: 1.05,
        color: color ?? Palette.ink,
      );

  static TextStyle italic(double size, {Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontStyle: FontStyle.italic,
        height: 1.35,
        color: color ?? Palette.muted,
      );

  static TextStyle label({Color? color, double size = 11}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w400,
        color: color ?? Palette.muted,
      );

  static TextStyle body({Color? color, double size = 15}) => GoogleFonts.inter(
    fontSize: size,
    height: 1.6,
    color: color ?? Palette.ink.withValues(alpha: 0.82),
  );
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Palette.bg,
    colorScheme: base.colorScheme.copyWith(
      surface: Palette.bg,
      primary: Palette.brass,
      onSurface: Palette.ink,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Palette.brass,
      selectionColor: Color(0x55B8935A),
      selectionHandleColor: Palette.brass,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: Palette.hairline,
  );
}

/// Transisi halaman: fade halus, tanpa geser.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 280),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, a, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
    child: child,
  ),
);

/// Notifikasi error singkat di bawah layar.
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF1C1915),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(),
      content: Text(message, style: Txt.italic(16, color: Palette.ink)),
    ),
  );
}
