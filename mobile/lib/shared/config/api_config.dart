import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

// Conditional import: dart:io only for non-web platforms
import 'dart:io' if (dart.library.html) 'dart:html' as io;

/// Конфигурация API для работы с backend
///
/// Определяет baseUrl: production — всегда https; dev/emulator — можно переопределить
/// через --dart-define=API_BASE_URL=http://... (например http://10.0.2.2:3000).
///
/// ЗАЧЕМ: Безопасность — GPS и профиль не должны передаваться по HTTP в production.
/// Разные платформы для дефолта: Android эмулятор — 10.0.2.2, остальные — localhost.
///
/// ВАЖНО: Использует условный импорт dart:io для совместимости с Flutter Web.
class ApiConfig {
  /// Override from build/run: --dart-define=API_BASE_URL=http://10.0.2.2:3000 (dev only).
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Получает baseUrl для текущей платформы
  ///
  /// - Если задан API_BASE_URL (--dart-define) — возвращает его (для dev можно http://).
  /// - Иначе —:
  ///   - в debug: облачный dev backend (http://85.208.85.13:3000);
  ///   - в release/production: фиксированный продакшн backend (https://85.208.85.13:3000).
  ///
  /// Для Android: использует localhost по умолчанию (эмулятор определяется через API_BASE_URL).
  /// Для физических Android устройств использует localhost (или IP через API_BASE_URL).
  /// Cloud dev server (backend on Cloud.ru). Used as default in debug when API_BASE_URL is not set.
  static const String _cloudDevBaseUrl = 'http://85.208.85.13:3000';

  /// Production backend base URL. Used for mobile/desktop in release builds
  /// when API_BASE_URL is not provided via --dart-define.
  static const String _prodBaseUrl = 'https://85.208.85.13:3000';

  static String getBaseUrl() {
    final override = _envBaseUrl.trim();
    if (override.isNotEmpty) {
      return override.endsWith('/') ? override.substring(0, override.length - 1) : override;
    }
    // In debug builds, default to cloud backend so dev runs work without --dart-define.
    if (kDebugMode) {
      return _cloudDevBaseUrl;
    }

    // Flutter Web: в release также используем фиксированный production backend.
    if (kIsWeb) {
      return _prodBaseUrl;
    }

    // Для мобильных/десктоп клиентов по умолчанию используем фиксированный продакшн backend.
    // Локальная разработка и альтернативные окружения по-прежнему идут через API_BASE_URL.
    try {
      if (io.Platform.isAndroid ||
          io.Platform.isIOS ||
          io.Platform.isWindows ||
          io.Platform.isLinux ||
          io.Platform.isMacOS) {
        return _prodBaseUrl;
      }
    } catch (_) {
      // Fallback если Platform недоступен — используем продакшн backend.
      return _prodBaseUrl;
    }

    return _prodBaseUrl;
  }
}
