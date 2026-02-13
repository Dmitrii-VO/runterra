# Реализация аудита модуля «Клубы» (2026-02-14)

Выполнены рекомендации из docs/tasks/gemini-clubs-audit-report.md.

## 1. Data Integrity (P0)

### territories.config.ts

- Удалены legacy-строки `club-1` и `club-2` из конфига территорий.
- Все территории имеют `clubId: undefined` (свободные).
- Статусы «Приморский парк» и «Парк 300» переведены в `FREE` (без владельца статусы CAPTURED/CONTESTED не имеют смысла).

### Тесты

- Обновлены тесты `api.test.ts`: `onlyActive` и `clubId` фильтры корректно работают при пустых/свободных территориях.

## 2. Бизнес-логика Backend (P1)

### Создание клуба — всегда PENDING

- `POST /api/clubs` теперь всегда создаёт клуб со статусом `PENDING`.
- Поле `status` удалено из `CreateClubSchema` (игнорируется при создании).

### Авто-активация при approveMembership

- После `approveMembership` вызывается `countActiveMembers`.
- Если `count >= 2`, клуб переводится в `ACTIVE` через `clubsRepo.update`.

### Передача лидерства

- Добавлен метод `updateRoleWithLeaderTransfer` в `ClubMembersRepository`.
- При назначении нового лидера (`role === 'leader'`) текущий лидер автоматически понижается до `trainer`.
- Используется транзакция для атомарности.

### Проверка club.status при захвате

- ADR-0007: зафиксировано правило — захват территорий только для клубов в статусе `active` (при реализации логики захвата).

## 3. Метрики MVP

- `GET /api/clubs/:id` возвращает:
  - `territoriesCount` — количество территорий клуба из `getTerritoriesForCity(cityId, clubId)`.
  - `cityRank` — `membersCount * 1 + territoriesCount * 10`.

При текущем конфиге (все территории свободны) `territoriesCount` всегда 0.

## 4. UX-подсказка (Mobile)

- На ClubDetailsScreen при `club.status == 'pending'` и `club.isMember == true` отображается баннер:
  - «Наберите ещё 1 участника, чтобы активировать клуб и участвовать в захвате территорий» (l10n: `clubActivationHint`).

## 5. Меркатели

- Требование зафиксировано в docs/changes/mercenaries-requirement.md.
- Код не изменяется до реализации логики захвата.

## Связанные документы

- docs/tasks/gemini-clubs-audit-report.md
- docs/adr/0007-territory-capture-active-club-only.md
- docs/changes/mercenaries-requirement.md
