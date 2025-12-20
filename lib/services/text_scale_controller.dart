import 'package:flutter/material.dart';

import 'user_profile_service.dart';

class TextScaleController {
  TextScaleController._();

  static final TextScaleController instance = TextScaleController._();

  final ValueNotifier<double> textScaleNotifier = ValueNotifier<double>(1.0);

  Future<void> loadSavedScale() async {
    final AppTextScale stored = await UserProfileService.instance.getTextScale();
    textScaleNotifier.value = _mapScale(stored);
  }

  Future<void> updateScale(AppTextScale scale) async {
    textScaleNotifier.value = _mapScale(scale);
    await UserProfileService.instance.saveTextScale(scale);
  }

  double _mapScale(AppTextScale scale) {
    switch (scale) {
      case AppTextScale.small:
        return 0.9;
      case AppTextScale.medium:
        return 1.0;
      case AppTextScale.large:
        return 1.15;
    }
  }
}
