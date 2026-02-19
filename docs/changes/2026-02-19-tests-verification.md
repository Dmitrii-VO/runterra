# Проверка и доработка тестов (2026-02-19)

## Результаты

### Backend
- **147 тестов** — все проходят (11 test suites)
- Jest: `forceExit: true` в конфиге, `jest.setup.ts` с `afterAll(closeDbPool)`
- Предупреждение «worker failed to exit gracefully» остаётся — связано с асинхронными операциями (возможно pg pool или Express). Не блокирует CI.

### Mobile
- **22 теста** — все проходят
- Модели: ClubModel, EventDetailsModel, EventListItemModel, MyClubModel, RunModel, TerritoryMapModel

## Изменения

1. **devLogClient.ts** — в тестовой среде (`NODE_ENV=test`) отключена отправка логов на dev-сервер. Исключает возможные утечки из-за fetch при прогоне тестов.

## Рекомендации

- При добавлении новых API-эндпоинтов — добавлять тесты в соответствующие `*.routes.test.ts`
- При изменении моделей mobile — обновлять `*_model_test.dart`
- Критичные модули (auth, events, clubs, runs, chat) уже покрыты тестами
