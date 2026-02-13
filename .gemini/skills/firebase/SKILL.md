# Firebase Specialist (Runterra)

Expert in Firebase integration for the Runterra project, covering Authentication, Cloud Messaging, and Admin SDK.

## Authentication Workflow
- **Provider:** Firebase Authentication (Email/Password, Google).
- **Client-Side:** Flutter `firebase_auth` retrieves the ID Token.
- **Server-Side:** Backend verifies the token using Firebase Admin SDK.
- **Fallback:** In non-production environments, if credentials are missing, the backend may use a derived UID from the token (mocked verification).

## Setup & Configuration
- **Android:** `google-services.json` must be placed in `mobile/android/app/`.
- **iOS:** `GoogleService-Info.plist` (when implemented).
- **Backend:** Requires `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, and `FIREBASE_PRIVATE_KEY` (or a path to the service account JSON).

## Best Practices
- **Token Handling:** Never store tokens in persistent storage on the backend; verify them on every request.
- **Multi-Environment:** Maintain separate Firebase projects for `dev`, `staging`, and `prod`. Use scripts (like `scripts/load-env.ps1`) to manage environment variables.
- **Messaging:** Use Firebase Cloud Messaging (FCM) for push notifications (messages, territory captures). Ensure tokens are synced from mobile to backend `users` table.

## Maintenance
- When updating Firebase plugins in Flutter, always run `cd mobile && flutter pub get`.
- Ensure the `applicationId` in `android/app/build.gradle` matches the package name in the Firebase Console.
