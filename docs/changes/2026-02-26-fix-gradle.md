# Fix Gradle Import and Java Version Conflict

## Changes made
- Upgraded Gradle Wrapper to version `8.10.2` for both `mobile/android` and `wear/android` modules.
- Configured VS Code `.vscode/settings.json` to explicitly use the bundled Android Studio Java 21 JDK (`C:\Program Files\Android\Android Studio1\jbr`).

## Why
VS Code's Java extension (redhat.java) was loading Gradle projects using Java 25. Since the background Gradle daemon uses Java 21, the Java 25 compilation of the Gradle initialization scripts crashed the build with an `Unsupported class file major version 69` error. By constraining the Java version for imports to the standard Java 21, the issue is resolved and Gradle works smoothly.
