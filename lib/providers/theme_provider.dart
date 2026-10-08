import 'package:flutter/material.dart';

import '../core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const _modeKey = 'st_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    try {
      final stored = await StorageService.instance.getString(_modeKey);
      if (stored != null) {
        _themeMode = switch (stored) {
          'dark' => ThemeMode.dark,
          'system' => ThemeMode.system,
          _ => ThemeMode.light,
        };
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await StorageService.instance.saveString(_modeKey, value);
    notifyListeners();
  }
}
