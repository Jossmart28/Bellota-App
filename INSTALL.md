<p align="center">
  <img src="assets/images/logo.png" alt="Bellota Logo" width="100"/>
</p>

<h1 align="center">🌰 Bellota — Guía de Instalación</h1>

<p align="center">
  <strong>Instrucciones paso a paso para clonar, configurar y ejecutar la app.</strong>
</p>

---

## ✅ Requisitos Previos

Antes de comenzar, asegúrate de tener instalado lo siguiente:

| Herramienta | Versión mínima | Verificar con |
|-------------|---------------|---------------|
| **Flutter SDK** | ≥ 3.13.0 | `flutter --version` |
| **Dart SDK** | ≥ 3.0.0 | `dart --version` |
| **Android Studio** | ≥ 2023.1 | Con Android SDK 34 |
| **Java JDK** | 17 | `java --version` |
| **Git** | ≥ 2.x | `git --version` |

> 💡 Si no tienes Flutter instalado, sigue la guía oficial: https://docs.flutter.dev/get-started/install

---

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/Jossmart28/Bellota-App.git
cd Bellota-App
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Verificar el entorno

```bash
flutter doctor -v
```

Asegúrate de que no haya errores críticos antes de continuar.

### 4. Conectar un dispositivo o emulador

- **Dispositivo físico:** Activa la **depuración USB** en tu Android y conecta el cable.
- **Emulador:** Abre Android Studio → AVD Manager → inicia un emulador.

Verifica que el dispositivo esté reconocido:

```bash
flutter devices
```

### 5. Ejecutar la app

```bash
# Modo debug (con hot reload)
flutter run

# Modo release (rendimiento óptimo)
flutter run --release
```

---

## 📦 Compilar APK

Si quieres generar el instalador `.apk`:

```bash
# APK universal
flutter build apk --release

# APKs separadas por arquitectura (más livianas, recomendado)
flutter build apk --release --split-per-abi
```

El archivo generado estará en:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Instalar APK en un dispositivo

Con el dispositivo conectado por USB y la depuración USB activa:

```bash
flutter install --release
```

O copia el archivo `app-release.apk` manualmente al teléfono, ábrelo desde el explorador de archivos y activa **Instalar desde orígenes desconocidos** si se solicita.

---

## 🔍 Verificar calidad del código

```bash
flutter analyze
```

---

## 🗒️ Notas

- La app funciona **100% offline** — no requiere servidor ni base de datos externa.
- El directorio `backend/` contiene un servidor FastAPI **opcional** para sincronización futura. No es necesario para usar la app.

---

<p align="center">
  <sub>Hecho con ❤️ para la salud femenina · <strong>Bellota 2024 – 2026</strong></sub>
</p>
