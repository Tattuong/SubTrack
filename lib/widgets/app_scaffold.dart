import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/app_theme_preset.dart';
import '../models/shop_item.dart';
import '../providers/shop_provider.dart';

class FtrBackground extends StatelessWidget {
  final Widget child;

  const FtrBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = context.select<ShopProvider, AppBackground>((s) => s.activeBackground);
    final ftr = context.ftrTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customBg = bg.id != ShopCatalog.defaultBackgroundId;
    final page = Theme.of(context).scaffoldBackgroundColor;
    final tint = ftr.isPremium || bg.glow ? ftr.glowColor : ftr.primary;
    final colors = customBg
        ? bg.gradient.colors.map((c) => Color.lerp(page, c, isDark ? 0.28 : 0.55)!).toList()
        : isDark
            ? [
                Color.lerp(page, tint, 0.28)!,
                page,
                Color.lerp(page, Colors.black, 0.38)!,
              ]
            : [
                Color.lerp(page, tint, ftr.isPremium ? 0.16 : 0.06)!,
                page,
              ];

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: colors,
                  ),
                ),
              ),
              if (bg.grid)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _NotebookGridPainter(color: ftr.primary.withValues(alpha: isDark ? 0.10 : 0.08)),
                      isComplex: true,
                      willChange: false,
                    ),
                  ),
                ),
              if (isDark)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _StarPainter(),
                      isComplex: true,
                      willChange: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class FtrScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;

  const FtrScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = true,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return FtrBackground(
      child: Scaffold(
        extendBody: extendBody,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: Colors.transparent,
        appBar: appBar,
        floatingActionButton: floatingActionButton,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? fill;
  final bool highlighted;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.fill,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.select<ShopProvider, CardStyle>((s) => s.activeCardStyle);
    final ftr = context.ftrTheme;
    var decoration = skin.lookDecoration(fill: fill ?? ftr.surface, accent: ftr.primary);
    if (highlighted) {
      decoration = decoration.copyWith(border: Border.all(color: ftr.primary, width: 1.4));
    }
    final radius = BorderRadius.circular(skin.borderRadius);
    final content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}

class _NotebookGridPainter extends CustomPainter {
  final Color color;

  const _NotebookGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookGridPainter oldDelegate) => oldDelegate.color != color;
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  static Size? _size;
  static List<Offset>? _points;
  static List<double>? _radii;

  @override
  void paint(Canvas canvas, Size size) {
    if (_size != size || _points == null) {
      _size = size;
      final random = math.Random(7);
      _points = List<Offset>.generate(
        28,
        (_) => Offset(random.nextDouble() * size.width, random.nextDouble() * size.height * 0.55),
      );
      _radii = List<double>.generate(28, (_) => random.nextDouble() * 1.3 + 0.4);
    }
    final paint = Paint()..color = const Color(0x80FFFFFF);
    final points = _points!;
    final radii = _radii!;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) => false;
}

class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.borderOf(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
