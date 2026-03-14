# Domain + HTTPS migration

Этот переход нужен, чтобы закрыть оставшийся критичный security finding: release mobile сейчас ходит на backend по cleartext HTTP/WS через IP.

## Что покупать

Покупать нужно домен. Отдельный платный SSL-сертификат не нужен:

- домен у любого регистратора;
- TLS-сертификат можно получить бесплатно через Let's Encrypt;
- для beta достаточно одного hostname: `api.runterra.ru`.

Если нужен сайт или админка позже, можно заранее взять:

- `api.runterra.ru` - backend/mobile API;
- `admin.<your-domain>` - будущая web/admin поверхность;
- `www.<your-domain>` или корень домена - лендинг, не обязателен.

## Почему домен обязателен

- нормальный публичный TLS выпускается на hostname, а не на голый IP;
- Android/iOS/web проще и надежнее работают с `https://api.runterra.ru` и `wss://api.runterra.ru`;
- после этого можно убрать Android cleartext exception и перестать гонять auth/GPS/profile по HTTP.

## DNS

После покупки домена создать запись:

- `A` record: `api.runterra.ru` -> `85.208.85.13`

Если используете Cloudflare DNS, режим лучше оставить `DNS only` на первом запуске, пока не проверен origin.

## Сервер

Нужно открыть входящие порты:

- `80/tcp`
- `443/tcp`

Backend уже слушает `localhost` в production, что подходит для reverse proxy:

- [server.ts](/D:/myprojects/Runterra/backend/src/server.ts#L24)

## Рекомендуемый вариант: Caddy

Для этого репозитория самый простой путь - `Caddy`, потому что он сам поднимет Let's Encrypt и будет продлевать сертификаты.

Пример конфига:

- [Caddyfile.example](/D:/myprojects/Runterra/infra/Caddyfile.example)

В проекте используется hostname `api.runterra.ru`.

## Порядок миграции

1. Купить домен.
2. Создать `A` запись `api.runterra.ru` -> `85.208.85.13`.
3. Установить `caddy` на сервере.
4. Положить рабочий `Caddyfile` с reverse proxy на `127.0.0.1:3000`.
5. Перезапустить `caddy` и проверить `https://api.runterra.ru/health`.
6. Пересобрать mobile с `--dart-define=API_BASE_URL=https://api.runterra.ru`.
7. Удалить Android cleartext exception:
   - [network_security_config.xml](/D:/myprojects/Runterra/mobile/android/app/src/main/res/xml/network_security_config.xml#L3)
8. Проверить, что WebSocket автоматически уйдет на `wss://`, потому что схема выводится из `API_BASE_URL`:
   - [chat_websocket_service.dart](/D:/myprojects/Runterra/mobile/lib/shared/services/chat_websocket_service.dart#L47)
9. После стабилизации можно дополнительно закрыть backend firewall так, чтобы снаружи были доступны только `80/443`.

## Что меняется в приложении

Сейчас release URL захардкожен как HTTP по IP:

- [api_config.dart](/D:/myprojects/Runterra/mobile/lib/shared/config/api_config.dart#L38)

После появления домена release должен ходить на:

- `https://api.runterra.ru` для REST;
- `wss://api.runterra.ru/ws` для WebSocket.

## Минимальная проверка

Проверить после переключения:

1. `GET /health`
2. `GET /api/version`
3. login в приложении
4. открытие профиля
5. открытие клубного чата
6. отправка одного сообщения через WS

## Следующий кодовый шаг после домена

После того как hostname будет известен, нужно сделать маленький финальный кодовый проход:

- заменить release default base URL;
- убрать cleartext allowlist для IP;
- сузить CORS с `cors()` по умолчанию до конкретных origin;
- задокументировать production hostname в `infra/README.md`.
