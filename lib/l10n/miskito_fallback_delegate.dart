import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/cupertino.dart';

class MiskitoMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const MiskitoMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'mi';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return await GlobalMaterialLocalizations.delegate.load(const Locale('es'));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}

class MiskitoCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const MiskitoCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'mi';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('es'));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

class MiskitoWidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  const MiskitoWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'mi';

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    return await GlobalWidgetsLocalizations.delegate.load(const Locale('es'));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<WidgetsLocalizations> old) => false;
}
