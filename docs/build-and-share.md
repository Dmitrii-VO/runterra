# Сборка и отправка приложения для тестирования

Рабочая инструкция по mobile build и Firebase App Distribution.

## Scope

Этот документ покрывает только mobile release-поток. Общий deploy/runtime контекст см. в [infra/README.md](../infra/README.md).

## Основные команды

Из корня репозитория:

```bash
npm run deploy
```

Это запускает полный цикл:

- backend deploy
- mobile build
- upload в Firebase App Distribution

Отдельно:

```bash
npm run deploy:backend
npm run deploy:mobile
```

С release notes:

```powershell
.\scripts\deploy-mobile.ps1 "Исправлен вход через Google"
.\scripts\deploy-all.ps1 "Новая фича"
```

Без тестов:

```powershell
.\scripts\deploy-mobile.ps1 -SkipTests
.\scripts\deploy-all.ps1 -SkipTests
```

## Firebase App Distribution

Конфиг тестировщиков хранится в `scripts/app-distribution.config.json`.

Пример:

```json
{
  "firebaseAppId": "1:718457871498:android:adbf0a55f96734f85b6173",
  "testers": ["luckyleeop@gmail.com"]
}
```

Для mobile deploy предпочтителен service account через `GOOGLE_APPLICATION_CREDENTIALS`.

Рекомендуемый локальный путь:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "D:\myprojects\Runterra\.secrets\firebase\app-distribution.json"
```

Не хранить service-account JSON в корне репозитория.

Fallback-варианты:

- `firebase login`
- `FIREBASE_TOKEN` (legacy fallback)

## Mobile Build

Быстрая debug-сборка:

```bash
cd mobile
flutter build apk --debug
```

Release-сборка:

```bash
cd mobile
flutter build apk --release
```

Результат:

- debug: `mobile/build/app/outputs/flutter-apk/app-debug.apk`
- release: `mobile/build/app/outputs/flutter-apk/app-release.apk`

## Карта

Приложение использует `Yandex MapKit`, а не Mapbox.

Если тестируется карта:

- убедиться, что Yandex MapKit API key настроен в `mobile/android/app/src/main/AndroidManifest.xml`;
- проверить, что карта открывается и не падает при старте.

Подробности настройки карты см. в `mobile/README.md`.

## Backend Для Mobile

Mobile использует `ApiConfig` и может работать:

- против локального backend через `--dart-define=API_BASE_URL=...`;
- против текущего удалённого backend по IP-конфигурации `85.208.85.13:3000`.

Примеры:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
flutter run --dart-define=API_BASE_URL=http://85.208.85.13:3000
```

Инфраструктурный переход на домен + HTTPS + reverse proxy отложен и в этот документ не входит.

## Альтернативы Распространения

### Через Firebase App Distribution

Предпочтительный способ для закрытой беты.

Тестировщики получают email, устанавливают Firebase App Tester и обновляют сборки оттуда.

### Прямая передача APK

Если нужен ручной сценарий:

- Telegram
- облако
- email для маленьких файлов

### Через USB / ADB

```bash
cd mobile
flutter install
```

## Минимальный Smoke Checklist

Перед отправкой сборки:

- [ ] приложение собирается
- [ ] работает вход
- [ ] открывается карта
- [ ] открывается профиль
- [ ] backend доступен

После deploy:

- [ ] `GET /health`
- [ ] `GET /api/version`
- [ ] один авторизованный API-запрос
- [ ] запуск mobile-сборки на устройстве/эмуляторе

## Troubleshooting

### Upload в Firebase App Distribution зависает

Что проверить:

1. Подождать 5-15 минут: debug APK может загружаться без видимого прогресса.
2. Проверить сеть, VPN и firewall.
3. Включить debug-лог:

```powershell
$env:FIREBASE_DEBUG="*"
.\scripts\deploy-mobile.ps1
```

4. Проверить авторизацию Firebase CLI.
5. Попробовать release APK вместо debug APK.

### Тестер не может скачать сборку

Проверить:

- включён ли тестировщик в Firebase App Distribution;
- нет ли ошибки `403`;
- актуальны ли группы и email тестировщиков.

### Карта не работает

Проверить:

- Yandex MapKit API key;
- интернет-соединение;
- что проблема не связана с конкретным эмулятором/устройством.
