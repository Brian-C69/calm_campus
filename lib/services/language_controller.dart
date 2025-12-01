import 'package:flutter/material.dart';

import 'user_profile_service.dart';

class LanguageController {
  LanguageController._();

  static final LanguageController instance = LanguageController._();

  final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('en', 'GB'));

  Future<void> loadSavedLanguage() async {
    final AppLanguage lang = await UserProfileService.instance.getLanguage();
    localeNotifier.value = _mapToLocale(lang);
  }

  Future<void> updateLanguage(AppLanguage language) async {
    localeNotifier.value = _mapToLocale(language);
    await UserProfileService.instance.saveLanguage(language);
  }

  Locale _mapToLocale(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.englishUK:
        return const Locale('en', 'GB');
      case AppLanguage.chineseCN:
        return const Locale('zh', 'CN');
      case AppLanguage.malayMY:
        return const Locale('ms', 'MY');
    }
  }
}
