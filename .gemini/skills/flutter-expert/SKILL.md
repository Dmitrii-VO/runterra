# Flutter Expert (Runterra)

Advanced Flutter development patterns for the Runterra mobile app.

## UI & Widgets
- **State Management:** Use `StatefulWidget` for local state and `ServiceLocator` for global services.
- **Rebuilds:** Avoid direct API calls in `build()` or `FutureBuilder.future`. Cache futures in `initState`.
- **Localization:** Use `AppLocalizations` (l10n) for ALL strings. No hardcoded text.
- **Responsive Design:** Use `MediaQuery` and `ConstrainedBox` to ensure the app works on different screen sizes.

## Logic & Services
- **Service Locator:** Always use `ServiceLocator.instance` via `GetIt`. Do not instantiate services manually in widgets.
- **WebSocket:** Use `ChatWebSocketService` with automatic reconnection and polling fallback.
- **Firebase:** Initialize in `main.dart`. Use `AuthService` to track login state.

## Performance
- **Image Caching:** Use cached network images for avatars and club logos.
- **Lists:** Use `ListView.builder` for long lists to ensure efficient memory usage.
- **Async:** Use `runZonedGuarded` in `main.dart` to catch unhandled async errors.
