import 'package:flutter/material.dart';

import 'user_profile_service.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);
  final ValueNotifier<Color> colorSeedNotifier = ValueNotifier<Color>(Colors.teal);

  Future<void> loadSavedTheme() async {
    final AppThemeMode stored = await UserProfileService.instance.getTheme();
    final Color seed = await UserProfileService.instance.getThemeColor();
    themeModeNotifier.value = _mapToThemeMode(stored);
    colorSeedNotifier.value = seed;
  }

  Future<void> updateTheme(AppThemeMode mode) async {
    themeModeNotifier.value = _mapToThemeMode(mode);
    await UserProfileService.instance.saveTheme(mode);
  }

  Future<void> updateColorSeed(Color color) async {
    colorSeedNotifier.value = color;
    await UserProfileService.instance.saveThemeColor(color);
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
