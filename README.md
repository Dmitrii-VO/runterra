# Runterra

Платформа для локальных беговых сообществ с геймификацией захвата территорий.

Текущее состояние: **MVP в активной разработке** (часть механик территорий пока на mock-данных; см. “Статус территорий” ниже).

---

## Что уже реализовано (в общих чертах)

- Авторизация: Firebase Authentication
- Карта: Yandex MapKit, полигоны территорий, события на карте
- События: список/детали/создание, участие (join/leave), GPS check-in, Swipe-to-run
- Пробежки: GPS-трекинг, сохранение `runs` + `run_gps_points`, история и детали пробежки
- Клубы: создание/редактирование, членство (в т.ч. заявки), роли `member/trainer/leader`, клубные чаты (каналы)
- Тренер: профиль тренера + библиотека тренировок (workouts), привязка к событиям
- i18n (RU/EN), multi-city (базовая поддержка)

## Статус территорий (важно)

Сейчас территории визуализируются из статического конфига (геометрия полигонов), а лидерборды/захват в значительной части **mock**. Переход на реальный захват по GPS-треку описан в:

- `docs/territory-capture-real-gps-implementation-spec.md`

---

## Стек (зафиксирован)

- **Mobile:** Flutter (Android-first), Yandex MapKit, GoRouter, Firebase Auth
- **Backend:** Node.js + TypeScript, Express, PostgreSQL (pg), WebSocket (ws), Zod, Firebase Admin SDK
- **Admin:** Next.js 14 (минимально, не основной фокус)

---

## Структура репозитория

- `backend/` — API + PostgreSQL migrations + WebSocket
- `mobile/` — Flutter приложение
- `admin/` — Next.js админка
- `docs/` — документация и история изменений
- `scripts/` — деплой/утилиты/AI-скрипты

---

## Быстрый старт (локально)

Backend:

```bash
cd backend
npm install
npm run migrate
npm run dev
```

Mobile:

```bash
cd mobile
flutter pub get
flutter run
```

Подробнее и про окружение:

- `docs/firebase-setup.md`
- `docs/build-and-share.md`

---

## Local Secrets / Tokens (Repo-Local)

If you run deploy scripts from the project root and want to avoid relying on user-profile configs under `C:\Users\...`,
put local-only variables into `.env.local` (not committed).

- Template: `.env.local.example`
- Common variables:
  - `FIREBASE_TOKEN` for Firebase App Distribution (from `firebase login:ci`)
  - `GH_TOKEN` or `GITHUB_TOKEN` for `gh` CI checks (optional)
  - `DEPLOY_SKIP_CI=1` and/or `DEPLOY_SKIP_FIREBASE=1` (optional toggles)

Deploy scripts auto-load `.env.local` via `scripts/load-env.ps1`.

---

## Документация (source of truth)

- `docs/progress.md` — хронология разработки
- `docs/changes/` — изменения по модулям (runs/clubs/events/territories/etc.)
- `docs/features/README.md` — функционал вкладок мобильного приложения
- `docs/product_spec.md` — продуктовая спецификация (длинный документ)
- `docs/adr/` — архитектурные решения (ADR)
