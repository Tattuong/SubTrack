import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/app_ui.dart';

@immutable
class FtrTheme extends ThemeExtension<FtrTheme> {
  final Color primary;
  final Color primaryLight;
  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color navBar;
  final Color navActive;
  final Color glowColor;
  final LinearGradient balanceGradient;
  final bool isPremium;

  const FtrTheme({
    required this.primary,
    required this.primaryLight,
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.navBar,
    required this.navActive,
    required this.glowColor,
    required this.balanceGradient,
    required this.isPremium,
  });

  factory FtrTheme.fromPreset(AppThemePreset preset, {bool isDark = true}) {
    final canvas = isDark ? preset.darkBackground : preset.background;
    final surface = isDark ? preset.darkSurface : preset.surface;
    final surfaceElevated = isDark
        ? (Color.lerp(preset.darkSurface, Colors.white, 0.06) ?? preset.darkSurface)
        : (Color.lerp(preset.surface, Colors.white, 0.12) ?? preset.surface);
    final border = Color.lerp(preset.primary, surface, isDark ? 0.72 : 0.55)?.withValues(alpha: isDark ? 0.45 : 0.35) ??
        AppColors.border;
    return FtrTheme(
      primary: preset.primary,
      primaryLight: preset.primaryLight,
      canvas: canvas,
      surface: surface,
      surfaceElevated: surfaceElevated,
      border: border,
      navBar: isDark ? const Color(0xFF2A2736) : Colors.white,
      navActive: preset.primary,
      glowColor: preset.glowColor,
      balanceGradient: preset.balanceGradient,
      isPremium: preset.isPremium,
    );
  }

  static FtrTheme get fallback => FtrTheme.fromPreset(AppThemePresets.defaultPreset, isDark: false);

  @override
  FtrTheme copyWith({
    Color? primary,
    Color? primaryLight,
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? navBar,
    Color? navActive,
    Color? glowColor,
    LinearGradient? balanceGradient,
    bool? isPremium,
  }) {
    return FtrTheme(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      navBar: navBar ?? this.navBar,
      navActive: navActive ?? this.navActive,
      glowColor: glowColor ?? this.glowColor,
      balanceGradient: balanceGradient ?? this.balanceGradient,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  FtrTheme lerp(ThemeExtension<FtrTheme>? other, double t) {
    if (other is! FtrTheme) return this;
    return FtrTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      balanceGradient: LinearGradient.lerp(balanceGradient, other.balanceGradient, t) ?? balanceGradient,
      isPremium: t < 0.5 ? isPremium : other.isPremium,
    );
  }

  BoxDecoration coinChip({bool header = false}) {
    return BoxDecoration(
      color: header ? surfaceElevated : surface,
      borderRadius: BorderRadius.circular(header ? 12 : 20),
      border: Border.all(color: isPremium ? glowColor.withValues(alpha: 0.55) : border),
      boxShadow: isPremium ? [BoxShadow(color: glowColor.withValues(alpha: 0.22), blurRadius: 12)] : null,
    );
  }
}

extension FtrThemeContext on BuildContext {
  FtrTheme get ftrTheme => Theme.of(this).extension<FtrTheme>() ?? FtrTheme.fallback;
}

class AppThemePreset {
  final String id;
  final Color primary;
  final Color primaryLight;
  final Color background;
  final Color surface;
  final Color darkBackground;
  final Color darkSurface;
  final Color glowColor;
  final Color blueSide;
  final Color coralSide;
  final LinearGradient headerGradient;
  final LinearGradient balanceGradient;
  final LinearGradient shopPreviewGradient;

  const AppThemePreset({
    required this.id,
    required this.primary,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.darkBackground,
    required this.darkSurface,
    required this.glowColor,
    required this.blueSide,
    required this.coralSide,
    required this.headerGradient,
    required this.balanceGradient,
    required this.shopPreviewGradient,
  });

  bool get isPremium => id != 'theme_default';

  ThemeData lightTheme() => _buildTheme(
        brightness: Brightness.light,
        scaffold: background,
        surfaceColor: surface,
        onSurface: AppColors.lightTextPrimary,
      );

  ThemeData darkTheme() => _buildTheme(
        brightness: Brightness.dark,
        scaffold: darkBackground,
        surfaceColor: darkSurface,
        onSurface: AppColors.darkInk,
      );

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffold,
    required Color surfaceColor,
    required Color onSurface,
  }) {
    final isDark = brightness == Brightness.dark;
    final onPrimary = primary.computeLuminance() > 0.55
        ? const Color(0xFF102830)
        : (isDark ? AppColors.darkOnPrimary : Colors.white);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.outfitFamily,
      scaffoldBackgroundColor: scaffold,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primary,
              onPrimary: onPrimary,
              secondary: primaryLight,
              surface: surfaceColor,
              onSurface: onSurface,
              onSurfaceVariant: AppColors.darkTextSecondary,
              outline: borderColor(surfaceColor, isDark),
            )
          : ColorScheme.light(
              primary: primary,
              onPrimary: onPrimary,
              secondary: primaryLight,
              surface: surfaceColor,
              onSurface: onSurface,
              onSurfaceVariant: AppColors.textSecondary,
              outline: borderColor(surfaceColor, isDark),
            ),
      textTheme: AppTypography.textTheme(brightness, onSurface: onSurface),
      iconTheme: IconThemeData(color: onSurface),
      primaryIconTheme: IconThemeData(color: onSurface),
      hintColor: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
      listTileTheme: ListTileThemeData(
        iconColor: onSurface,
        textColor: onSurface,
        subtitleTextStyle: AppTypography.body(
          size: 13,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
        hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        floatingLabelStyle: TextStyle(color: primary),
        prefixIconColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        suffixIconColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surfaceColor,
        headerForegroundColor: onSurface,
        headerBackgroundColor: isDark
            ? Color.lerp(surfaceColor, Colors.white, 0.06)
            : (Color.lerp(primary, surface, 0.78) ?? primaryLight),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return (isDark ? AppColors.darkTextMuted : AppColors.textMuted).withValues(alpha: 0.45);
          }
          if (states.contains(WidgetState.selected)) return onPrimary;
          return onSurface;
        }),
        yearForegroundColor: WidgetStateProperty.all(onSurface),
        weekdayStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
      ),
      dialogTheme: DialogThemeData(backgroundColor: surfaceColor, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: onPrimary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: borderColor(surfaceColor, isDark)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return surfaceColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return onPrimary;
            return onSurface;
          }),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.16),
      ),
      extensions: [FtrTheme.fromPreset(this, isDark: isDark)],
    );
  }

  Color borderColor(Color surfaceColor, bool isDark) =>
      Color.lerp(primary, surfaceColor, 0.62)?.withValues(alpha: isDark ? 0.5 : 0.35) ?? AppColors.border;
}

class AppThemePresets {
  AppThemePresets._();

  static const defaultPreset = AppThemePreset(
    id: 'theme_default',
    primary: AppColors.primary,
    primaryLight: AppColors.primaryLight,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    darkBackground: AppColors.darkBackground,
    darkSurface: AppColors.darkSurface,
    glowColor: AppColors.primaryLight,
    blueSide: AppColors.primary,
    coralSide: AppColors.coral,
    headerGradient: AppColors.headerGradient,
    balanceGradient: AppColors.primaryGradient,
    shopPreviewGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF10303C), Color(0xFF1A4A58)],
    ),
  );

  static const peach = AppThemePreset(
    id: 'theme_peach',
    primary: Color(0xFFFF8A5B),
    primaryLight: Color(0xFFFFB07A),
    background: Color(0xFFF7EFE8),
    surface: Color(0xFFFFF8F2),
    darkBackground: Color(0xFF120806),
    darkSurface: Color(0xFF221410),
    glowColor: Color(0xFFFFB07A),
    blueSide: Color(0xFFFF7A45),
    coralSide: Color(0xFFFF4D6D),
    headerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2A140C), Color(0xFF120806)],
    ),
    balanceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFB07A), Color(0xFFFF8A5B)],
    ),
    shopPreviewGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF0E8), Color(0xFFFF8A5B), Color(0xFFFFB07A)],
    ),
  );

  static const dusk = AppThemePreset(
    id: 'theme_dusk',
    primary: Color(0xFF6B5CE7),
    primaryLight: Color(0xFFB8A9FF),
    background: Color(0xFFF4F0FA),
    surface: Color(0xFFFBF8FF),
    darkBackground: Color(0xFF16101F),
    darkSurface: Color(0xFF241C30),
    glowColor: Color(0xFFB8A9FF),
    blueSide: Color(0xFF5B4CDB),
    coralSide: Color(0xFFFF8A5B),
    headerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2A2140), Color(0xFF16101F)],
    ),
    balanceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFB8A9FF), Color(0xFF6B5CE7)],
    ),
    shopPreviewGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2A2140), Color(0xFF6B5CE7), Color(0xFFFF9F6B)],
    ),
  );

  static const mint = AppThemePreset(
    id: 'theme_mint',
    primary: Color(0xFF3DDBA5),
    primaryLight: Color(0xFF9AF0D4),
    background: Color(0xFFEEF7F4),
    surface: Color(0xFFF7FCFA),
    darkBackground: Color(0xFF061210),
    darkSurface: Color(0xFF10201C),
    glowColor: Color(0xFF9AF0D4),
    blueSide: Color(0xFF0F9F6E),
    coralSide: Color(0xFF8ED63A),
    headerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0C2A24), Color(0xFF061210)],
    ),
    balanceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9AF0D4), Color(0xFF3DDBA5)],
    ),
    shopPreviewGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0C2A24), Color(0xFF3DDBA5), Color(0xFF9AF0D4)],
    ),
  );

  static const ice = AppThemePreset(
    id: 'theme_ice',
    primary: Color(0xFF1AA6C9),
    primaryLight: Color(0xFF7DE3F2),
    background: Color(0xFFEEF8FB),
    surface: Color(0xFFF7FCFE),
    darkBackground: Color(0xFF07151C),
    darkSurface: Color(0xFF122430),
    glowColor: Color(0xFF7DE3F2),
    blueSide: Color(0xFF1AA6C9),
    coralSide: Color(0xFF3D5AFE),
    headerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1AA6C9), Color(0xFF3D5AFE)],
    ),
    balanceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7DE3F2), Color(0xFF1AA6C9)],
    ),
    shopPreviewGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1AA6C9), Color(0xFF3D5AFE)],
    ),
  );

  static const night = AppThemePreset(
    id: 'theme_night',
    primary: Color(0xFF1B3A6B),
    primaryLight: Color(0xFF6B96FF),
    background: Color(0xFFEEF1F7),
    surface: Color(0xFFF7F9FC),
    darkBackground: Color(0xFF070B14),
    darkSurface: Color(0xFF141C2E),
    glowColor: Color(0xFFE84A7F),
    blueSide: Color(0xFF1B3A6B),
    coralSide: Color(0xFFE84A7F),
    headerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1B3A6B), Color(0xFFE84A7F)],
    ),
    balanceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6B96FF), Color(0xFF1B3A6B)],
    ),
    shopPreviewGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B3A6B), Color(0xFFE84A7F)],
    ),
  );

  static const Map<String, AppThemePreset> byId = {
    'theme_default': defaultPreset,
    'theme_mint': mint,
    'theme_dusk': dusk,
    'theme_peach': peach,
    'theme_ice': ice,
    'theme_night': night,
  };

  static AppThemePreset get(String? id) => byId[id] ?? defaultPreset;
}

class AppBackground {
  final String id;
  final LinearGradient gradient;
  final bool grid;
  final bool glow;
  final bool mesh;
  final bool stadium;

  const AppBackground({
    required this.id,
    required this.gradient,
    this.grid = false,
    this.glow = false,
    this.mesh = false,
    this.stadium = false,
  });

  static const defaultBg = AppBackground(id: 'bg_default', gradient: AppColors.gameGradient);

  static const gridBg = AppBackground(
    id: 'bg_grid',
    grid: true,
    gradient: LinearGradient(
      colors: [Color(0xFFF7F5FB), Color(0xFFEEEAF6), Color(0xFFF6F4FB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const softBg = AppBackground(
    id: 'bg_soft',
    glow: true,
    gradient: LinearGradient(
      colors: [Color(0xFFF8F6FC), Color(0xFFEDE8FF), Color(0xFFF6F4FB)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static const dusk = AppBackground(
    id: 'bg_dusk',
    glow: true,
    stadium: true,
    gradient: LinearGradient(
      colors: [Color(0xFFFFF6F0), Color(0xFFFFE8F0), Color(0xFFFFF4C8)],
      begin: Alignment.topCenter,
      end: Alignment.bottomRight,
    ),
  );

  static const meshBg = AppBackground(
    id: 'bg_mesh',
    mesh: true,
    gradient: LinearGradient(
      colors: [Color(0xFFE8F6EE), Color(0xFFD8F0E4), Color(0xFFEEF8F2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const Map<String, AppBackground> byId = {
    'bg_default': defaultBg,
    'bg_grid': gridBg,
    'bg_soft': softBg,
    'bg_dusk': dusk,
    'bg_mesh': meshBg,
  };

  static AppBackground get(String? id) => byId[id] ?? defaultBg;
}

class CardStyle {
  final String id;
  final double borderRadius;
  final double stationRadius;
  final bool glow;
  final bool hex;
  final bool glassEffect;
  final bool led;
  final double scoreSize;

  const CardStyle({
    required this.id,
    this.borderRadius = 20,
    this.stationRadius = 6,
    this.glow = false,
    this.hex = false,
    this.glassEffect = false,
    this.led = false,
    this.scoreSize = 118,
  });

  static const defaultStyle = CardStyle(id: 'skin_default');

  static const glowStyle = CardStyle(
    id: 'skin_glow',
    stationRadius: 7,
    glow: true,
    led: true,
    scoreSize: 100,
  );

  static const soft = CardStyle(
    id: 'skin_soft',
    borderRadius: 28,
    stationRadius: 9,
    glassEffect: true,
    scoreSize: 96,
  );

  static const sharp = CardStyle(
    id: 'skin_sharp',
    borderRadius: 8,
    hex: true,
    scoreSize: 108,
  );

  static const Map<String, CardStyle> byId = {
    'skin_default': defaultStyle,
    'skin_glow': glowStyle,
    'skin_soft': soft,
    'skin_sharp': sharp,
  };

  static CardStyle get(String? id) => byId[id] ?? defaultStyle;

  BoxDecoration lookDecoration({required Color fill, required Color accent, double? radius}) {
    final r = radius ?? borderRadius;
    if (glassEffect) {
      return BoxDecoration(
        color: fill.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: AppColors.softShadow(opacity: 0.12),
      );
    }
    if (glow) {
      return BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 18),
        ],
      );
    }
    if (hex) {
      return BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.4),
      );
    }
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(r),
      boxShadow: AppColors.softShadow(),
    );
  }
}
