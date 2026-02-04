import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'app.dart';
import 'shared/auth/auth_service.dart';
import 'shared/di/service_locator.dart';

/// Dev-only remote logger.
///
/// PURPOSE:
/// - In DEV (when [DEV_LOG_SERVER] is set), forward errors to the dev log server (POST /log).
/// - In PROD ([DEV_LOG_SERVER] not set, e.g. release build), no requests are made.
/// - Single utility for try/catch, API errors, GPS errors; easy to remove after dev phase.
class DevRemoteLogger {
  const DevRemoteLogger._();

  /// Set only in dev builds, e.g. --dart-define=DEV_LOG_SERVER=http://176.108.255.4:4000
  static const String _baseUrl = String.fromEnvironment(
    'DEV_LOG_SERVER',
    defaultValue: '',
  );

  static bool get _isDev => _baseUrl.isNotEmpty;

  static Future<void> logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) async {
    if (!_isDev) return;
    try {
      final path = _baseUrl.endsWith('/') ? '${_baseUrl}log' : '$_baseUrl/log';
      final uri = Uri.parse(path);
      final body = jsonEncode({
        'level': 'error',
        'message': message,
        'context': {
          'error': error.toString(),
          'stackTrace': stackTrace?.toString(),
          ...extra,
        },
      });

      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
    } catch (_) {
      // Swallow: logging must never crash the app.
    }
  }
}

void main() async {
  // Инициализация Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase
  await Firebase.initializeApp();
  
  // Инициализация Yandex MapKit
  // useAndroidViewSurface = false лучше работает на эмуляторах
  AndroidYandexMap.useAndroidViewSurface = false;

  // Single ApiClient and shared services (DI) — created once at app start
  ServiceLocator.init();

  // Инициализация сервисов текущего города и клуба (кеш + профиль).
  await ServiceLocator.currentCityService.init();
  await ServiceLocator.currentClubService.init();

  // Слушаем изменения состояния авторизации
  // При логине/логауте обновляем токен и уведомляем роутер
  AuthService.instance.authStateChanges.listen((user) async {
    if (user != null) {
      // Пользователь залогинился — обновляем токен
      await ServiceLocator.refreshAuthToken();
    } else {
      // Пользователь вышел — очищаем токен
      ServiceLocator.updateAuthToken(null);
    }
    // Уведомляем роутер о смене состояния
    authRefreshNotifier.refresh();
  });

  // Настройка обработчика ошибок Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    // Логируем в консоль для локальной разработки
    FlutterError.presentError(details);

    // Отправляем техническую информацию на backend (dev-only)
    DevRemoteLogger.logError(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
      extra: {'details': details.toString()},
    );
  };
  
  // Запуск приложения с обработкой необработанных асинхронных ошибок
  runZonedGuarded(
    () async {
      runApp(const RunterraApp());
    },
    (error, stackTrace) {
      // Обработка необработанных асинхронных ошибок
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
      
      DevRemoteLogger.logError(
        'Uncaught async error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
