# Вкладка «Профиль»

Функционал вкладки «Профиль» мобильного приложения Runterra.

## Назначение

Личный кабинет пользователя: просмотр и редактирование данных, настройки, управление клубами, выход и удаление аккаунта. Точка входа после авторизации (первый экран по умолчанию).

## ProfileScreen — основной экран

### Шапка (ProfileHeaderSection)

- Аватар (из `avatarUrl` или placeholder)
- ФИО (имя из профиля)
- Город (название из конфига или cityId)

**Примечание:** блоки клуба/роли/меркателя убраны (упрощение 2026-02-09).

### Секции

#### Личные данные (ProfilePersonalInfoSection)

Сворачиваемая секция (по умолчанию свёрнута). По тапу на заголовок — expand/collapse.

**Поля:**
- Имя, фамилия
- Дата рождения
- Страна
- Пол (мужской/женский)

#### Город

- Отображение текущего города (cityName или cityId)
- Тап → `CityPickerDialog` (список городов из GET /api/cities)
- После выбора — `UsersService.updateProfile(currentCityId)` и `CurrentClubService.setCurrentCityId`

#### Клубы

- Кнопка «Клубы» → `MyClubsScreen` (`/profile/clubs`)
- Список клубов пользователя с переходом в детали

### Кнопки в AppBar

- **Редактировать** → `EditProfileScreen` (`/profile/edit`)

---

## EditProfileScreen — редактирование профиля

**Поля:**
- Имя (обязательное)
- URL фото (avatarUrl)
- Город (если редактируется отдельно)

**Настройки (перенесены из ProfileScreen, feedback 2026-02-14):**
- **Геолокация** — ListTile, тап открывает настройки приложения через `Geolocator.openAppSettings()`
- **Видимость профиля** — Switch, `profileVisible` (GET/PATCH /api/users/me/profile)
- **Выйти из аккаунта** — signOut, переход на /login
- **Удалить аккаунт** — диалог подтверждения, DELETE /api/users/me, после успеха — signOut и /login

---

## MyClubsScreen — мои клубы

- Список клубов пользователя (GET /api/clubs/my)
- Карточки: название, город, статус, роль
- Тап → `ClubDetailsScreen` (`/club/:id`)
- Состояния: loading, empty, error + retry

---

## API

| Метод | Назначение |
|-------|------------|
| GET /api/users/me/profile | Профиль (user, club, primaryClubId, cityName, profileVisible) |
| PATCH /api/users/me/profile | Обновление (currentCityId, name, avatarUrl, profileVisible) |
| DELETE /api/users/me | Удаление аккаунта |
| GET /api/clubs/my | Список клубов пользователя |
| GET /api/cities | Список городов (для выбора) |

---

## Навигация

- `/` — профиль (корневой маршрут, точка входа после логина)
- `/profile/edit` — редактирование
- `/profile/clubs` — мои клубы

---

## Связанные файлы

- `mobile/lib/features/profile/profile_screen.dart`
- `mobile/lib/features/profile/edit_profile_screen.dart`
- `mobile/lib/features/profile/my_clubs_screen.dart`
- `mobile/lib/shared/ui/profile/personal_info_section.dart`
- `mobile/lib/shared/ui/profile/profile_header_section.dart`
- `mobile/lib/shared/api/users_service.dart`
- `backend/src/api/users.routes.ts`
