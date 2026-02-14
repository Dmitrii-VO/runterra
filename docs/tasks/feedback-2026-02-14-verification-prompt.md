# Промпт: Перепроверка изменений Feedback 2026-02-14

Используй этот промпт для верификации реализации задач из docs/changes/feedback-2026-02-14.md.

**Контекст:** Реализация выполнена (docs/changes/2026-02-14-profile-settings-and-onlyopen.md). Требуется перепроверка кода и ручное тестирование.

---

## Задача

1. Проверить код — соответствие реализации требованиям.
2. Проверить отсутствие регрессий.
3. Выполнить ручную проверку сценариев (если возможно).
4. Зафиксировать результат в docs/changes/feedback-2026-02-14.md (пункт «Выполнить ручную проверку фильтров событий»).

---

## 1. Профиль — перенос настроек

### Проверка кода

| Проверка | Файл | Ожидание |
|---------|------|----------|
| ProfileSettingsSection отсутствует | profile_screen.dart | Нет импорта и использования `ProfileSettingsSection` |
| Нет state геолокации/видимости | profile_screen.dart | Нет `_locationPermissionGranted`, `_profileVisibleOverride`, `_savingProfileVisible` |
| Переход передаёт ProfileModel | profile_screen.dart | `context.push('/profile/edit', extra: profile)` — `profile` типа ProfileModel |
| EditProfileScreen принимает profile | edit_profile_screen.dart | `EditProfileScreen({required this.profile})`, `ProfileModel profile` |
| Блок настроек присутствует | edit_profile_screen.dart | Card с 4 ListTile: Геолокация, Видимость (Switch), Выйти, Удалить |
| Геолокация | edit_profile_screen.dart | `Geolocator.openAppSettings()` по тапу, `_checkLocationPermission()` в initState |
| Видимость | edit_profile_screen.dart | Switch + `UsersService.updateProfile(profileVisible:)`, обработка ApiException |
| Выход | edit_profile_screen.dart | Диалог (logoutTitle, logoutConfirm) → AuthService.signOut → authRefreshNotifier.refresh → context.go('/login') |
| Удаление | edit_profile_screen.dart | Диалог (deleteAccountTitle, deleteAccountConfirm) → UsersService.deleteAccount → signOut → go('/login') |
| Route /profile/edit | app.dart | `state.extra as ProfileModel`, `EditProfileScreen(profile: profile)` |
| settings_section.dart удалён | — | Файл не существует |

### Ручная проверка (если приложение запускается)

- [ ] Профиль: на главном экране профиля **нет** блока «Геолокация / Видимость / Выйти / Удалить».
- [ ] Профиль → кнопка «Редактировать»: открывается экран «Редактирование профиля» с формой и блоком настроек.
- [ ] Геолокация: тап открывает настройки приложения.
- [ ] Видимость: переключение Switch сохраняет значение (без ошибок).
- [ ] Выйти: диалог подтверждения → выход → переход на экран входа.
- [ ] Удалить: диалог подтверждения → (осторожно!) удаление аккаунта.

---

## 2. Backend — onlyOpen

### Проверка кода

| Проверка | Файл | Ожидание |
|---------|------|----------|
| onlyOpen в query | events.routes.ts | `const { ..., onlyOpen, ... } = query` |
| onlyOpen передаётся в repo | events.routes.ts | `onlyOpen: onlyOpen === 'true' \|\| onlyOpen === '1'` в `repo.findAll()` |
| onlyOpen в options | events.repository.ts | `onlyOpen?: boolean` в `findAll(options?)` |
| Условие при onlyOpen | events.repository.ts | `if (options?.onlyOpen) { conditions.push(\`status = 'open'\`); } else { ... status IN ('open', 'full') ... }` |

### Проверка API (curl или тест)

- [ ] `GET /api/events?cityId=spb` — возвращает события со status `open` и `full`.
- [ ] `GET /api/events?cityId=spb&onlyOpen=true` — возвращает только события со status `open`.

### Ручная проверка (если приложение запускается)

- [ ] Вкладка События: фильтр «Только открытые» включён по умолчанию — в списке только открытые события (без полных).
- [ ] Выключить «Только открытые» — появляются полные события.
- [ ] Фильтры «Сегодня» / «Завтра» / «7 дней» — список обновляется при переключении.

---

## 3. Автоматические проверки

```bash
cd backend && npm test
cd mobile && flutter analyze && flutter test
```

Ожидание: все тесты проходят, 0 issues.

---

## 4. Результат

После проверки:

1. Обновить docs/changes/feedback-2026-02-14.md: отметить `[x]` для «Выполнить ручную проверку фильтров событий», если проверка выполнена.
2. При обнаружении регрессий — описать в docs/changes/feedback-2026-02-14.md или создать issue.
3. Кратко зафиксировать в docs/progress.md: «Перепроверка Feedback 2026-02-14 — пройдена» или «обнаружены проблемы: …».
