import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier extends ValueNotifier<String> {
  LanguageNotifier() : super('es');

  String get currentLang => value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_lang') ?? 'es';
    value = lang;
  }

  Future<void> toggle() async {
    // Cycle through: es -> mi -> en -> es
    if (value == 'es') {
      value = 'mi';
    } else if (value == 'mi') {
      value = 'en';
    } else {
      value = 'es';
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', value);
  }

  Future<void> setLanguage(String lang) async {
    value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', value);
  }
}

final languageNotifier = LanguageNotifier();
