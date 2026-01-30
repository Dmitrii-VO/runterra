# Mobile: GoRouter и реакция на auth

**Дата:** 2026-01-29

## Проблема

В `app.dart` GoRouter объявлен как `static final` без привязки к состоянию авторизации. Маршрутизатор не мог реагировать на смену auth (например redirect после логина/логаута).

## Решение

- Введён **AuthRefreshNotifier** (extends `ChangeNotifier`) с методом `refresh()`.
- Экземпляр **authRefreshNotifier** передан в GoRouter как **refreshListenable**.
- При вызове `authRefreshNotifier.refresh()` GoRouter обновляется (пересчёт redirect и т.п.).

На этапе skeleton реальная подписка на Firebase Auth не добавлена; при интеграции авторизации достаточно вызывать `authRefreshNotifier.refresh()` при смене состояния (логин/логаут), чтобы маршрутизатор отреагировал.
