# 🌰 Bellota App

> **Plataforma digital de seguimiento del ciclo menstrual, registro de síntomas y educación en salud femenina.**

![Version](https://img.shields.io/badge/versión-1.0.0-pink?style=flat-square)
![Flutter](https://img.shields.io/badge/Flutter-3.13%2B-02569B?style=flat-square&logo=flutter)
![Platform](https://img.shields.io/badge/plataforma-Android%20%7C%20iOS%20%7C%20Web-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/licencia-privada-red?style=flat-square)
![Offline](https://img.shields.io/badge/modo-Offline--First-success?style=flat-square)

---

## 📖 Descripción

**Bellota App** es una aplicación móvil construida con **Flutter** que permite a las usuarias:

- 📅 **Registrar y predecir** su ciclo menstrual con un calendario interactivo.
- 🩺 **Documentar diariamente** síntomas, flujo vaginal, cólicos y patrones de sangrado.
- 🗺️ **Localizar centros de salud** cercanos mediante geolocalización en tiempo real.
- 📄 **Exportar un reporte médico en PDF** con el historial clínico para consultas ginecológicas.

El sistema opera en modo **100 % local (Offline-First)**: todos los datos se almacenan en el dispositivo mediante SQLite, garantizando la privacidad absoluta de la usuaria. Adicionalmente, se incluye un módulo de backend experimental en **FastAPI** preparado para sincronizaciones futuras en la nube.

---

## 🚀 Inicio Rápido

### Requisitos Previos

| Herramienta | Versión mínima |
|---|---|
| Flutter SDK | 3.13+ |
| Dart SDK | 3.0+ |
| Android Studio / Xcode | Última versión estable |
| Python *(solo backend)* | 3.11+ |

### Instalación y Ejecución

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd bellotadevolpment

# 2. Instalar dependencias Flutter
flutter pub get

# 3. Ejecutar en modo desarrollo
flutter run

# 4. Compilar APK de release (Android)
flutter build apk --release

# 5. Compilar para iOS
flutter build ios --release
```

### Backend Experimental (Opcional)

```bash
cd backend

# Crear entorno virtual e instalar dependencias
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Iniciar el servidor
uvicorn app.main:app --reload
# API disponible en:    http://localhost:8000
# Docs interactivas:   http://localhost:8000/docs
```

---

## 🏗️ Arquitectura

El sistema está diseñado bajo el patrón **Local-First**, donde la app Flutter es completamente funcional sin conexión a internet.

```
┌─────────────────────────────────────────────────┐
│                  App Flutter                    │
│  (UI reactiva · Estado · Generación de PDF)     │
└────────────────┬────────────────────────────────┘
                 │
     ┌───────────┴───────────┐
     │                       │
┌────▼────────┐   ┌──────────▼──────────┐
│   SQLite    │   │  SharedPreferences  │
│ (bellota.db)│   │ (sesión · prefs)    │
│  sqflite   │   │                     │
└─────────────┘   └─────────────────────┘
                 │
     (futuro) ───┴──────────────────────
                 │
     ┌───────────▼──────────┐
     │  Backend FastAPI     │
     │  (Experimental)      │
     │  SQLAlchemy · SQLite │
     └──────────────────────┘
```

---

## 📁 Estructura del Proyecto

```
bellotadevolpment/
├── lib/
│   ├── core/                        # Modelos de dominio (UserModel, ProfileModel)
│   ├── database/
│   │   └── database_helper.dart     # Gestor SQFlite — tablas: users, profiles, daily_logs
│   ├── l10n/                        # Internacionalización (i18n)
│   ├── screens/                     # Pantallas de la aplicación
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── dashboard_screen.dart    # 🏠 Pantalla principal con fase actual y predicciones
│   │   ├── calendar_screen.dart     # 📅 Calendario menstrual interactivo
│   │   ├── symptom_log_screen.dart  # 📝 Registro diario de síntomas
│   │   ├── map_screen.dart          # 🗺️ Mapa de centros de salud (flutter_map)
│   │   ├── medical_report_preview_screen.dart  # 📄 Exportación de reporte PDF
│   │   ├── profile_screen.dart
│   │   ├── personal_data_screen.dart
│   │   ├── notifications_settings_screen.dart
│   │   └── ...                      # Pantallas de sintomatología detallada
│   ├── theme/                       # Sistema de diseño (BellotaColors)
│   ├── widgets/                     # Componentes UI reutilizables
│   └── main.dart
├── backend/                         # API REST Experimental (FastAPI)
│   ├── app/
│   │   ├── api/routers/             # Endpoints: logs.py, medications.py, profile.py
│   │   ├── core/database.py         # Configuración SQLAlchemy
│   │   ├── models/                  # Modelos ORM
│   │   └── main.py                  # Punto de entrada FastAPI
│   └── requirements.txt
├── assets/
│   ├── images/                      # Recursos gráficos
│   └── fonts/Estrella.ttf           # Tipografía corporativa
├── pubspec.yaml                     # Declaración de dependencias Flutter
├── DOCUMENTACION.md                 # Documentación técnica completa
└── diagrama_relacional.mmd          # Diagrama ER de la base de datos (Mermaid)
```

---

## 🧩 Módulos Principales

### 📅 Calendario Menstrual Automatizado
La usuaria ingresa el inicio de su menstruación; el sistema proyecta automáticamente las 4 fases del ciclo en el calendario y sincroniza notificaciones (píldora, ovulación, periodo).

### 🩺 Registro Diario de Síntomas
- **Vía rápida:** cambios de humor, fatiga, dolores generales.
- **Vía detallada:** tipo de flujo vaginal, intensidad de cólicos, patrones de sangrado y actividad sexual.

### 🗺️ Mapa de Centros de Salud
Basado en `flutter_map` + `latlong2`. Localiza a la usuaria y despliega pines de clínicas ginecológicas y centros de asistencia en tiempo real.

### 📄 Reporte Médico PDF
Exportación automatizada que cruza el historial de ciclos recientes y síntomas, generando un documento `.pdf` listo para presentar en consulta clínica.

---

## ⚙️ Motor de Cálculo de Fases

La lógica central reside en `database_helper.dart` y `dashboard_screen.dart`.

**Proyección del siguiente periodo:**
```
T_next = T_last + D_cycle
```

**Fase actual del ciclo** (día relativo `D = (Hoy − T_last) % D_cycle + 1`):

| Rango de días | Fase |
|---|---|
| D ≤ 5 | 🔴 Menstrual |
| 5 < D ≤ 13 | 🌱 Folicular |
| 13 < D ≤ 16 | 🌕 Ovulatoria |
| D > 16 | 🌙 Lútea |

---

## 📦 Dependencias Clave

| Paquete | Propósito |
|---|---|
| `sqflite` / `sqflite_common_ffi` | Base de datos SQLite local |
| `shared_preferences` | Sesión y preferencias clave-valor |
| `path_provider` | Rutas seguras del sistema de archivos |
| `flutter_map` / `latlong2` | Mapas interactivos y geoespaciales |
| `geocoding` | Geocodificación inversa |
| `pdf` / `printing` | Generación y exportación de reportes PDF |
| `image_picker` / `screenshot` | Foto de perfil y captura de widgets |
| `share_plus` / `url_launcher` | Compartir archivos y abrir enlaces |
| `intl` / `uuid` / `crypto` | Fechas, IDs únicos y hashing de contraseñas |
| `google_fonts` | Tipografías dinámicas |

---

## 🗄️ Esquema de Base de Datos (Local - SQLite)

```
USERS          1 ──────── 1   PROFILES
 id (PK)                       user_id (PK, FK)
 name                          username
 email (UK)                    cycle_duration
 password_hash                 period_duration
 created_at                    notif_periodo / pildora / ...

USERS          1 ──────── N   DAILY_LOGS
 id (PK)                       id (PK)
                                user_id (FK)
                                date
                                period_start
                                symptoms (JSON)
                                flujo (JSON)
                                sexo
                                created_at
```

> Ver el diagrama completo en [`diagrama_relacional.mmd`](./diagrama_relacional.mmd).

---

## 📚 Documentación Adicional


- 🗂️ [**diagrama_relacional.mmd**](./diagrama_relacional.mmd) — Diagrama entidad-relación de la base de datos (formato Mermaid).

