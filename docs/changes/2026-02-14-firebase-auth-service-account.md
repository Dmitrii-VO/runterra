# Firebase App Distribution: поддержка GOOGLE_APPLICATION_CREDENTIALS

Дата: 2026-02-14

## Контекст

Firebase CLI выдаёт deprecation warning при использовании `--token` (FIREBASE_TOKEN): «Authenticating with --token is deprecated... use a service account key with GOOGLE_APPLICATION_CREDENTIALS».

## Изменения

**deploy-mobile.ps1 и deploy-mobile.sh:**
- Приоритет аутентификации: `GOOGLE_APPLICATION_CREDENTIALS` (путь к JSON service account) → `FIREBASE_TOKEN` (fallback).
- Если `GOOGLE_APPLICATION_CREDENTIALS` задана и файл существует — `--token` не передаётся, deprecation warning не появляется.
- Если `GOOGLE_APPLICATION_CREDENTIALS` указывает на несуществующий файл — fallback на `FIREBASE_TOKEN`.

**docs/build-and-share.md:**
- Добавлена инструкция по настройке `GOOGLE_APPLICATION_CREDENTIALS`.

## Использование

Перед деплоем (PowerShell):
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "D:\myprojects\Runterra\firebase-service-account.json"
npm run deploy:mobile
```

Файл `firebase-service-account.json` — ключ из Firebase Console → Project settings → Service accounts → Generate new private key. Добавлен в .gitignore.
