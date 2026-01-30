# Admin panel

Административная панель Runterra.

Текущая стадия:
- архитектурный скелет
- Next.js с App Router и TypeScript
- без UI
- модуль авторизации (только типы и контракты, без реализации)
- без бизнес-логики
- без подключения к backend

## Структура проекта

```
src/
  app/              # Next.js App Router (layout, pages)
  modules/
    auth/           # Модуль авторизации администраторов
      admin.roles.ts           # Роли администраторов (enum)
      admin-user.type.ts       # Типы данных администратора
      admin-auth.provider.ts   # Контракт провайдера авторизации
      index.ts                 # Экспорты модуля
```

## Модуль авторизации

Модуль `src/modules/auth` содержит определения типов и контрактов для авторизации администраторов:

- **Роли**: `AdminRole` (SUPER_ADMIN, ADMIN, MODERATOR, VIEWER)
- **Типы**: `AdminUser`, `AdminLoginCredentials`
- **Контракт**: `AdminAuthProvider` (интерфейс для реализации провайдера авторизации)

Реализация авторизации будет добавлена на следующих этапах.

## Запуск

```bash
npm install
npm run dev
```

Проект доступен на `http://localhost:3000`.
