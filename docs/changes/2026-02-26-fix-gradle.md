# Исправление сборки Gradle и конфликта версий Java

## Описание изменений
- Обновлен Gradle Wrapper до версии `8.10.2` в модулях `mobile/android` и `wear/android`.
- Исправлены несовместимости с Flutter 3.24.5 в мобильном приложении:
  - Метод `.withValues(alpha: ...)` заменен на `.withOpacity(...)`.
  - Параметр `initialValue` в `DropdownButtonFormField` заменен на `value`.
- В GitHub Actions (`ci.yml`) добавлен шаг очистки `gradle.properties` от локальных путей к Java (`org.gradle.java.home`).

## Причина
Локальные настройки VS Code (Java 25) конфликтовали с Gradle в CI (Java 21), что вызывало ошибку `Unsupported class file major version 69` или `65`. Обновление Gradle до 8.10.2 обеспечивает полную поддержку Java 21 и стабильность сборки в различных окружениях.
