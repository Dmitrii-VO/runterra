# Политика ошибок API и валидации (backend)

## 1. Базовый формат ошибок API

Все ошибочные ответы backend-API должны использовать единый конверт:

- `code: string` — стабильный машинный код ошибки (например: `validation_error`, `unauthorized`, `not_found`, `internal_error`).
- `message: string` — краткое техническое сообщение на английском языке (для логов и отладки; UI может его не показывать напрямую).
- `details?: any` — объект с дополнительной структурой, зависящей от типа ошибки (например, список полей при валидации).

HTTP статус остаётся основным носителем семантики (`400/401/403/404/500` и т.д.), а `code` описывает тип ошибки на уровне API-слоя (НЕ бизнес-домен).

## 2. Ошибки валидации (Zod)

Для ошибок валидации тела запроса (runtime-валидация через Zod) применяется стандартный формат:

- HTTP статус: `400 Bad Request`.
- Тело ответа:

```json
{
  "code": "validation_error",
  "message": "Request body validation failed",
  "details": {
    "fields": [
      {
        "field": "cityId",
        "message": "Required",
        "code": "invalid_type"
      }
    ]
  }
}
```

### 2.1 Формат `details.fields`

Массив `details.fields` имеет элементы вида:

- `field: string` — dot-path до поля в запросе (например: `"email"`, `"user.cityId"`, `"coordinates.longitude"`).
- `message: string` — базовое техническое сообщение на английском языке из Zod (или кастомизированное), без русской локализации.
- `code: string` — технический код ошибки поля, основанный на `issue.code` из Zod (например: `invalid_type`, `too_small`, `too_big`, `invalid_enum_value`).

Клиенты (mobile, admin) должны использовать:

- `code` и `field` как ключи для локализации и выбора сообщения.
- `message` — как fallback для отладки и логов.

### 2.2 Маппинг Zod-ошибок

Backend маппит `ZodIssue` в `details.fields` по правилу:

- `field` = `issue.path.join('.')`.
- `message` = `issue.message`.
- `code` = `issue.code`.

## 3. Ошибки авторизации

Для ошибок авторизации (middleware `authMiddleware`) используется формат:

- HTTP статус: `401 Unauthorized`.
- Тело ответа:

```json
{
  "code": "unauthorized",
  "message": "Authorization required",
  "details": {
    "reason": "missing_header" | "invalid_format" | "invalid_token" | "unexpected_error"
  }
}
```

Локализация сообщений и отображение пользователю происходят на стороне клиента, используя `code` и `details.reason` как ключи.

## 4. Политика runtime-валидации

На skeleton-этапе runtime-валидация на backend ограничивается ТОЛЬКО техническими проверками формы и типов:

- Валидация тела (`req.body`) через Zod-схемы (`Create*Schema`) для DTO.
- Без доменных инвариантов и бизнес-правил (связи сущностей, статусы, условия захвата территорий и т.п.) — они будут добавлены позже отдельными задачами.

Правила:

- Все новые DTO для входящих данных должны сопровождаться Zod-схемой рядом с типами (`Create*Dto` + `Create*Schema`).
- Валидация тела:
  - При неуспехе → HTTP `400` + `code: "validation_error"` + `details.fields`.
- Ошибки авторизации:
  - При отсутствии/неверном формате заголовка/невалидном токене → HTTP `401` + `code: "unauthorized"` + `details.reason`.

## 5. Локализация

- Backend возвращает только технические коды и английские сообщения.
- Пользовательские (русскоязычные) тексты ошибок формируются на клиентах (mobile, admin) на основе:
  - `http status`,
  - `code` верхнего уровня,
  - `details` (например, `fields` или `reason`).

## 6. Примеры

### 6.1 Ошибка валидации нескольких полей

```json
{
  "code": "validation_error",
  "message": "Request body validation failed",
  "details": {
    "fields": [
      {
        "field": "email",
        "message": "Invalid email",
        "code": "invalid_string"
      },
      {
        "field": "coordinates.longitude",
        "message": "Expected number, received string",
        "code": "invalid_type"
      }
    ]
  }
}
```

### 6.2 Ошибка авторизации (нет заголовка)

```json
{
  "code": "unauthorized",
  "message": "Authorization required",
  "details": {
    "reason": "missing_header"
  }
}
```

### 6.3 Ошибка авторизации (неверный формат заголовка)

```json
{
  "code": "unauthorized",
  "message": "Authorization required",
  "details": {
    "reason": "invalid_format"
  }
}
```

