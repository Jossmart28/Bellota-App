import 'package:bellotadevelopment/core/errors/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bellotadevelopment/core/constants/app_keys.dart';
import 'package:bellotadevelopment/core/services/auth_service.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/domain/repositories/user_repository.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';
import 'package:bellotadevelopment/domain/repositories/audit_repository.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';


class LanguageNotifier extends ValueNotifier<String> {
  static const supportedLocales = ['es', 'en', 'mi'];

  LanguageNotifier() : super('es');

  String get currentLang => value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(AppKeys.appLang) ?? 'es';
    value = supportedLocales.contains(lang) ? lang : 'es';
  }

  Future<void> _updateDbIfLoggedIn(String lang) async {
    try {
      final user = await AuthService.instance.currentSessionUser();
      if (user != null) {
        await sl<UserRepository>().updateUserLanguage(user.id, lang);
      }
    } catch (e) {
      AppLogger.d('Error syncing language to DB: $e');
    }
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
    await prefs.setString(AppKeys.appLang, value);
    await _updateDbIfLoggedIn(value);
  }

  Future<void> setLanguage(String lang) async {
    if (supportedLocales.contains(lang)) {
      value = lang;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppKeys.appLang, value);
      await _updateDbIfLoggedIn(value);
    }
  }
}

final languageNotifier = LanguageNotifier();
