# Промпт: Реализация Feedback 2026-02-14

Используй этот промпт для реализации задач из docs/changes/feedback-2026-02-14.md.

---

## Контекст

Проект Runterra (Flutter mobile, Node.js backend). Стек и правила — см. .cursorrules, CLAUDE.md. Перед изменениями прочитай docs/product_spec.md и релевантные docs/changes/*.

---

## Задача 1: Перенос настроек профиля в «Редактирование профиля»

### Цель

Перенести из раздела **Профиль** в раздел **Редактирование профиля**:
- Геолокация (тап → открытие настроек приложения)
- Видимость профиля (Switch)
- Выйти из аккаунта
- Удалить аккаунт

### Текущее состояние

- `ProfileScreen` (mobile/lib/features/profile/profile_screen.dart) отображает `ProfileSettingsSection` с этими четырьмя элементами.
- `ProfileSettingsSection` (mobile/lib/shared/ui/profile/settings_section.dart) — Card с ListTile для геолокации, Switch для видимости, ListTile для выхода и удаления.
- `EditProfileScreen` (mobile/lib/features/profile/edit_profile_screen.dart) принимает `ProfileUserData user`, содержит форму (имя, фамилия, страна, дата рождения, пол, город, URL фото).
- Переход на редактирование: `context.push('/profile/edit', extra: profile.user)`.
- `ProfileUserData` содержит `profileVisible: bool`.
- Для геолокации нужен `LocationPermission` — `ProfileScreen` вызывает `_checkLocationPermission()` и хранит `_locationPermissionGranted`. EditProfileScreen не имеет доступа к профилю целиком, только к `user`.

### План реализации

1. **Изменить маршрут `/profile/edit`** — передавать `ProfileModel` или `ProfileUserData` + `profileVisible` + `locationPermissionGranted`. Сейчас передаётся только `profile.user`. Варианты:
   - Передавать `extra: profile` (ProfileModel) — тогда EditProfileScreen получит profile.user, profile.user.profileVisible, а для геолокации нужно либо вызывать LocationService в EditProfileScreen, либо передавать флаг.
   - Или передавать `extra: {'user': profile.user, 'profileVisible': profile.user.profileVisible}` и в EditProfileScreen проверять геолокацию через `LocationService.checkPermission()` в initState.

2. **ProfileScreen:**
   - Удалить `ProfileSettingsSection` из `_buildBody`.
   - Удалить state `_locationPermissionGranted`, `_profileVisibleOverride`, `_savingProfileVisible` и связанную логику (они переедут в EditProfileScreen).
   - Удалить `_checkLocationPermission()` из initState.
   - Удалить импорт `ProfileSettingsSection` и `settings_section.dart`.

3. **EditProfileScreen:**
   - Расширить конструктор: принимать `ProfileUserData user` и `bool profileVisible` (или `ProfileModel profile`).
   - Добавить `initState`: проверка `LocationService.checkPermission()` → `_locationPermissionGranted`.
   - Добавить state: `_profileVisibleOverride`, `_savingProfileVisible` (аналогично текущей логике в ProfileScreen).
   - После формы (перед кнопкой «Сохранить» или после неё) добавить блок настроек:
     - Геолокация: ListTile с иконкой location_on, subtitle (Allowed/Denied), onTap → `Geolocator.openAppSettings()`.
     - Видимость профиля: ListTile с Switch, вызов `UsersService.updateProfile(profileVisible:)`, обработка ошибок через SnackBar.
     - Выйти из аккаунта: ListTile (красный), диалог подтверждения (logoutTitle, logoutConfirm), при подтверждении — `AuthService.signOut()`, `ServiceLocator.updateAuthToken(null)`, `authRefreshNotifier.refresh()`, `context.go('/login')`.
     - Удалить аккаунт: ListTile (красный), диалог (deleteAccountTitle, deleteAccountConfirm), при подтверждении — `UsersService.deleteAccount()`, затем signOut и go('/login'); при ошибке — SnackBar с ApiException.message.
   - Использовать все строки через `AppLocalizations.of(context)!` (settingsLocation, settingsVisibility, settingsLogout, settingsDeleteAccount и т.д.).

4. **app.dart:**
   - Обновить route `/profile/edit`: `state.extra` должен быть `ProfileModel` или `Map` с user + profileVisible. Если передаём ProfileModel — `EditProfileScreen(profile: profile)` или `EditProfileScreen(user: profile.user, profileVisible: profile.user.profileVisible)`.

5. **ProfileScreen** (кнопка «Редактировать»):
   - Сейчас: `context.push('/profile/edit', extra: profile.user)`.
   - Изменить на: `context.push('/profile/edit', extra: profile)` — передаём весь ProfileModel. EditProfileScreen будет принимать `ProfileModel profile` и брать `profile.user`, `profile.user.profileVisible`.

6. **ProfileSettingsSection:**
   - Вариант A: Удалить файл, если логика полностью перенесена в EditProfileScreen.
   - Вариант B: Вынести в отдельный виджет `_EditProfileSettingsBlock` внутри edit_profile_screen.dart (приватный виджет) для переиспользования — если хочешь сохранить Card/стиль.

### Ограничения

- Не вызывать HTTP в FutureBuilder.future — использовать StatefulWidget и initState.
- Строки — только через l10n (app_en.arb, app_ru.arb).
- ApiClient — только через ServiceLocator.

### Файлы для изменения

- `mobile/lib/features/profile/profile_screen.dart`
- `mobile/lib/features/profile/edit_profile_screen.dart`
- `mobile/lib/app.dart`
- `mobile/lib/shared/ui/profile/settings_section.dart` (удалить или оставить пустым/переиспользовать)

### Проверки

- Профиль: нет блока «Геолокация / Видимость / Выйти / Удалить» на главном экране профиля.
- Редактирование профиля: при открытии «Редактировать» — видны форма + блок настроек; геолокация, видимость, выход, удаление работают как раньше.
- После выхода/удаления — переход на /login.

---

## Задача 2 (опционально): Backend — поддержка onlyOpen в GET /api/events

### Цель

Добавить параметр `onlyOpen=true` в `GET /api/events`. При `onlyOpen=true` возвращать только события со статусом `open` (исключать `full`).

### Текущее состояние

- Backend `events.routes.ts` не извлекает `onlyOpen` из query.
- `EventsRepository.findAll()` не принимает `onlyOpen`; по умолчанию возвращает `status IN ('open', 'full')` и `end_date_time > NOW()`.
- Mobile передаёт `onlyOpen=true` в query, но backend игнорирует; фильтрация выполняется на клиенте.

### План реализации

1. **events.routes.ts:** Добавить `onlyOpen` в деструктуризацию query. Передавать в `repo.findAll({ onlyOpen: onlyOpen === 'true' || onlyOpen === '1' })`.

2. **events.repository.ts:** В `findAll(options)` добавить `onlyOpen?: boolean`. При `onlyOpen === true` заменить условие `status IN ('open', 'full')` на `status = 'open'`.

3. **Тесты:** Добавить в api.test.ts проверку: при `onlyOpen=true` в ответе только события со status `open`.

### Файлы

- `backend/src/api/events.routes.ts`
- `backend/src/db/repositories/events.repository.ts`
- `backend/src/api/events.routes.test.ts` (или api.test.ts)

---

## После реализации

1. Обновить docs/progress.md.
2. Обновить docs/changes/feedback-2026-02-14.md: отметить выполненные пункты.
3. Создать docs/changes/2026-02-14-profile-settings-move.md или добавить в существующий change-файл описание изменений.
