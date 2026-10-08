import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppTabs {
  static final shopFeatures = ValueNotifier<bool>(false);
  static final tabIndex = ValueNotifier<int>(0);

  static void goHome() => tabIndex.value = 0;
  static void goResults() => tabIndex.value = 1;
  static void goTexts() => tabIndex.value = 2;
  static void goProfile() => tabIndex.value = 3;

  static void goSettings() {
    rootNavigatorKey.currentState?.pushNamed('/settings');
  }

  static void goShop({bool features = false}) {
    shopFeatures.value = features;
    rootNavigatorKey.currentState?.pushNamed('/shop');
  }
}

BuildContext? get rootContext => rootNavigatorKey.currentContext;

Future<T?> showAppModal<T>(Widget sheet) {
  final ctx = rootContext;
  if (ctx == null) return Future.value(null);
  return showModalBottomSheet<T>(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}
