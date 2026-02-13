# Runterra

## Local Secrets / Tokens (Repo-Local)

If you run deploy scripts from the project root and want to avoid relying on user-profile configs under `C:\Users\...`,
put local-only variables into `.env.local` (not committed).

- Template: `.env.local.example`
- Common variables:
  - `FIREBASE_TOKEN` for Firebase App Distribution (from `firebase login:ci`)
  - `GH_TOKEN` or `GITHUB_TOKEN` for `gh` CI checks (optional)
  - `DEPLOY_SKIP_CI=1` and/or `DEPLOY_SKIP_FIREBASE=1` (optional toggles)

Deploy scripts auto-load `.env.local` via `scripts/load-env.ps1`.

Платформа для локальных беговых сообществ.

Текущая стадия проекта — **подготовка основы (skeleton)**.
Продуктовая логика и геймификация будут добавляться позже.

---

## Текущая стадия

На данном этапе проект представляет собой:
- архитектурную основу приложения
- заготовку для мобильного клиента, backend и админки
- минимальную, чистую структуру без бизнес-логики

### ВАЖНО
На этом этапе:
- ❌ нет геймплея
- ❌ нет территорий
- ❌ нет тренировок
- ❌ нет клубов
- ❌ нет рейтингов и очков

Любая логика будет добавляться **поэтапно позже**.

---

## Цель текущего этапа

- Подготовить масштабируемую архитектуру
- Заложить правильную структуру проекта
- Избежать переработок при добавлении функциональности
- Получить стабильную базу для MVP

---

## Технологический стек (зафиксирован)

- **Мобильное приложение:** Flutter (Android-first)
- **Backend:** Node.js + TypeScript
- **База данных:** PostgreSQL
- **Карты:** Yandex MapKit
- **Авторизация:** Firebase Authentication
- **Админ-панель:** Next.js

---

## Принципы разработки

- Сначала архитектура — потом функциональность
- Минимум кода, максимум ясности
- Никаких «фич на будущее» без необходимости
- Любое решение должно быть объяснимо

---

## Документация

Полное продуктовое техническое задание находится отдельно  
и **не используется как инструкция для реализации на текущем этапе**.

См.:
