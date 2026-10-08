import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class AppTypography {
  static const String outfitFamily = 'Outfit';
  static const String archivoFamily = 'Archivo';

  static const TextStyle _outfit = TextStyle(fontFamily: outfitFamily);
  static const TextStyle _archivo = TextStyle(fontFamily: archivoFamily);
  static TextTheme? _lightTheme;
  static TextTheme? _darkTheme;

  static Color _ink(BuildContext? context) =>
      context == null ? AppColors.textPrimary : Theme.of(context).colorScheme.onSurface;

  static Color _muted(BuildContext? context) =>
      context == null ? AppColors.textSecondary : Theme.of(context).colorScheme.onSurfaceVariant;

  static TextTheme textTheme(Brightness brightness, {Color? onSurface}) {
    if (onSurface == null) {
      final cached = brightness == Brightness.dark ? _darkTheme : _lightTheme;
      if (cached != null) return cached;
    }
    onSurface ??= brightness == Brightness.dark ? AppColors.darkInk : AppColors.lightTextPrimary;
    final onVariant = brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final base = Typography.material2021().black.apply(fontFamily: outfitFamily);
    final theme = base.apply(bodyColor: onSurface, displayColor: onSurface).copyWith(
          bodyLarge: base.bodyLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w400),
          bodyMedium: base.bodyMedium?.copyWith(color: onSurface),
          bodySmall: base.bodySmall?.copyWith(color: onVariant),
          titleLarge: base.titleLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
          titleMedium: base.titleMedium?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
          labelLarge: base.labelLarge?.copyWith(color: onSurface, fontWeight: FontWeight.w700),
        );
    if (onSurface == AppColors.darkInk) {
      _darkTheme = theme;
    } else if (onSurface == AppColors.lightTextPrimary) {
      _lightTheme = theme;
    }
    return theme;
  }

  static TextStyle display({Color? color, double size = 28, BuildContext? context}) => _outfit.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: color ?? (context != null ? _ink(context) : null),
      );

  static TextStyle title({Color? color, double size = 20, BuildContext? context}) => _outfit.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: color ?? (context != null ? _ink(context) : null),
      );

  static TextStyle titleLarge({Color? color, double size = 22, BuildContext? context}) =>
      title(color: color, size: size, context: context);

  static TextStyle labelBold({Color? color, double size = 13, BuildContext? context}) => _outfit.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? (context != null ? _ink(context) : null),
      );

  static TextStyle body({Color? color, double size = 14, BuildContext? context}) => _outfit.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color ?? (context != null ? _muted(context) : null),
      );

  static TextStyle clock({Color? color, double size = 56}) => _outfit.copyWith(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: -1.4,
        color: color ?? AppColors.onPrimary,
      );

  static TextStyle archivo({
    Color? color,
    double size = 16,
    FontWeight weight = FontWeight.w700,
    double? height,
    double? letterSpacing,
  }) =>
      _archivo.copyWith(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
}
