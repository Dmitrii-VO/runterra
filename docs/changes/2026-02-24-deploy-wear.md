# Deploy Wear OS через npm run deploy

**Дата:** 2026-02-24

## Изменения

### `scripts/deploy-wear.ps1` (новый)

Скрипт сборки и загрузки Wear OS APK в Firebase App Distribution.

**Параметры:**
- `-Force` — деплоить вне зависимости от наличия изменений
- `-SkipFirebase` — только сборка, без загрузки

**Логика:**
1. Вычисляет версию из последнего `v*` git-тега (та же функция `Get-VersionFromGit`, что в `deploy-mobile.ps1`)
2. Проверяет изменения в `wear/` с последнего тега (`git log <tag>..HEAD -- wear/`) — если нет и нет `-Force`, выходит с `exit 0`
3. Проверяет наличие `wear/android/app/build.gradle` — если нет, выводит инструкцию по scaffold и `exit 1`
4. `flutter pub get` и `flutter build apk --debug` в `wear/`
5. При `SkipFirebase=false` — читает `firebaseWearAppId` из конфига, запрашивает подтверждение, загружает в Firebase App Distribution

### `scripts/deploy-all.ps1`

Добавлен блок `>>> WEAR OS <<<` после `>>> MOBILE <<<`. Флаг `-SkipFirebase` передаётся в wear-скрипт.

### `scripts/app-distribution.config.json`

Добавлено поле `firebaseWearAppId: ""`. Пустая строка — сигнал «не настроено»; скрипт выводит пошаговую инструкцию по созданию Firebase-приложения.

## Как настроить Firebase для часов (одноразово)

1. **Firebase Console → Project → Add app → Android**
   - Package name: `com.runterra.mobile` (совпадает с телефоном — Wearable Data Layer требует этого)
   - Nickname: `Runterra Wear OS`
2. Скопировать App ID из настроек приложения: `1:718457871498:android:XXXXXXXX`
3. Вставить в `scripts/app-distribution.config.json` → поле `firebaseWearAppId`

## Проверка

```bash
# Деплой без изменений в wear/ — должен пропустить шаг:
npm run deploy  # → "No wear changes since vX.X.X, skipping"

# Только сборка APK без Firebase:
powershell -File scripts/deploy-wear.ps1 -Force -SkipFirebase
```
