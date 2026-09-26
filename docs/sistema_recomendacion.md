# Sistema de Recomendación de Hospitales (Fase 4)

Este documento detalla la arquitectura y el funcionamiento del algoritmo de recomendación basado en síntomas implementado en la aplicación Bellota.

## Arquitectura

El sistema está compuesto por los siguientes módulos principales:

1. **`UserHealthProfileService`**: Se encarga de unificar los datos médicos de la usuaria recopilados desde diferentes fuentes (SharedPreferences y SQLite). Extrae condiciones médicas, anticonceptivos, medicamentos y el historial de síntomas (físicos, emocionales y generales) de los últimos 14 días.
2. **`SymptomHospitalMapping`**: Un diccionario estático (`symptomToSpecialty` y `medicalConditionToSpecialty`) que actúa como puente para traducir un síntoma específico (ej. `pelvic_pain`) o condición médica (ej. `pcos`) a una o más especialidades hospitalarias requeridas (ej. `ginecologia`, `endocrinologia`).
3. **`RecommendationEngine`**: El algoritmo central de puntuación.
4. **`HospitalHubScreen`**: La interfaz gráfica que consume el motor y presenta la información con internacionalización (i18n).

## Algoritmo de Puntuación (Scoring)

El algoritmo evalúa a cada hospital disponible usando una fórmula con base de 100 puntos (o porcentaje) que pondera 4 criterios fundamentales:

| Criterio | Peso Máximo | Descripción |
|----------|------------|-------------|
| **Ubicación** | 40% | Utiliza la fórmula Haversine. Máximo puntaje si la distancia es 0 km, decayendo linealmente hasta 0 puntos a los 25 km de distancia. |
| **Síntomas Recientes** | 25% | Calcula un índice de Jaccard modificado. Si las especialidades derivadas de los síntomas de la usuaria coinciden con los tags del hospital, el puntaje sube. Si el hospital cuenta con servicio de "Emergencia General", recibe un puntaje compensatorio parcial (salvavidas) del 30% de esta categoría, aun si no hace match exacto. |
| **Condiciones Médicas** | 20% | Se evalúa si el hospital tiene las especialidades necesarias para atender las condiciones pre-existentes de la paciente (SOP, Endometriosis, etc.). |
| **Relevancia Base** | 15% | Puntuación estática del hospital según su nivel de equipamiento o popularidad predefinida en la base de datos. |

## Escalabilidad y Mantenimiento

- **Para agregar nuevos síntomas:** Simplemente añade una nueva llave al mapa `symptomToSpecialty` en `lib/core/data/symptom_hospital_mapping.dart`.
- **Para agregar nuevos hospitales:** Utiliza el repositorio `HospitalRepository` e inserta una nueva instancia de `HealthCenter`.
- **Traducciones:** El sistema UI está 100% acoplado a `AppLocalizations` (`.arb` files) garantizando su internacionalización.
