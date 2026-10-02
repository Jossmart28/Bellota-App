# Plan de Implementación Fase 4: Inteligencia Clínica y Motor Predictivo

Este documento detalla la arquitectura y los pasos para implementar el análisis continuo de síntomas, alertas clínicas y predicciones reales en Bellota, eliminando los datos estáticos (*stubs*) actuales.

## 1. Reestructuración del Motor de Datos (Eliminación de *Stubs*)
- **Archivo:** `lib/database/database_helper.dart`
- **Problema actual:** `getTopSymptomsForPhase` devuelve siempre `['mood_swings', 'sensitivity', 'fatigue']`.
- **Solución:**
  - Extraer todos los registros de `daily_logs` de la usuaria.
  - Calcular la fase del ciclo en la que se encontraba la usuaria en la fecha de cada registro (usando retrospectivamente el `CycleService`).
  - Agrupar la frecuencia matemática de cada síntoma por fase.
  - Devolver los síntomas más frecuentes reales para la fase consultada.

## 2. Integración de Fertilidad y Datos en el Dashboard
- **Archivos:** `lib/screens/dashboard_screen.dart`, `lib/core/services/cycle_service.dart`
- **Problema actual:** Se pasa `fertilityData: null` al inicializar el dashboard.
- **Solución:** 
  - Ejecutar un query a SQLite para extraer la temperatura basal (`basal_temp`) y pruebas de ovulación (`lh_test_result`) de los últimos 45 días.
  - Inyectar estos datos a `CycleService.calculateCycleInfo()`.
  - Con esto, la ventana fértil y predicción de ovulación se basará en datos biológicos reales (shift térmico) y no solo en el calendario.

## 3. Motor de Alertas Clínicas Continuas (Clinical Alerts Engine)
- **Nuevo Archivo:** `lib/core/services/clinical_analysis_service.dart`
- **Responsabilidad:** Monitoreo en segundo plano de anomalías de salud.
- **Reglas Base:**
  - **Endometriosis / Dismenorrea Severa:** Si `nivelDolor >= 8` durante más de 2 días consecutivos.
  - **Menorragia:** Si los días de sangrado continuo superan los 7 días.
  - **Irregularidad de Ciclo:** Si los ciclos son menores a 21 días o mayores a 35 días de forma repetitiva.
  - **Alerta Oncológica / Mamaria:** Si se registra `breast_lump` (bulto), `breast_skin_change` o `breast_discharge`.

## 4. Dinamización de la Interfaz (Resumen Diario)
- **Archivo:** `lib/screens/resumen_diario_screen.dart`
- **Problemas actuales:** Fechas estáticas (`"17 sept"`), gráfico circular fijo.
- **Solución:**
  - Reemplazar el `_buildDateSelector` con un generador dinámico de fechas `DateTime.now()`.
  - Refactorizar `_CycleRingPainter` para que calcule los radianes del arco según la longitud real de las fases (ej. fase lútea = 14 días vs fase folicular dinámica).
  - Renderizar en UI los `todaySymptoms` y el `todayMood` que actualmente se pasan al Widget pero no se dibujan.

## 5. Integración Predictiva con el Sistema de Hospitales (Map Scores)
- **Archivo:** `lib/core/services/recommendation_engine.dart`
- **Solución:**
  - El motor de mapas consumirá el `Clinical Alerts Engine`.
  - Si hay alertas graves (ej. `breast_lump`), el algoritmo aplicará un multiplicador de peso (`x1.5` o `x2.0`) a los hospitales con etiquetas especializadas (ej. `oncologia`), alterando dinámicamente las recomendaciones en pantalla para proteger a la usuaria.
