# Настройка Firebase Authentication для Android и backend-охранные механизмы

**Дата:** 2025-01-27  
**Статус:** Завершено (mobile), backend — skeleton с безопасными заглушками

## Что сделано

Настроена интеграция Firebase Authentication в мобильное приложение Runterra (Flutter/Android).
Добавлены базовые защитные механизмы на backend вокруг заглушек авторизации, чтобы исключить
случайный деплой без реальной интеграции Firebase Admin SDK.
### 1. Конфигурация Firebase

- ✅ Создан проект Firebase "Runterra" в Firebase Console
- ✅ Зарегистрировано Android приложение с package name `com.runterra.runterra`
- ✅ Файл `google-services.json` размещён в `mobile/android/app/google-services.json`

### 2. Настройка Android Gradle

- ✅ Добавлен Google Services plugin в корневой `build.gradle`:
  ```gradle
  classpath 'com.google.gms:google-services:4.4.0'
  ```
- ✅ Подключён плагин в app-level `build.gradle`:
  ```gradle
  apply plugin: 'com.google.gms.google-services'
  ```

### 3. Flutter зависимости

- ✅ Добавлены Firebase зависимости в `pubspec.yaml`:
  - `firebase_core: ^3.0.0`
  - `firebase_auth: ^5.0.0`
- ✅ Зависимости установлены через `flutter pub get`

### 4. Инициализация Firebase в коде

- ✅ Обновлён `mobile/lib/main.dart`:
  - Добавлен импорт `firebase_core`
  - Добавлена инициализация `Firebase.initializeApp()` перед запуском приложения
  - `WidgetsFlutterBinding.ensureInitialized()` вызывается перед инициализацией Firebase

## Структура изменений

```
mobile/
  android/
    app/
      ├── google-services.json  ← добавлен
      └── build.gradle          ← обновлён (добавлен apply plugin)
    build.gradle                ← обновлён (добавлен classpath)
  lib/
    main.dart                   ← обновлён (инициализация Firebase)
  pubspec.yaml                  ← обновлён (Firebase зависимости)
```

## Что осталось сделать

### Обязательно

1. **Включить методы авторизации в Firebase Console:**
   - Перейти в Firebase Console → Authentication → Sign-in method
   - Включить Email/Password (рекомендуется для MVP)

### Опционально (для skeleton не требуется)

2. Реализовать экран логина/регистрации (TODO)
3. Интегрировать получение Firebase ID токена после авторизации (TODO)
4. Передавать токен в API запросах через заголовок `Authorization: Bearer <token>` (TODO)
5. Настроить Firebase Admin SDK в backend для проверки токенов (TODO)
6. Заменить заглушки `FirebaseAuthService` / `FirebaseAuthProvider` на реальную
   интеграцию с Firebase Admin SDK, обновив startup-check `assertFirebaseAuthConfigured()`.

## Примечания

- На текущей стадии (skeleton) Firebase настроен в mobile, но авторизация не реализована end-to-end
- Без включения методов авторизации в Firebase Console экраны логина работать не будут
- Backend имеет заглушки для проверки токенов; они помечены как `SECURITY: STUB — MUST BE REPLACED`
  и в production окружении приводят к немедленной ошибке:
  - методы `verifyToken` в `backend/src/auth/service.ts` и
    `backend/src/modules/auth/firebase.provider.ts` проверяют `NODE_ENV === 'production'`
    и выбрасывают `Error`, если вызываются в таком окружении;
  - при старте сервера вызывается startup-check `assertFirebaseAuthConfigured()`, который
    блокирует запуск backend в production, если вместо реальной интеграции по-прежнему используется заглушка.

## Документация

- Инструкция по настройке: [docs/firebase-setup.md](../firebase-setup.md)
