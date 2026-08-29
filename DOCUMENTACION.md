# 🌰 Sistema de Asistencia de Salud Menstrual
Documentación Técnica, Arquitectura de Software y Fundamentos de Cálculo

**BELLOTA APP V1.0**

> **Resumen del Proyecto:** Plataforma digital interactiva para el seguimiento del ciclo menstrual, registro de síntomas y educación en salud femenina. A través de la aplicación móvil (Flutter), la usuaria registra las fechas de su periodo y documenta diariamente síntomas (dolor, flujo vaginal, patrón de sangrado). La aplicación despliega un tablero de control (dashboard) dinámico con la fase del ciclo actual, predicciones del próximo periodo y centros de salud cercanos mediante geolocalización. El sistema opera de manera 100% local, asegurando la privacidad absoluta de los datos mediante almacenamiento interno del dispositivo, y permite la exportación de un reporte médico en PDF detallado para consultas clínicas.

## Tabla de Contenidos

1. Arquitectura y Flujo de Datos
2. Módulos del Ecosistema
    1. Calendario Menstrual Automatizado
    2. Registro Diario de Síntomas y Salud
    3. Mapa de Centros de Salud (Geolocalización)
    4. Gestor de Reportes Médicos
3. Motor de Cálculo: Fundamentos Algorítmicos
4. Dependencias del Sistema
5. Variables de Entorno y Configuración Local
6. Estructura Modular del Proyecto
7. Scripts de Ejecución y Despliegue
8. Ejemplos de Interacción de Datos (Local y API)
9. Referencias Bibliográficas

---

### 1. Arquitectura y Flujo de Datos
El sistema está diseñado bajo un enfoque prioritario **Local / Offline-First**, garantizando que la información sensible nunca salga del dispositivo sin el permiso de la usuaria.

1. **App (Flutter):** Interfaz de usuario interactiva. Gestiona el estado reactivo, captura los *daily logs*, genera el reporte médico en PDF y renderiza el mapa.
2. **Almacenamiento Local Robusto:** 
   * **Base de Datos (SQLite):** A través de `sqflite` (archivo `bellota.db`), guarda perfiles de usuaria, configuraciones de notificaciones (píldora, periodo, ovulación), e historial diario (fases, flujo, relaciones sexuales).
   * **Archivos y Caché:** Uso de `path_provider` y `shared_preferences` para almacenar imágenes de perfil, preferencias de sesión (Login) e identificadores locales.
3. **Backend Experimental (FastAPI):** Se incluye en el repositorio un módulo de API REST en Python (FastAPI + SQLAlchemy) preparado para futuras sincronizaciones en la nube, aunque el flujo actual de la aplicación se abastece íntegramente de la base de datos local.

### 2. Módulos del Ecosistema

**1. Calendario Menstrual Automatizado**
Línea de tiempo interactiva (`calendar_screen.dart`) que se adapta al ciclo biológico.
* **Funcionamiento:** La usuaria ingresa el inicio de su menstruación y ajusta la duración de su ciclo en el perfil.
* **Automatización:** El sistema proyecta sus fases en el calendario y se sincroniza con el Dashboard principal, habilitando notificaciones oportunas (píldora, periodo, ovulación).

**2. Registro Diario de Síntomas y Salud**
Captura dinámica del bienestar físico.
* **Vía A — Sintomatología Rápida:** Parámetros como cambios de humor, fatiga o dolores.
* **Vía B — Análisis Físico Detallado:** Módulos para tipo de flujo vaginal (`flujo_vaginal_selection_screen.dart`), intensidad de cólicos (`dolor_sintomatologia_screen.dart`), y patrones de sangrado.

**3. Mapa de Centros de Salud (Geolocalización)**
Módulo asistencial.
* Interfaz basada en `flutter_map` y `latlong2` (`map_screen.dart`) que localiza a la usuaria y despliega pines de clínicas ginecológicas y de asistencia.

**4. Gestor de Reportes Médicos**
Traducción de historial clínico.
* Exportación automatizada (`medical_report_preview_screen.dart`) que cruza el historial de la usuaria, permitiendo generar un archivo `.pdf` que documenta el comportamiento de sus ciclos recientes.

### 3. Motor de Cálculo: Fundamentos Algorítmicos

Lógica central (`database_helper.dart` y `dashboard_screen.dart`) para el análisis de ciclos.

**Paso A — Proyección del Siguiente Ciclo (T_next)**
```text
T_next = T_last + D_cycle
```
* **T_last**: Fecha del último inicio de periodo extraída de `daily_logs` (`period_start = 1`).
* **D_cycle**: Duración promedio del ciclo (por defecto `28` en la tabla `profiles`).

**Paso B — Determinación de la Fase Actual (F_current)**
Día relativo del ciclo: `D_current = (Fecha_Hoy - T_last) % D_cycle + 1`

* Si `D_current <= 5` → **Fase Menstrual**
* Si `5 < D_current <= 13` → **Fase Folicular** 
* Si `13 < D_current <= 16` → **Fase Ovulatoria**
* Si `D_current > 16` → **Fase Lútea**

### 4. Dependencias del Sistema

**App Mobile (Flutter 3.13+) - Ecosistema Local**

| Paquete | Uso y Descripción |
| :--- | :--- |
| **Persistencia y Local** | |
| `sqflite` / `sqflite_common_ffi` | Base de datos relacional local (SQLite). Almacenamiento primario. |
| `shared_preferences` | Almacenamiento rápido clave-valor para sesiones y configuraciones. |
| `path_provider` / `path` | Resolución de rutas seguras en el sistema de archivos del dispositivo. |
| **Mapas y Geolocalización** | |
| `flutter_map` / `latlong2` | Mapeo interactivo vectorial y cálculos geoespaciales (offline/online). |
| `geocoding` | Conversión de coordenadas a direcciones (Geocodificación inversa). |
| **Multimedia y Exportación** | |
| `pdf` / `printing` | Construcción de documentos PDF nativos y diálogo de impresión. |
| `screenshot` / `image_picker` | Captura de widgets a imagen y selección de foto de perfil. |
| `share_plus` / `url_launcher` | Compartir archivos/reportes y apertura de enlaces externos. |
| **Utilidades Core** | |
| `intl` / `uuid` / `crypto` | Formateo de fechas, generación de IDs únicos, y hashing local de contraseñas. |
| `google_fonts` / `cupertino_icons` | Tipografías dinámicas y set de iconos de sistema. |

**Backend Experimental (Python 3.11+ / FastAPI)**

| Paquete | Uso y Descripción |
| :--- | :--- |
| `fastapi` / `uvicorn` | Framework principal de la API REST y servidor ASGI. |
| `sqlalchemy` / `pydantic` | ORM relacional (sobre SQLite) y validación de esquemas. |

### 5. Variables de Entorno y Configuración Local

Debido a su naturaleza local, la app inicializa dinámicamente el archivo `bellota.db` vía `path_provider`. Para el entorno backend, la configuración es:

```python
# backend/app/core/database.py
SQLALCHEMY_DATABASE_URL="sqlite:///./backend.db"
```

### 6. Estructura Modular del Proyecto

```text
bellotadevolpment/
├── backend/                   # Carpeta de API REST Experimental
│   ├── app/
│   │   ├── api/routers/       # Endpoints (logs.py, medications.py, profile.py)
│   │   ├── core/              # Config (database.py)
│   │   ├── models/            # SQLAlchemy DB Models
│   │   └── main.py            # Punto de entrada FastAPI
│   └── requirements.txt
├── lib/
│   ├── core/                  # Modelos Flutter (UserModel, ProfileModel)
│   ├── database/
│   │   └── database_helper.dart # Gestor SQFlite (Tablas users, profiles, daily_logs)
│   ├── l10n/                  # Internacionalización 
│   ├── screens/               # Módulos: Dashboard, Calendar, Map, MedicalReport...
│   ├── theme/                 # Colores corporativos (BellotaColors)
│   └── widgets/               # UI reutilizable
├── pubspec.yaml               # Declaración exhaustiva de dependencias
└── README.md
```

### 7. Scripts de Ejecución y Despliegue

**App Mobile (Flutter)**
```bash
# Instalar todas las dependencias (sqflite, path_provider, pdf, etc.)
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Compilar APK de release para producción (Local-First)
flutter build apk --release
```

### 8. Ejemplos de Interacción de Datos (Local y API)

Al operar localmente, el sistema ejecuta transacciones nativas SQLite mediante Dart.

**1. Consulta Local (Flutter / SQFlite): Registrar Síntomas Diarios**
```dart
// En database_helper.dart
final data = {
  'user_id': userId,
  'date': '2026-08-27',
  'period_start': 1,
  'symptoms': jsonEncode(['dolor_severo', 'fatiga']),
  'flujo': jsonEncode(['abundante']),
};
await db.insert('daily_logs', data);
```

**2. Endpoint Equivalente (Backend API REST Experimental)**
Base URL: `http://localhost:8000`

`POST /logs/`

**Request Body:**
```json
{
  "user_id": 12,
  "date": "2026-08-27",
  "period_start": 1,
  "symptoms": "[\"dolor_severo\", \"fatiga\"]"
}
```

### 9. Referencias Bibliográficas

1. ACOG, *Menstruation in Girls and Adolescents: Using the Menstrual Cycle as a Vital Sign*, Committee Opinion No. 651, 2015.
2. Flutter Development Documentation, *sqflite, shared_preferences & path_provider plugins for Flutter*, 2026.
