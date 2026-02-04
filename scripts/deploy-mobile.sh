#!/usr/bin/env bash
# Deploy mobile: tests -> build APK -> upload to Firebase App Distribution -> notify testers
# Usage: ./scripts/deploy-mobile.sh [release-notes]
#        ./scripts/deploy-mobile.sh --skip-tests
#        ./scripts/deploy-mobile.sh "Fix login" --skip-tests

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_PATH="$PROJECT_ROOT/scripts/app-distribution.config.json"
APK_PATH="$PROJECT_ROOT/mobile/build/app/outputs/flutter-apk/app-debug.apk"

RELEASE_NOTES=""
SKIP_TESTS=false
for arg in "$@"; do
  if [ "$arg" = "--skip-tests" ]; then
    SKIP_TESTS=true
  else
    RELEASE_NOTES="$arg"
  fi
done

if [ -z "$RELEASE_NOTES" ]; then
  RELEASE_NOTES="Release $(date '+%Y-%m-%d %H:%M')"
fi

cd "$PROJECT_ROOT"

# 1. Config
if [ ! -f "$CONFIG_PATH" ]; then
  echo "Config not found: $CONFIG_PATH"
  exit 1
fi
APP_ID=$(node -e "console.log(require('$CONFIG_PATH').firebaseAppId)")
TESTERS=$(node -e "console.log(require('$CONFIG_PATH').testers.join(','))")

echo "=== 1. Tests ==="
if [ "$SKIP_TESTS" = true ]; then
  echo "Skipped (--skip-tests)"
else
  cd "$PROJECT_ROOT/mobile"
  flutter test
  cd "$PROJECT_ROOT"
fi

echo ""
echo "=== 2. Build APK ==="
cd "$PROJECT_ROOT/mobile"
flutter build apk --debug
cd "$PROJECT_ROOT"

if [ ! -f "$APK_PATH" ]; then
  echo "APK not found: $APK_PATH"
  exit 1
fi

echo ""
echo "=== 3. Upload to Firebase App Distribution ==="
APK_SIZE_MB=$(du -m "$APK_PATH" | cut -f1)
echo "APK size: ~${APK_SIZE_MB} MB. Upload can take 5-15 min for large debug APK; progress may not show."
[ -n "$FIREBASE_DEBUG" ] && echo "FIREBASE_DEBUG is set - verbose Firebase CLI output enabled."
firebase appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --release-notes "$RELEASE_NOTES" \
  --testers "$TESTERS"

echo ""
echo "Done. Testers will receive an email: $TESTERS"
