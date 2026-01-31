# Mobile (Flutter)

Мобильное приложение Runterra.

## Текущая стадия

- ✅ Flutter skeleton инициализирован
- ✅ Минимальный MaterialApp
- ✅ Базовая структура проекта
- ✅ Базовый роутинг с BottomNavigationBar
- ✅ Экраны-заглушки: Profile и Map
- ✅ Yandex MapKit подключен (yandex_mapkit)
- ✅ MapScreen с пустой картой (фиксированный центр - Санкт-Петербург)
- ✅ UI-слои поверх карты (панель города, FAB, контейнер для карточек)
- ✅ Минимальное соединение с backend (HTTP)
- ✅ ApiClient для работы с backend API
- ✅ HealthService для проверки здоровья backend
- ✅ ProfileScreen отображает результат GET /health
- ✅ GPS / Location слой (LocationService)
- ❌ Без бизнес-логики
- ❌ Без маркеров, полигонов, интеграции геолокации с картой
- ❌ Без state management
- ❌ Без обработки ошибок

## Структура

```
lib/
  main.dart                    # Точка входа приложения
  app.dart                     # Основной MaterialApp widget с BottomNav
  features/
    map/
      map_screen.dart          # Экран карты с Yandex MapKit (территории, события, фильтры)
    profile/
      profile_screen.dart      # Экран профиля (отображает результат GET /health)
  shared/
    api/
      api_client.dart          # Базовый HTTP клиент для работы с backend API
      health_service.dart      # Сервис для проверки здоровья backend (GET /health)
    location/
      location_service.dart    # Сервис для работы с GPS / Location (разрешения, получение позиции)
    navigation/
      bottom_nav.dart          # Нижняя навигация для переключения между экранами
```

## Запуск

### Android (основная платформа)

```bash
flutter pub get
flutter run
```

Требуется Android эмулятор или физическое устройство.

### Windows (ограниченная поддержка)

**⚠️ Важно:** Yandex MapKit SDK не поддерживает Windows. Экран карты работает только на Android и iOS.

Для тестирования других экранов (без карты) можно использовать Windows:

```bash
flutter create --platforms windows .
flutter run -d windows
```

**Примечание:** Windows поддержка добавлена только для удобства тестирования skeleton'а. Основная платформа - Android.

## Платформы

- **Android-first** (основная платформа)
- iOS (поддерживается Yandex MapKit)
- Windows (опционально, для тестирования, но без карты)

## Зависимости

- `yandex_mapkit: ^4.0.0` - Yandex MapKit SDK для Flutter
- `http: ^1.1.0` - HTTP клиент для работы с backend API
- `geolocator: ^13.0.0` - Пакет для работы с GPS / Location

## Настройка Yandex MapKit

1. Получите API-ключ на [developer.tech.yandex.ru](https://developer.tech.yandex.ru/)
2. Ключ указывается в `android/app/src/main/AndroidManifest.xml` как `com.yandex.android.mapkit.ApiKey`
3. Для iOS добавьте ключ в `ios/Runner/AppDelegate.swift` (когда будете настраивать iOS)

**Текущее состояние:** API-ключ настроен.

## Навигация

Приложение использует простую навигацию через `BottomNavigationBar`:
- **Map** - экран с картой Yandex MapKit (центр: Санкт-Петербург) с UI-слоями:
  - Панель с названием города сверху (placeholder)
  - FloatingActionButton справа снизу (пустой)
  - Нижний полупрозрачный контейнер - задел под карточки
- **Profile** - экран профиля, отображает результат GET /health запроса к backend

Переключение между экранами происходит через нижнюю панель навигации. Логика навигации реализована через `StatefulWidget` без использования state management библиотек.

**Важно:** UI-слои на MapScreen - только визуальные элементы без логики, состояний и данных. Используются `Stack`, `Positioned`, `Container`, `FloatingActionButton` с TODO-комментариями для будущей реализации.

## Backend соединение

Приложение имеет минимальное соединение с backend через HTTP:

- **ApiClient** (`lib/shared/api/api_client.dart`) - базовый HTTP клиент с настраиваемым `baseUrl`
- **HealthService** (`lib/shared/api/health_service.dart`) - сервис для выполнения GET /health запроса
- **ProfileScreen** - при открытии автоматически выполняет GET /health и отображает результат как текст

**Текущая реализация:**
- BaseUrl захардкожен в экранах как `http://10.0.2.2:3000` (TODO: вынести в конфигурацию)
- Улучшенная обработка ошибок подключения с понятными сообщениями
- Парсинг JSON ответов в типизированные модели (ClubModel, CityModel, etc.)
- Нет state management (используется простой `StatefulWidget` и `FutureBuilder`)

**Важно:**
- **Для Android эмулятора:** Используется `10.0.2.2:3000` (специальный IP адрес эмулятора для доступа к хост-машине)
- **Для физического устройства:** Замените `10.0.2.2` на IP адрес вашего компьютера в локальной сети (например: `http://192.168.1.100:3000`)
- **Убедитесь, что backend сервер запущен:** Выполните `npm run dev` в папке `backend`

## Dev-логи (только в dev)

В dev-сборках ошибки (Flutter, API, GPS, карта) можно отправлять на удалённый лог-сервер. В PROD (release без define) отправка отключена.

- Запуск с отправкой логов:
  ```bash
  flutter run --dart-define=DEV_LOG_SERVER=http://176.108.255.4:4000
  ```
- Без define логов на сервер не отправляется.

Подробнее: [docs/changes/logging.md](../docs/changes/logging.md).

## API base URL (dev / production)

По умолчанию приложение использует **https** для запросов к backend. Для локальной разработки и эмулятора (когда backend без TLS) можно задать base URL через `--dart-define=API_BASE_URL=...`, например:

- Android эмулятор: `--dart-define=API_BASE_URL=http://10.0.2.2:3000`
- Локально: `--dart-define=API_BASE_URL=http://localhost:3000`

В production не передавать `API_BASE_URL` — тогда используется https. Подробнее: [docs/changes/api-client.md](../docs/changes/api-client.md).

## GPS / Location

Приложение имеет базовый слой для работы с геолокацией:

- **LocationService** (`lib/shared/location/location_service.dart`) - сервис-обёртка над geolocator
  - `checkPermission()` - проверка статуса разрешения на геолокацию
  - `requestPermission()` - запрос разрешения на геолокацию
  - `getCurrentPosition()` - получение текущей позиции устройства (одноразово)

**Текущая реализация:**
- Только одноразовое получение позиции (без continuous tracking)
- Только foreground работа (без background location)
- Нет обработки ошибок (TODO)
- Нет интеграции с картой (TODO)
- Android permissions настроены (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)

**Ограничения:**
- НЕ реализует трекинг позиции
- НЕ реализует фоновую работу
- НЕ сохраняет данные о позиции
- НЕ выполняет вычисления
