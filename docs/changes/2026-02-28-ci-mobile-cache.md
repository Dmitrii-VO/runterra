# CI: кэширование pub и Gradle для mobile build

**Дата:** 2026-02-28

## Описание

В GitHub Actions workflow для mobile-сборки добавлено кэширование зависимостей, чтобы ускорить повторные прогоны.

## Изменения

- **Pub cache:** кэш директории `~/.pub-cache` с ключом на основе `**/pubspec.lock` (mobile и wear).
- **Gradle:** кэш `~/.gradle/caches` и `~/.gradle/wrapper` с ключом на основе `**/gradle-wrapper.properties` и `**/*.gradle` (mobile и wear).

## Файлы

- `.github/workflows/ci.yml` — добавлены шаги `actions/cache` для Mobile job.
