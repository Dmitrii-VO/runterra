# Реализация рекомендаций brainstorm: вкладка Профиль MVP (2026-02-13)

Реализованы три доработки из docs/changes/2026-02-13-profile-brainstorm.md.

## 1. Видимость профиля

**Backend:**
- Миграция `017_users_profile_visible.sql`: колонка `profile_visible BOOLEAN NOT NULL DEFAULT true` в таблице `users`
- `GET /api/users/me/profile` возвращает `profileVisible` в объекте `user` (по умолчанию `true`)
- `PATCH /api/users/me/profile` принимает `profileVisible?: boolean` в теле запроса
- UsersRepository: поле `profile_visible` в UserRow, rowToUser, метод update

**Mobile:**
- ProfileUserData: поле `profileVisible` (default `true`), парсинг из JSON
- UsersService.updateProfile: параметр `profileVisible?: boolean`
- ProfileSettingsSection: callback `onProfileVisibilityChanged: (bool) => void`; Switch вызывает его при переключении
- ProfileScreen: передаёт `profile.user.profileVisible` и callback, вызывающий API + _retry() при успехе

## 2. Удаление аккаунта

**Backend:** без изменений — `DELETE /api/users/me` уже реализован.

**Mobile:**
- UsersService.deleteAccount(): вызов `DELETE /api/users/me` через ApiClient
- ProfileScreen: onDeleteAccount показывает диалог подтверждения (deleteAccountTitle, deleteAccountConfirm, deleteAccountConfirmButton)
- При подтверждении: deleteAccount() → signOut → updateAuthToken(null) → authRefreshNotifier.refresh() → context.go('/login')
- Ошибки API отображаются через SnackBar

**i18n:** добавлены ключи в app_en.arb и app_ru.arb:
- deleteAccountTitle
- deleteAccountConfirm
- deleteAccountConfirmButton

## 3. Геолокация — открытие настроек по тапу

**Mobile:**
- ProfileSettingsSection: ListTile геолокации получил `onTap: () => Geolocator.openAppSettings()`
- При тапе открываются настройки приложения (раздел разрешений)

## Не изменялось

- PersonalInfo, Activity — оставлены без изменений (рекомендация brainstorm)
- Уровень (новичок/любитель/опытный) — отложен
- Видимость статистики для других — отложена (нет публичного просмотра профиля)
