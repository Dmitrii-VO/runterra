# ApiClient и авторизация в мобильных API-запросах

**Дата:** 2026-01-29  
**Тип:** Безопасность  
**Статус:** Завершено

## Проблема

В мобильном приложении `ApiClient` не отправлял заголовок `Authorization` в запросах к backend. Backend ожидает `Authorization: Bearer <token>` (auth middleware); без токена защищённые эндпоинты возвращают `401 Unauthorized`. Механизма инъекции токена в клиент не было.

## Решение

В `mobile/lib/shared/api/api_client.dart` добавлено:

1. **Опциональный параметр конструктора `authToken`**  
   При создании `ApiClient(baseUrl: ..., authToken: idToken)` клиент сохраняет токен и подставляет его во все исходящие запросы.

2. **Автоматический заголовок для GET и POST**  
   - При `authToken != null` и непустом значении к каждому запросу добавляется заголовок `Authorization: Bearer <token>`.
   - Для GET: заголовки передаются в `http.Client.get(uri, headers: _authHeaders)`.
   - Для POST: `_authHeaders` мержатся в `requestHeaders` вместе с `Content-Type` и опциональными заголовками вызова.

3. **Обратная совместимость**  
   Параметр `authToken` опционален. Существующий код `ApiClient(baseUrl: baseUrl)` без токена продолжает работать (заголовок Authorization не добавляется).

## Ответственность вызывающего кода

- **Получение токена** (например Firebase ID token через `FirebaseAuth.instance.currentUser?.getIdToken()`) и момент передачи в `ApiClient` в данной задаче не реализованы — это отдельная интеграция (экран входа, глобальный провайдер и т.д.).
- Цель изменения — обеспечить **механизм** инъекции токена и единообразную отправку `Authorization: Bearer` во всех запросах, идущих через `ApiClient`.

## Затронутые файлы

- `mobile/lib/shared/api/api_client.dart` — добавлены `authToken`, геттер `_authHeaders`, использование заголовков в `get()` и `post()`.

Сервисы (`*_service.dart`) и экраны, создающие `ApiClient`, пока не изменялись: они по-прежнему могут создавать клиент без токена. Для реальной авторизации потребуется передавать токен при создании `ApiClient` (например из общего места, где хранится текущий пользователь/токен).

---

## Base URL и HTTPS (2026-01-29, обновление 2026-02-06)

**Тип:** Безопасность  
**Проблема:** Все base URL использовали `http://`; GPS-координаты и данные профиля передавались в открытом виде.

**Решение:**

В `mobile/lib/shared/config/api_config.dart`:

1. **Production по умолчанию — https.** Изначально при отсутствии переменной окружения `getBaseUrl()` возвращал URL с схемой `https://` и тем же платформенным хостом (localhost, 10.0.2.2 для Android эмулятора).

2. **Dev/emulator — http через env.** Для локальной разработки и эмулятора можно задать полный base URL через `--dart-define=API_BASE_URL=...` при запуске/сборке, например:
   - `--dart-define=API_BASE_URL=http://10.0.2.2:3000` (Android эмулятор)
   - `--dart-define=API_BASE_URL=http://localhost:3000` (десктоп / симулятор)

3. **Реализация (обновлено 2026-02-06):**
   - Если задан `API_BASE_URL` — возвращается он (без завершающего слэша).
   - Если не задан и сборка **debug** — используется облачный dev backend `http://85.208.85.13:3000`.
   - Если не задан и сборка **release/production**:
     - для Flutter Web — `https://localhost:3000` (ожидается reverse-proxy на том же origin);
     - для mobile/desktop — фиксированный продакшн backend `https://85.208.85.13:3000` (без localhost по умолчанию).

**Затронутые файлы:** `mobile/lib/shared/config/api_config.dart`.

---

## Cloud dev base URL по умолчанию в debug (2026-01-31)

**Тип:** Конфигурация  
**Проблема:** Для разработки против облачного backend (Cloud.ru, 85.208.85.13:3000) приходилось каждый раз передавать `--dart-define=API_BASE_URL=http://85.208.85.13:3000`.

**Решение:**

В `mobile/lib/shared/config/api_config.dart`:

- В **debug-сборках** (`kDebugMode`), если `API_BASE_URL` не задан через `--dart-define`, `getBaseUrl()` возвращает облачный URL `http://85.208.85.13:3000`.
- В **release/production** логика без изменений: при отсутствии define используется https с платформенным хостом.
- Переопределение через `--dart-define=API_BASE_URL=...` по-прежнему имеет приоритет (например для локального backend или эмулятора).

**Затронутые файлы:** `mobile/lib/shared/config/api_config.dart`.

---

## ApiClient singleton и dispose — утечка ресурсов (2026-01-29)

**Тип:** Утечка ресурсов  
**Проблема:** `ApiClient` создавал `http.Client()` в конструкторе и никогда не вызывал `close()`. Каждый экран создавал новый `ApiClient` — накапливались незакрытые сокеты.

**Решение:**

В `mobile/lib/shared/api/api_client.dart`:

1. **Синглтон** — статический метод `getInstance({required String baseUrl, String? authToken, http.Client? client})` возвращает один и тот же экземпляр; первый вызов создаёт его, последующие переиспользуют. Один `http.Client` на всё приложение.

2. **Конструктор** остаётся публичным для тестов и инъекции `client`; в production код использует только `getInstance()`.

3. **dispose()** — закрывает `_client`, если он был создан этим экземпляром (`_ownsClient`), и сбрасывает статический `_instance`, чтобы следующий `getInstance()` создал новый экземпляр. Вызывать в production не обязательно; предназначено для тестов и явного завершения (например при logout).

4. **Затронутые вызовы:** все места, создававшие `ApiClient(baseUrl: ...)`, переведены на `ApiClient.getInstance(baseUrl: ...)`:
   - `run_service.dart`, `events_screen.dart`, `map_screen.dart`, `activity_details_screen.dart`, `city_details_screen.dart`, `club_details_screen.dart`, `territory_details_screen.dart`, `event_details_screen.dart`, `global_chat_tab.dart`, `club_messages_tab.dart`, `profile_screen.dart`.

---

## ServiceLocator (DI) — ApiClient и сервисы один раз на старте (2026-01-29)

**Тип:** Архитектура / утечка ресурсов  
**Проблема:** Около 10 экранов дублировали цепочку `ApiConfig.getBaseUrl()` → `ApiClient.getInstance(baseUrl:)` → `XxxService(apiClient:)` при каждом вызове fetch. ApiClient уже был синглтоном, но сервисы создавались заново; не было единой точки инициализации.

**Решение:**

1. **ServiceLocator** (`mobile/lib/shared/di/service_locator.dart`) — статический класс с методом `init()`. Создаёт один раз: `ApiClient` (через `getInstance(baseUrl: ApiConfig.getBaseUrl())`), `LocationService`, все API-сервисы (`ActivitiesService`, `CitiesService`, `ClubsService`, `EventsService`, `MapService`, `MessagesService`, `RunService`, `TerritoriesService`, `UsersService`). `RunService` получает общий `ApiClient` и общий `LocationService`.

2. **Инициализация в main()** — в `main.dart` после `Firebase.initializeApp()` вызывается `ServiceLocator.init()`; экраны больше не вызывают `getBaseUrl()`/`getInstance()`/конструкторы сервисов.

3. **Экраны и вкладки** берут сервисы из локатора: `ServiceLocator.eventsService`, `ServiceLocator.mapService`, `ServiceLocator.runService` и т.д. Импорты `ApiConfig` и `ApiClient` в feature-экранах удалены (кроме случаев, где нужен тип, например `ApiException` из `users_service.dart`).

4. **MapScreen:** использует `ServiceLocator.mapService` и `ServiceLocator.locationService`; больше не создаёт и не диспозит свой экземпляр `LocationService` (общий экземпляр принадлежит локатору).

**Затронутые файлы:**  
- Добавлен: `mobile/lib/shared/di/service_locator.dart`.  
- Изменены: `main.dart` (вызов `ServiceLocator.init()`), `activity_details_screen.dart`, `city_details_screen.dart`, `club_details_screen.dart`, `territory_details_screen.dart`, `event_details_screen.dart`, `events_screen.dart`, `map_screen.dart`, `profile_screen.dart`, `run_screen.dart`, `global_chat_tab.dart`, `club_messages_tab.dart` — переход на `ServiceLocator.*`.
