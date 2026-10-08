import 'package:logger/logger.dart';

/// AppLogger centraliza el registro de errores y eventos en la aplicación.
/// Reemplaza todos los `print()` y evita el silenciamiento de excepciones (`catch (_) {}`).
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, 
      errorMethodCount: 8, 
      lineLength: 120, 
      colors: true, 
      printEmojis: true, 
      printTime: true,
    ),
  );

  static void t(dynamic message) => _logger.t(message); // Trace
  static void d(dynamic message) => _logger.d(message); // Debug
  static void i(dynamic message) => _logger.i(message); // Info
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) => _logger.w(message, error: error, stackTrace: stackTrace); // Warning
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) => 
      _logger.e(message, error: error, stackTrace: stackTrace); // Error
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) => 
      _logger.f(message, error: error, stackTrace: stackTrace); // Fatal
}
