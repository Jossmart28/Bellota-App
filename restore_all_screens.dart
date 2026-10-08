import 'dart:io';

/// Restaura TODOS los archivos de pantallas desde git y convierte todos
/// los imports relativos a imports absolutos de paquete.
void main() async {
  final map = {
    // Health log forms
    'lib/screens/flujo_vaginal_selection_screen.dart': 'lib/presentation/screens/health_log/flujo_vaginal_selection_screen.dart',
    'lib/screens/sexo_selection_screen.dart': 'lib/presentation/screens/health_log/sexo_selection_screen.dart',
    'lib/screens/patron_sangrado_screen.dart': 'lib/presentation/screens/health_log/patron_sangrado_screen.dart',
    'lib/screens/dolor_sintomatologia_screen.dart': 'lib/presentation/screens/health_log/dolor_sintomatologia_screen.dart',
    // Login
    'lib/screens/login_screen.dart': 'lib/presentation/screens/auth/login_screen.dart',
    // Dashboard
    'lib/screens/dashboard_screen.dart': 'lib/presentation/screens/home/dashboard_screen.dart',
  };

  for (final e in map.entries) {
    final r = await Process.run('git', ['show', 'HEAD:${e.key}']);
    if (r.exitCode != 0) { print('Cannot restore ${e.key}'); continue; }
    String f = r.stdout as String;
    f = fixImports(f);
    File(e.value).writeAsStringSync(f);
    print('Restored ${e.value}');
  }
}

String fixImports(String c) {
  // Fix relative and old-path imports to package-style
  final replacements = {
    "../theme/bellota_colors.dart": "package:bellotadevelopment/presentation/theme/bellota_colors.dart",
    "../widgets/bellota_top_actions.dart": "package:bellotadevelopment/presentation/widgets/bellota_top_actions.dart",
    "../widgets/cycle_ring_widget.dart": "package:bellotadevelopment/presentation/widgets/cycle_ring_widget.dart",
    "../widgets/": "package:bellotadevelopment/presentation/widgets/",
    "../database/database_helper.dart": "package:bellotadevelopment/core/di/injection_container.dart",
    "../core/di/injection_container.dart": "package:bellotadevelopment/core/di/injection_container.dart",
    "../core/": "package:bellotadevelopment/core/",
    "../domain/": "package:bellotadevelopment/domain/",
    "../l10n/": "package:bellotadevelopment/l10n/",
    "../navigation/": "package:bellotadevelopment/navigation/",
    "login_screen.dart'": "package:bellotadevelopment/presentation/screens/auth/login_screen.dart'",
    "dashboard_screen.dart'": "package:bellotadevelopment/presentation/screens/home/dashboard_screen.dart'",
    "onboarding_screen.dart'": "package:bellotadevelopment/presentation/screens/onboarding/onboarding_screen.dart'",
    "birth_year_screen.dart'": "package:bellotadevelopment/presentation/screens/onboarding/birth_year_screen.dart'",
    "privacy_policy_screen.dart'": "package:bellotadevelopment/presentation/screens/onboarding/privacy_policy_screen.dart'",
    "flujo_vaginal_selection_screen.dart'": "package:bellotadevelopment/presentation/screens/health_log/flujo_vaginal_selection_screen.dart'",
    "sexo_selection_screen.dart'": "package:bellotadevelopment/presentation/screens/health_log/sexo_selection_screen.dart'",
    "patron_sangrado_screen.dart'": "package:bellotadevelopment/presentation/screens/health_log/patron_sangrado_screen.dart'",
    "dolor_sintomatologia_screen.dart'": "package:bellotadevelopment/presentation/screens/health_log/dolor_sintomatologia_screen.dart'",
  };

  for (final rr in replacements.entries) {
    c = c.replaceAll("'${rr.key}", "'${rr.value}");
  }

  // Ensure flutter/material.dart
  if (!c.contains("package:flutter/material.dart")) {
    c = "import 'package:flutter/material.dart';\n" + c;
  }

  return c;
}
