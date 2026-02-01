#!/usr/bin/env bash
# Deploy backend: push to git -> SSH to server -> run update.sh
# Usage: ./scripts/deploy-backend.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SSH_HOST="runterra"
REMOTE_SCRIPT="~/runterra/backend/update.sh"

cd "$PROJECT_ROOT"

echo "=== 1. Check git status ==="
if [ -n "$(git status --porcelain)" ]; then
    echo "Uncommitted changes detected:"
    git status --porcelain
    echo ""
    echo "Commit your changes first, or they won't be deployed."
    exit 1
fi

echo "=== 2. Push to origin ==="
AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
if [ "$AHEAD" -gt 0 ]; then
    echo "Pushing $AHEAD commit(s)..."
    git push
else
    echo "Already up to date with origin."
fi

echo ""
echo "=== 3. SSH: update backend on server ==="
echo "Running: ssh $SSH_HOST \"$REMOTE_SCRIPT\""
ssh "$SSH_HOST" "$REMOTE_SCRIPT"

echo ""
echo "Backend deployed successfully!"
