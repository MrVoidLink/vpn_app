import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _key = 'app_locale'; // مثلا 'fa' یا 'en'
  static final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  static Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_key);
    if (code != null && code.isNotEmpty) {
      locale.value = Locale(code);
    }
  }

  static Future<void> setLocale(String code) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, code);
    locale.value = Locale(code);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
    locale.value = null;
  }
}
