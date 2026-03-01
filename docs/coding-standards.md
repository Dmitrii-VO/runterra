# Стандарты кода (Coding Standards)

Документ описывает обязательные правила форматирования и линтинга для всех частей проекта Runterra.

---

## Backend (Node.js + TypeScript)

### Инструменты

| Инструмент | Версия | Назначение |
|---|---|---|
| ESLint | v10 (flat config) | Статический анализ |
| typescript-eslint | v8 | TypeScript-правила |
| Prettier | v3 | Форматирование |

Конфигурации: `backend/eslint.config.mjs`, `backend/.prettierrc`

### Стиль кода

- **Кавычки:** одинарные (`singleQuote: true`)
- **Точки с запятой:** обязательны (`semi: true`)
- **Отступ:** 2 пробела (`tabWidth: 2`)
- **Trailing commas:** везде, где допустимо (`trailingComma: "all"`)
- **Длина строки:** до 100 символов (`printWidth: 100`)
- **Arrow functions:** без скобок для одного аргумента (`arrowParens: "avoid"`)

### Правила ESLint

- `@typescript-eslint/no-explicit-any: warn` — нежелательно, но допустимо с комментарием
- `@typescript-eslint/no-unused-vars: error` — переменные с `_` в начале игнорируются
- `@typescript-eslint/explicit-function-return-type: off` — TypeScript выводит типы
- `@typescript-eslint/no-empty-object-type: off` — `{}` как Express route params допустимо
- `no-console: warn` — использовать `logger` вместо `console`

**Исключения:**
- Тестовые файлы (`*.test.ts`): разрешены `require()` и `any`
- `src/shared/logger.ts`, `src/db/migrate.ts`: разрешены `console.*`

### Команды

```bash
cd backend

# Проверка
npm run lint            # ESLint (0 ошибок, 0 предупреждений)
npm run format:check    # Prettier (только проверка)

# Исправление
npm run lint:fix        # Авто-исправление ESLint
npm run format          # Авто-форматирование Prettier
```

---

## Mobile (Flutter + Dart)

### Инструменты

| Инструмент | Назначение |
|---|---|
| flutter_lints | Базовый набор lint-правил |
| flutter analyze | Статический анализ |

Конфигурация: `mobile/analysis_options.yaml`

### Правила линтера

**Включены в `analysis_options.yaml`:**

| Правило | Назначение |
|---|---|
| `prefer_const_constructors` | Использовать `const` где возможно |
| `prefer_const_literals_to_create_immutables` | `const` для неизменяемых коллекций |
| `avoid_empty_else` | Запрет пустых `else`-блоков |
| `sized_box_for_whitespace` | `SizedBox` вместо пустого `Container` |
| `avoid_returning_null_for_void` | Не возвращать `null` из `void`-функций |
| `use_build_context_synchronously` | Безопасная работа с `BuildContext` после `await` |
| `avoid_unnecessary_containers` | Убирать лишние `Container`-обёртки |
| `prefer_const_declarations` | `const` для константных переменных |

**Подавлены:**

| Правило | Причина |
|---|---|
| `deprecated_member_use` | Совместимость с Yandex MapKit |

### Команды

```bash
cd mobile
flutter analyze --no-fatal-infos   # Анализ (должен вернуть «No issues found»)
flutter test                        # Тесты
```

---

## CI/CD

Линтинг запускается автоматически при каждом пуше в `main` и PR.

**Шаги для backend:**
1. `npm run lint` — ESLint (0 нарушений)
2. `npx tsc --noEmit` — TypeScript typecheck
3. `npm test` — тесты
4. `npm run build` — сборка

**Шаги для mobile:**
1. `flutter analyze --no-fatal-infos` — анализ кода
2. `flutter test` — тесты
3. `flutter build apk --debug` — сборка APK

---

## Общие принципы

- **Комментарии в коде:** английский язык
- **Документация:** русский язык
- Простой, читаемый, явный код — без преждевременных абстракций
- Не добавлять комментарии к самоочевидному коду
- Не использовать `any` в TypeScript без крайней необходимости; если необходимо — добавить `// eslint-disable-next-line @typescript-eslint/no-explicit-any` с пояснением
