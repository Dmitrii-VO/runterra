# Переработка профиля: фото, username, клубы

**Дата:** 2026-03-10

## Цель

Полный редизайн раздела «Профиль»:
- Загрузка фото через Firebase Storage + image_picker
- Опциональный username (@ник) с уникальностью
- Переработка EditProfileScreen, ProfileScreen, MyClubsScreen

---

## Backend

### Миграция `041_users_username.sql`
- Колонка `users.username VARCHAR(30)` — опциональная, nullable
- Partial unique index: `CREATE UNIQUE INDEX ... WHERE username IS NOT NULL`
- Допускает множество NULL (пользователи без ника), но запрещает дубли среди заполненных

### `users.repository.ts`
- `username` добавлен в `UserRow`, `rowToUser()`, `update()` (тип `string | null`)
- `lastName` и `country` в `update()`: тип изменён на `string | null`

### `users.routes.ts`
- `GET /me/profile` — возвращает `user.username`
- `PATCH /me/profile`:
  - `username: string | null` — валидация Zod `/^[a-z0-9_]{3,30}$/`, nullable
  - `lastName: string | null`, `country: string | null` — nullable для очистки поля
  - 409 `username_taken` при нарушении unique constraint (`23505`)

### `user.dto.ts`
- `UpdateProfileSchema`: `lastName` и `country` — `.nullable().optional()`
- `UpdateProfileDto`: `lastName?: string | null`, `country?: string | null`

---

## Mobile

### Новые зависимости (`pubspec.yaml`)
- `firebase_storage: ^12.0.0`
- `image_picker: ^1.1.2`

### `ProfileUserData` (`profile_model.dart`)
- Поле `username?: String?`

### `UsersService` (`users_service.dart`)
- `updateProfile()`:
  - Параметры `username: String?` и `clearUsername: bool`
  - `lastName` / `country`: маппинг empty string → null (очистка поля)
  - Обработка 409 → бросает `ApiException('username_taken', ...)`
- `uploadAvatar(filePath)`:
  - Загружает в Firebase Storage `users/{uid}/avatar.jpg`
  - Возвращает download URL с `&t={timestamp}` для cache-busting

### `EditProfileScreen` (полный переписыв)
- **Фото:** CircleAvatar сверху. Нажатие → `image_picker` (gallery). Локальный `FileImage` preview. Upload происходит в `_save()` — отмена не затрагивает Storage.
- **Поля:** Имя, Фамилия, Ник (`@` prefix, regex валидация, 409 conflict), Страна, Дата рождения, Пол (только `male`/`female`), Город
- **Gender:** опции `other`/`unknown` удалены — backend принимает только `male`/`female`
- **Очистка полей:** `lastName`/`country` всегда передаются в запрос (empty → null на сервере)
- **mounted guards:** добавлены после `showDatePicker` и city picker callbacks

### `ProfileScreen`
- `_ProfileHeroHeader`: показывает `@username` под именем (если установлен)
- `ProfilePersonalInfoSection` удалён из SliverList (дублировал данные из формы)
- Card «Мой клуб» → навигация в `/profile/clubs` (вместо конкретного клуба)

### `MyClubsScreen` (переработан)
- **Секция А** — «Мои клубы»: клубы где роль `member` / `leader`
- **Секция Б** — «Найти клуб»: кнопка → `/clubs?cityId=...`
- **Секция В** — «Клубы, где я тренер»: только если есть клубы с `role == 'trainer'`

### L10n (9 новых ключей)
| Ключ | RU | EN |
|------|----|----|
| `editProfileUsername` | Ник (username) | Username |
| `editProfileUsernameHint` | латиница, цифры, _ • 3–30 символов | lowercase letters, digits, underscore • 3–30 chars |
| `editProfileUsernameConflict` | Этот ник уже занят | This username is already taken |
| `editProfilePhotoChange` | Изменить фото | Change photo |
| `editProfilePhotoSelected` | Фото выбрано | Photo selected |
| `editProfilePhotoUploading` | Загрузка фото... | Uploading photo... |
| `myClubsMySection` | Мои клубы | My clubs |
| `myClubsFind` | Найти клуб | Find a club |
| `myClubsAsTrainer` | Клубы, где я тренер | Clubs where I'm a trainer |

### Удалено
- `personal_info_section.dart` — мёртвый код, нигде не использовался

---

## Adversarial review (Codex, 3 рецензента)

Проведён после основной реализации. Закрыто 6 из 8 findings:

| # | Серьёзность | Исправлено |
|---|------------|-----------|
| F1 | high | Upload перенесён в `_save()`, preview через `FileImage` |
| F2 | high | Удалены `other`/`unknown` из gender dropdown |
| F3 | medium | `mounted` guards в date picker и city picker |
| F4 | medium | Очистка `lastName`/`country`: Zod nullable + empty→null mapping |
| F5 | medium | Cache-busting `&t=timestamp` в `uploadAvatar()` |
| F8 | low | Удалён `personal_info_section.dart` |

Отклонено (F6, F7): смешение HTTP/Storage в UsersService и двухпараметрный API username — не блокируют MVP.

---

## Тесты

- `npm test`: 173/173 ✅
- `flutter analyze`: 0 issues ✅
