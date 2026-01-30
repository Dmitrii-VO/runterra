# Настройка Firebase Authentication для Android

Инструкция по настройке Firebase Authentication в мобильном приложении Runterra (Flutter/Android).

## Обзор

Firebase Authentication используется для авторизации пользователей в приложении. На текущей стадии (skeleton) настройка Firebase опциональна, но необходима для полноценной работы авторизации.

**ЗАЧЕМ:** Firebase Authentication обеспечивает безопасную аутентификацию пользователей через email/password, Google Sign-In и другие провайдеры. Backend проверяет Firebase ID токены для авторизации запросов.

## Предварительные требования

1. Аккаунт Google (для доступа к Firebase Console)
2. Flutter SDK установлен и настроен
3. Android Studio или Android SDK установлен
4. Проект Flutter настроен для Android

## Шаги настройки

### 1. Создание проекта Firebase

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Нажмите **"Add project"** (Добавить проект)
3. Введите название проекта: `Runterra` (или другое)
4. Отключите Google Analytics (опционально, для skeleton не требуется)
5. Нажмите **"Create project"**

### 2. Добавление Android приложения в Firebase

1. В Firebase Console выберите созданный проект
2. Нажмите на иконку **Android** (или **"Add app"** → **Android**)
3. Заполните форму:
   - **Android package name:** `com.runterra.runterra` (должен совпадать с `applicationId` в `android/app/build.gradle`)
   - **App nickname:** `Runterra Android` (опционально)
   - **Debug signing certificate SHA-1:** (опционально, для тестирования)
4. Нажмите **"Register app"**

### 3. Скачивание конфигурационного файла

1. После регистрации приложения Firebase предложит скачать файл `google-services.json`
2. **ВАЖНО:** Скачайте файл `google-services.json`
3. Поместите файл в папку: `mobile/android/app/google-services.json`
   - Файл должен быть в корне папки `app/`, рядом с `build.gradle`

**Структура должна быть:**
```
mobile/android/app/
  ├── build.gradle
  ├── google-services.json  ← здесь
  └── src/
```

### 4. Настройка Android build.gradle

#### 4.1. Корневой build.gradle (`mobile/android/build.gradle`)

Добавьте Google Services plugin в `buildscript.dependencies`:

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.0'  // ← добавить эту строку
    }
}
```

#### 4.2. App-level build.gradle (`mobile/android/app/build.gradle`)

Добавьте Google Services plugin в конец файла:

```gradle
// ... существующий код ...

dependencies {}

// Добавить в конец файла:
apply plugin: 'com.google.gms.google-services'
```

**ВАЖНО:** Плагин `google-services` должен применяться **после** всех остальных плагинов, в самом конце файла.

### 5. Добавление Firebase зависимостей в Flutter

#### 5.1. Обновите `mobile/pubspec.yaml`

Добавьте Firebase зависимости:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... существующие зависимости ...
  
  # Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
```

#### 5.2. Установите зависимости

```bash
cd mobile
flutter pub get
```

### 6. Инициализация Firebase в коде

#### 6.1. Обновите `mobile/lib/main.dart`

Добавьте инициализацию Firebase перед запуском приложения:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';

void main() async {
  // Инициализация Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  
  // ... остальной код ...
}
```

**ВАЖНО:** `WidgetsFlutterBinding.ensureInitialized()` должен быть вызван перед `Firebase.initializeApp()`.

### 7. Проверка настройки

#### 7.1. Соберите проект

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --debug
```

Если сборка прошла успешно без ошибок — Firebase настроен корректно.

#### 7.2. Проверка в коде (опционально)

Добавьте простую проверку в `ProfileScreen` или другой экран:

```dart
import 'package:firebase_auth/firebase_auth.dart';

// Проверка текущего пользователя
final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  print('User logged in: ${user.uid}');
} else {
  print('No user logged in');
}
```

## Настройка для разных окружений

### Development (разработка)

Используйте отдельный Firebase проект для разработки:
- Создайте проект `Runterra Dev` в Firebase Console
- Скачайте `google-services.json` для dev окружения
- Храните файл в `mobile/android/app/google-services.json`

### Production (продакшн)

Для продакшна используйте отдельный Firebase проект:
- Создайте проект `Runterra Prod` в Firebase Console
- Настройте CI/CD для подмены `google-services.json` при сборке

**Рекомендация:** Используйте разные Firebase проекты для dev/staging/prod окружений.

## Настройка методов авторизации в Firebase Console

1. В Firebase Console перейдите в **Authentication** → **Sign-in method**
2. Включите нужные провайдеры:
   - **Email/Password** (рекомендуется для MVP)
   - **Google** (опционально)
   - **Phone** (опционально)

**Для skeleton:** Достаточно включить Email/Password.

## Интеграция с Backend

После настройки Firebase в mobile приложении:

1. **Mobile:** Пользователь авторизуется через Firebase Auth и получает ID токен
2. **Mobile:** Отправляет ID токен в заголовке `Authorization: Bearer <token>` при запросах к backend
3. **Backend:** Проверяет токен через Firebase Admin SDK (требует настройки backend)

**Текущий статус backend:** Backend имеет заглушки для проверки токенов. Реальная интеграция требует:
- Установки `firebase-admin` в backend
- Настройки Firebase Admin SDK credentials
- Реализации проверки токенов в `backend/src/modules/auth/firebase.provider.ts`

## Troubleshooting

### Ошибка: "File google-services.json is missing"

**Решение:** Убедитесь, что файл `google-services.json` находится в `mobile/android/app/google-services.json`

### Ошибка: "Default FirebaseApp is not initialized"

**Решение:** Убедитесь, что `Firebase.initializeApp()` вызывается в `main()` до `runApp()`

### Ошибка: "Package name mismatch"

**Решение:** Убедитесь, что package name в Firebase Console (`com.runterra.runterra`) совпадает с `applicationId` в `android/app/build.gradle`

### Ошибка при сборке: "Plugin with id 'com.google.gms.google-services' not found"

**Решение:** Убедитесь, что Google Services plugin добавлен в `buildscript.dependencies` в корневом `build.gradle`

## Следующие шаги

После настройки Firebase:

1. ✅ Firebase инициализирован в приложении
2. ⏳ Реализовать экран логина/регистрации (TODO)
3. ⏳ Интегрировать получение ID токена после авторизации (TODO)
4. ⏳ Передавать токен в API запросах (TODO)
5. ⏳ Настроить Firebase Admin SDK в backend (TODO)

## Дополнительные ресурсы

- [Firebase Flutter документация](https://firebase.flutter.dev/)
- [Firebase Authentication документация](https://firebase.google.com/docs/auth)
- [FlutterFire Setup Guide](https://firebase.flutter.dev/docs/overview)

## Примечания

- На текущей стадии (skeleton) Firebase настройка опциональна
- Без Firebase приложение запустится, но авторизация работать не будет
- Backend использует заглушки для авторизации, реальная проверка токенов требует настройки Firebase Admin SDK
