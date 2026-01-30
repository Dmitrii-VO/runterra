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
  /// - Иначе — https с платформенным хостом (production: не передавать API_BASE_URL).
  ///
  /// Для Android: использует localhost по умолчанию (эмулятор определяется через API_BASE_URL).
  /// Для физических Android устройств использует localhost (или IP через API_BASE_URL).
  /// Cloud dev server (backend on Cloud.ru). Used as default in debug when API_BASE_URL is not set.
  static const String _cloudDevBaseUrl = 'http://85.208.85.13:3000';

  static String getBaseUrl() {
    final override = _envBaseUrl.trim();
    if (override.isNotEmpty) {
      return override.endsWith('/') ? override.substring(0, override.length - 1) : override;
    }
    // In debug builds, default to cloud backend so dev runs work without --dart-define.
    if (kDebugMode) {
      return _cloudDevBaseUrl;
    }
    const scheme = 'https://';
    const port = ':3000';
    
    // Flutter Web: всегда localhost
    if (kIsWeb) {
      return '${scheme}localhost$port';
    }
    
    // For non-web platforms, use Platform from dart:io
    // Conditional import ensures this works on Web (imports dart:html instead)
    // On Web, io.Platform will not exist, so we check kIsWeb first
    try {
      // Use io.Platform (aliased import) to avoid direct Platform reference
      // This works because conditional import resolves to Platform on mobile/desktop
      // and to a different type on Web (but we return early for Web above)
      if (io.Platform.isAndroid) {
        // TODO: Add proper emulator detection if needed
        // For now, use localhost for all Android (users can override via API_BASE_URL)
        return '${scheme}localhost$port';
      } else if (io.Platform.isIOS) {
        return '${scheme}localhost$port';
      } else if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
        return '${scheme}localhost$port';
      }
    } catch (e) {
      // Fallback if Platform is unavailable (should not happen due to kIsWeb check)
      return '${scheme}localhost$port';
    }
    
    return '${scheme}localhost$port';
  }
}
