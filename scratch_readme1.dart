import 'dart:io';

void main() {
  final file = File('README.md');
  final lines = file.readAsLinesSync();

  // ═══ CHANGE 1: Architecture Diagram - Update Services Layer (lines ~113-121) ═══
  // Find and update the services layer in the ASCII art
  for (int i = 0; i < lines.length; i++) {
    // Update screen count
    if (lines[i].contains('27 Screens')) {
      lines[i] = lines[i].replaceFirst('27 Screens', '32 Pantallas');
    }
    // Update ClinicalAnalysisService description
    if (lines[i].contains('ClinicalAnalysisService') && lines[i].contains('Motor de alertas')) {
      lines[i] = lines[i].replaceFirst('Motor de alertas médicas (semáforo)', 'Motor de alertas + HealthcareRoutingService');
    }
    // Update RecommendationEngine description
    if (lines[i].contains('RecommendationEngine') && lines[i].contains('Matching hospitales')) {
      lines[i] = lines[i].replaceFirst('Matching hospitales ↔ síntomas', 'Matching por HealthcareTier ↔ hospitales');
    }
    // Fix symptom_hospital_mapping reference
    if (lines[i].contains('symptom_hospital_mapping.dart')) {
      lines[i] = '│   │   │   └── hospital_repository.dart     # Repositorio + filtrado por tiers';
    }
    // Remove duplicate hospital_repository line
    if (lines[i].contains('hospital_repository.dart') && lines[i].contains('Repositorio de acceso a hospitales')) {
      lines[i] = '';
    }
    // Update screens count reference
    if (lines[i].contains('──── 27 Pantallas ────')) {
      lines[i] = lines[i].replaceFirst('──── 27 Pantallas ────', '──── 32 Pantallas ────');
    }
  }

  file.writeAsStringSync(lines.join('\r\n'));
  print('DONE: basic README fixes applied');
}
