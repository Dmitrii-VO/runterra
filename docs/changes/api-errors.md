# Изменения: Формат ошибок API и валидация

## История изменений

### 2026-01-29

- **Единый формат ошибок API:** Для всех ошибочных ответов backend-API введён общий конверт `{ code: string; message: string; details?: any }`, где `code` — стабильный технический код ошибки (например: `validation_error`, `unauthorized`), `message` — краткое англоязычное сообщение, `details` — структура, зависящая от типа ошибки.
- **Стандартизация ошибок валидации (Zod):** Ошибки runtime-валидации тел запросов теперь возвращаются как `400 Bad Request` с телом `{ code: "validation_error"; message: "Request body validation failed"; details: { fields: { field: string; message: string; code: string }[] } }`. Формат `details.fields` основан на маппинге `ZodIssue` (dot-path, англоязычное сообщение, технический код).
- **Ответы авторизации (`authMiddleware`):** Ошибки авторизации для всех `/api` эндпоинтов теперь возвращаются в формате `{ code: "unauthorized"; message: "Authorization required"; details: { reason: "missing_header" | "invalid_format" | "invalid_token" | "unexpected_error" } }` с HTTP статусом `401`. Поведение доменных заглушек и контрактов бизнес-уровня не изменено.

