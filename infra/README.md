# Infrastructure

Инфраструктура проекта Runterra.

## Сервер backend (Cloud.ru)

- **SSH алиас:** `runterra` (настроен в `~/.ssh/config`)
- **IP:** `85.208.85.13`
- **Порт backend:** `3000`
- **Путь к репо:** `/home/user1/runterra`
- **Путь к backend:** `/home/user1/runterra/backend`

### Systemd сервис

```
runterra-backend.service
```

Управление:
```bash
ssh runterra "systemctl status runterra-backend"
ssh runterra "systemctl restart runterra-backend"
ssh runterra "journalctl -u runterra-backend -f"  # логи
```

### Обновление backend

На сервере есть скрипт `~/runterra/backend/update.sh`:
```bash
git pull → npm ci → npm run build → systemctl restart runterra-backend
```

**Локально** (из корня репо):
```bash
npm run deploy:backend   # push + SSH + update.sh
npm run deploy           # backend + mobile
```

## Firebase App Distribution (mobile)

Тестировщики получают email с новой сборкой.

```bash
npm run deploy:mobile    # tests + build APK + upload + notify
```

Конфиг: `scripts/app-distribution.config.json`

## CI/CD

GitHub Actions CI (`ci.yml`) запускается на каждый push/PR в main:
- **Backend:** typecheck, tests, build
- **Mobile:** analyze, tests, build APK

Скрипт `npm run deploy` автоматически ждёт прохождения CI перед деплоем.

## TODO

- [ ] Docker для backend
- [x] CI/CD (GitHub Actions) — проверка перед деплоем
- [ ] Автодеплой после merge в main
- [ ] Staging окружение
- [ ] HTTPS / домен

  Много TODO в коде. Вот ключевые по приоритетам:
  Критично для MVP:
  1. Firebase Auth — сейчас mock, нужна реальная проверка токенов
  2. События — запись на событие, check-in с GPS проверкой
  3. Пробежки — валидация (слишком короткая/быстрая), сохранение GPS точек

  Важно:
  4. Фильтры карты/событий — параметры принимаются, но не обрабатываются на backend
  5. Профиль — выход из аккаунта, удаление аккаунта
  6. Backend URL — захардкожен в нескольких экранах, нужно вынести в конфиг

  На потом:
  7. i18n — локализация строк (много хардкода на русском)
  8. Чат — real-time сообщения, пагинация
  9. Retry logic — повторные запросы при ошибках сети
  10. Background GPS — трекинг пробежки в фоне