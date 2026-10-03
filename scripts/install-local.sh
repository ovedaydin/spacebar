#!/usr/bin/env bash
# Builds Spacebar and installs it to /Applications, replacing the running copy.
# Full Disk Access survives because local builds are signed with the same
# certificate (signing/identity.txt).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/packaging/app.env"
"$ROOT/scripts/build-app.sh"

osascript -e "quit app id \"$BUNDLE_ID\"" 2>/dev/null || true
sleep 1
rm -rf "/Applications/$APP_NAME.app"
ditto "$ROOT/dist/$APP_NAME.app" "/Applications/$APP_NAME.app"
rm -rf "$ROOT/dist/$APP_NAME.app"   # one copy only, so permissions go to the installed app
echo "==> Installed /Applications/$APP_NAME.app"
open "/Applications/$APP_NAME.app"
