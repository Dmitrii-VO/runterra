# ADR-0004: Mobile — простой ServiceLocator для ApiClient и сервисов

## Контекст

В мобильном приложении Runterra ApiClient уже был синглтоном (`getInstance(baseUrl:)`), но около 10 экранов при каждом вызове fetch повторяли цепочку: получить baseUrl → вызвать getInstance → создать новый экземпляр XxxService. Сервисы не переиспользовались, единой точки инициализации не было; при добавлении новых экранов дублировался один и тот же шаблон.

Требовалось: создавать ApiClient один раз на старте приложения и переиспользовать сервисы (DI / единая точка доступа).

## Решение

Введён **простой статический ServiceLocator** без внешних зависимостей (Riverpod, get_it и т.п.):

1. **Файл:** `mobile/lib/shared/di/service_locator.dart`. Класс с приватным конструктором, статическими полями для ApiClient и всех API-сервисов, методом `init()` и геттерами.

2. **Инициализация:** в `main()` после `Firebase.initializeApp()` вызывается `ServiceLocator.init()`. Внутри: один вызов `ApiClient.getInstance(baseUrl: ApiConfig.getBaseUrl())`, создание одного экземпляра каждого сервиса (ActivitiesService, CitiesService, ClubsService, EventsService, MapService, MessagesService, RunService, TerritoriesService, UsersService) и одного LocationService; RunService получает общий ApiClient и общий LocationService.

3. **Использование:** экраны и вкладки получают сервисы через `ServiceLocator.eventsService`, `ServiceLocator.mapService` и т.д. Импорты ApiConfig и ApiClient в feature-экранах убраны (кроме случаев, когда нужен тип, например ApiException из users_service).

## Альтернативы

- **Riverpod / Provider:** добавили бы зависимость и потребовали бы оборачивания приложения в провайдеры; на skeleton-этапе избыточно.
- **get_it:** популярный пакет для DI; решение без зависимостей достаточно для одного ApiClient и набора сервисов, создаваемых один раз.

## Последствия

- Один ApiClient и один набор сервисов на всё приложение; переиспользование соединений и отсутствие дублирования инициализации.
- Добавление нового сервиса: зарегистрировать в ServiceLocator.init() и добавить геттер; экраны обращаются через ServiceLocator.
- Для тестов: можно вызывать `ApiClient.getInstance(...)` с тестовым baseUrl до runApp или использовать инъекцию через конструкторы сервисов (как сейчас в run_service); при необходимости можно добавить в ServiceLocator метод `reset()` для сброса синглтонов (по аналогии с ApiClient.dispose()).
