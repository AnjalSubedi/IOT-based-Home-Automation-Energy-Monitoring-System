// lib/data/providers/locale_provider.dart
// Manages language selection (English / Nepali) and persists choice.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_language';
  String _languageCode = 'en';

  String get languageCode => _languageCode;
  AppStrings get strings => AppStrings.of(_languageCode);
  bool get isNepali => _languageCode == 'ne';

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved != _languageCode) {
      _languageCode = saved;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
