import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF10303C);
  static const Color primaryLight = Color(0xFF2A6A78);
  static const Color coral = Color(0xFF10303C);
  static const Color coralSoft = Color(0xFFC0F8E0);
  static const Color ink = Color(0xFF102830);

  static const Color accent = primary;
  static const Color success = Color(0xFF16C47F);
  static const Color warning = Color(0xFFF5C542);
  static const Color error = Color(0xFFE5484D);
  static const Color coin = Color(0xFFFFC107);
  static const Color onGold = Color(0xFF3B1408);
  static const Color onPrimary = Colors.white;

  static const Color background = Color(0xFFF5F6F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF4F8FC);
  static const Color surfaceVariant = Color(0xFFE3EDF7);
  static const Color border = Color(0xFFD5E3F0);

  static const Color textPrimary = Color(0xFF102830);
  static const Color textSecondary = Color(0xFF5C6E76);
  static const Color textMuted = Color(0xFF8A989C);

  static const Color darkBackground = Color(0xFF12181C);
  static const Color darkSurface = Color(0xFF1C242A);
  static const Color darkInk = Color(0xFFD7DDD9);
  static const Color darkTextSecondary = Color(0xFF9AA6A1);
  static const Color darkTextMuted = Color(0xFF6E7A76);
  static const Color darkOnPrimary = Color(0xFFDCE3DF);
  static const Color lightBackground = Color(0xFFF7F8F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF102830);
  static const Color onSurfaceVariant = Color(0xFF5C6B8A);

  static const List<Color> listPalette = [
    Color(0xFFFF2D8A),
    Color(0xFF16C47F),
    Color(0xFFF5C542),
    Color(0xFF7B5CFF),
    Color(0xFF1AA6C9),
    Color(0xFFFF7A45),
  ];

  static Color brand(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color primaryOf(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color onPrimaryOf(BuildContext context) => Theme.of(context).colorScheme.onPrimary;
  static Color primaryLightOf(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color canvasOf(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surfaceOf(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color borderOf(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color inkOf(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  static Color secondaryInk(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color mutedInk(BuildContext context) => isDark(context) ? darkTextMuted : textMuted;

  static Color mintWash(BuildContext context) => isDark(context) ? const Color(0xFF8ECFB8) : const Color(0xFFC0F8E0);

  static Color alertWash(BuildContext context) => isDark(context) ? const Color(0xFF322E22) : const Color(0xFFF8E8C4);

  static Color noteWash(BuildContext context) => isDark(context) ? const Color(0xFF1A262E) : const Color(0xFFE7F1FB);

  static Color statusWash(BuildContext context, {required bool active, required bool paused}) {
    if (active) return isDark(context) ? const Color(0xFF1A3330) : const Color(0xFFC0F8E0);
    if (paused) return alertWash(context);
    return isDark(context) ? const Color(0xFF262C30) : const Color(0xFFE7EAED);
  }

  static Color statusInk(BuildContext context) => isDark(context) ? const Color(0xFFD5E0DA) : const Color(0xFF10303C);

  static Color primarySoftOf(BuildContext context) =>
      Color.lerp(primaryOf(context), surfaceOf(context), 0.78) ?? primaryLightOf(context);

  static Color listColor(int index) => listPalette[index % listPalette.length];

  static List<BoxShadow> softShadow({double opacity = 0.10}) => [
        BoxShadow(
          color: const Color(0xFF111111).withValues(alpha: opacity),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A4A58), Color(0xFF10303C)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A4A58), Color(0xFF10303C)],
  );

  static const LinearGradient gameGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF10303C), Color(0xFF1A4A58)],
  );
}
