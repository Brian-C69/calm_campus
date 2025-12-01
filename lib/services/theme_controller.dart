import 'package:flutter/material.dart';

import 'user_profile_service.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  Future<void> loadSavedTheme() async {
    final AppThemeMode stored = await UserProfileService.instance.getTheme();
    themeModeNotifier.value = _mapToThemeMode(stored);
  }

  Future<void> updateTheme(AppThemeMode mode) async {
    themeModeNotifier.value = _mapToThemeMode(mode);
    await UserProfileService.instance.saveTheme(mode);
  }

  ThemeMode _mapToThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}
