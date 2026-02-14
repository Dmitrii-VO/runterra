# Deploy Mobile: Firebase App Distribution release notes (2026-02-14)

Дата: 2026-02-14

## Контекст

В `firebase appdistribution:distribute` возможна ситуация: APK успешно загружен и релиз создан, но шаг обновления release notes падает (CLI возвращает non-zero).

## Изменение

Обновлён скрипт `scripts/deploy-mobile.ps1`:

- Добавлено нормализующее ограничение длины release notes (консервативный cap `4000` символов, с пометкой `- ... (truncated)`), чтобы снизить вероятность отказа App Distribution API.
- Если Firebase CLI завершился с ошибкой, но по выводу видно, что релиз **успешно загружен**, а упал именно шаг release notes, скрипт не валит деплой целиком и выводит предупреждение (release notes можно поправить вручную в Firebase Console).

## Риски/ограничения

- Release notes могут быть усечены.
- Если upload неуспешен, скрипт по-прежнему завершает работу с ошибкой.

