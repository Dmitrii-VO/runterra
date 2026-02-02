# Изменения: Города

## История изменений

### 2026-01-29

- **Mobile API error handling (CitiesService):** в `getCities` и `getCityById` добавлена проверка `response.statusCode` и обработка не-JSON ответов по образцу `EventsService.getEvents()`: при статусе != 200 — `Exception`, при ответе не application/json или HTML — `FormatException`, парсинг JSON в try/catch. Устранена возможность FormatException при 404/500.
- **Runtime-валидация входных данных (backend):** Для эндпоинта `POST /api/cities` добавлена техническая runtime-валидация тела запроса через Zod-схему `CreateCitySchema` (на основе `CreateCityDto`). Валидация проверяет только форму и типы полей запроса (name и coordinates) без добавления бизнес-логики; при некорректном теле запроса backend возвращает `400 Bad Request` с описанием ошибок.
 - **Mobile: City details FutureBuilder:** `CityDetailsScreen` переведён на `StatefulWidget` с кэшированием `Future` загрузки деталей города в `initState`, чтобы избежать повторных HTTP-запросов при каждом `rebuild`; отображаемые поля и доменная модель не изменены.

### 2026-02-02

- **Backend City: center + bounds, in-memory конфиг:** модель `City` в backend расширена полями `center: GeoCoordinates` и `bounds: { ne; sw }` (тип `CityBounds`), добавлен in-memory конфиг городов `cities.config.ts` с записью для Санкт‑Петербурга (`id: "spb"`, центр и прямоугольные границы вокруг города). Эндпоинты `/api/cities` и `/api/cities/:id` переведены на использование этого конфига, `POST /api/cities` возвращает центр и bounds без сохранения (skeleton).
- **Shared utils для границ города:** добавлен модуль `city.utils.ts` с функциями `isPointWithinBounds` и `isPointWithinCityBounds`, используемый для валидации координат событий и территорий относительно выбранного города.
- **Mobile CityModel: центр и границы:** `CityModel` расширен полями `center` и `bounds` с обратной совместимостью (если `center`/`bounds` отсутствуют в JSON, `center` берётся из `coordinates`, `bounds` остаются null). Это позволяет использовать центр/границы города на карте без изменения существующих вызовов.
- **Code review fix — 5 ошибок в мульти-город коммите:**
  - `events.repository.ts` — `participantLimit`, `checkInLongitude`, `checkInLatitude`: `|| undefined` → `?? undefined` (значение `0` превращалось в `undefined`);
  - `city_picker_dialog.dart` — 4 хардкод-строки на русском заменены на `AppLocalizations` (добавлены ключи `cityPickerTitle`, `cityPickerLoadError`, `cityPickerEmpty`);
  - `territories.routes.ts` — mock `cityId: 'city-1'` → `'spb'`;
  - `event_list_item_model_test.dart` — добавлен `cityId` в тестовые JSON и проверки;
  - `map_screen.dart` — удалён `DevRemoteLogger.logError` для штатного `onMapCreated`.

