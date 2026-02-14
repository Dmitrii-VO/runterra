# Feedback 2026-02-14 — Реализация

Дата: 2026-02-14

## Обзор

Реализованы задачи из docs/changes/feedback-2026-02-14.md: (1) перенос настроек профиля в «Редактирование профиля»; (2) поддержка `onlyOpen` на backend для GET /api/events.

---

## 1. Профиль — перенос настроек в «Редактирование профиля»

### Изменения

**ProfileScreen:**
- Удалена `ProfileSettingsSection` (геолокация, видимость, выход, удаление).
- Удалены state `_locationPermissionGranted`, `_profileVisibleOverride`, `_savingProfileVisible` и метод `_checkLocationPermission()`.
- Переход на редактирование: передаётся `ProfileModel` вместо `ProfileUserData` (`extra: profile`).

**EditProfileScreen:**
- Конструктор принимает `ProfileModel profile` вместо `ProfileUserData user`.
- Добавлен блок настроек после формы: Геолокация, Видимость профиля, Выйти из аккаунта, Удалить аккаунт.
- Логика геолокации: `LocationService.checkPermission()` в initState.
- Логика видимости: Switch, `UsersService.updateProfile(profileVisible:)`, обработка ошибок.
- Логика выхода/удаления: диалоги подтверждения, `AuthService.signOut()`, `context.go('/login')`.

**app.dart:**
- Route `/profile/edit`: `state.extra` — `ProfileModel`, `EditProfileScreen(profile: profile)`.

**Удалено:**
- `mobile/lib/shared/ui/profile/settings_section.dart` — логика перенесена в EditProfileScreen.

### Файлы

- `mobile/lib/features/profile/profile_screen.dart`
- `mobile/lib/features/profile/edit_profile_screen.dart`
- `mobile/lib/app.dart`
- `mobile/lib/shared/ui/profile/settings_section.dart` (удалён)

---

## 2. Backend — поддержка onlyOpen в GET /api/events

### Изменения

**events.routes.ts:**
- Добавлен query-параметр `onlyOpen` в деструктуризацию.
- Передача `onlyOpen: onlyOpen === 'true' || onlyOpen === '1'` в `repo.findAll()`.

**events.repository.ts:**
- Добавлен параметр `onlyOpen?: boolean` в `findAll()`.
- При `onlyOpen === true`: условие `status = 'open'` вместо `status IN ('open', 'full')`.

### Файлы

- `backend/src/api/events.routes.ts`
- `backend/src/db/repositories/events.repository.ts`

---

## Проверки

- Backend: `npx jest --runInBand` — 98 passed (в среде агента `npm test` падал с `spawn EPERM`)
- Mobile: `flutter analyze` — 0 issues
- Mobile: `flutter test` — 21 passed
