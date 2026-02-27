# AI Lessons Learned (Runterra)

Документ для предотвращения регрессий и повторения технических ошибок AI-ассистентом.

## Backend / Database
- **PostgreSQL Types:** Всегда проверять типы в миграциях. При сравнении `VARCHAR` и `UUID` в `JOIN` или `WHERE` ОБЯЗАТЕЛЬНО использовать явное приведение типов (например, `m.channel_id::uuid`).
- **Schema Truth:** Никогда не предполагать названия колонок (например, `photo_url` vs `avatar_url`). Всегда проверять файл `backend/src/db/migrations/001_initial.sql` или актуальные миграции.
- **SQL Errors (500):** Любая 500 ошибка при работе с БД в 90% случаев вызвана несоответствием типов или отсутствием колонки. При диагностике первым делом проверять SQL-запрос в репозитории.

## Mobile (Flutter)
- **Localization:** Перед использованием `AppLocalizations.of(context)!.key` ОБЯЗАТЕЛЬНО проверить наличие этого ключа в `mobile/l10n/app_ru.arb`.
- **Imports:** После добавления новых моделей или сервисов в Widget, всегда проверять наличие соответствующего `import`.
- **TabBar/TabController:** При создании вложенных вкладок всегда использовать `with SingleTickerProviderStateMixin` и явный `TabController` для избежания блокировки UI.

## Deployment / CI
- **PowerShell Flags:** Если `npm run script -- -Flag` не срабатывает, использовать прямой вызов скрипта: `.\scripts\script.ps1 -Flag` или переменные окружения `$env:DEPLOY_SKIP_CI="1"`.
- **Systemd:** Если после деплоя бэкенд не изменился, проверить необходимость `sudo systemctl daemon-reload`.
