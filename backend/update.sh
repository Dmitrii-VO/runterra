#!/bin/bash
# Update backend Runterra: pull, install, build, migrate, restart
set -e
REPO_ROOT="${HOME}/runterra"
BACKEND_DIR="${REPO_ROOT}/backend"

cd "$REPO_ROOT"
git pull

cd "$BACKEND_DIR"
npm ci
npm run build

# Run database migrations
echo "Running database migrations..."
npm run migrate:prod

sudo systemctl restart runterra-backend
echo "Backend updated and restarted."
