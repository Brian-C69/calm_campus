import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'GB'),
    Locale('zh', 'CN'),
    Locale('ms', 'MY'),
  ];

  static Future<AppLocalizations> load(Locale locale) async {
    final String code = _localeCode(locale);
    Map<String, String> strings = {};

    try {
      final String data = await rootBundle.loadString('assets/lang/$code.json');
      final Map<String, dynamic> jsonMap = json.decode(data) as Map<String, dynamic>;
      strings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      if (code != 'en') {
        final String data = await rootBundle.loadString('assets/lang/en.json');
        final Map<String, dynamic> jsonMap = json.decode(data) as Map<String, dynamic>;
        strings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      }
    }

    return AppLocalizations(locale, strings);
  }

  String t(String key) => _strings[key] ?? key;
  String get localeName => locale.toLanguageTag();

  static String _localeCode(Locale locale) {
    if (locale.languageCode == 'zh') return 'zh';
    if (locale.languageCode == 'ms') return 'ms';
    return 'en';
  }

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? result = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'ms'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension LocalizationContext on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
  String t(String key) => AppLocalizations.of(this).t(key);
}
