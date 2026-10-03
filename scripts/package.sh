#!/usr/bin/env bash
# Packages dist/Spacebar.app into a ZIP (for Homebrew / installer script) and a
# drag-to-Applications DMG, plus SHA256SUMS.txt. Run after build-app.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/dist"
source "$ROOT/packaging/app.env"

APP="$APP_NAME.app"
VERSION="$(defaults read "$PWD/$APP/Contents/Info.plist" CFBundleShortVersionString)"
ZIP="$APP_NAME-$VERSION.zip"
DMG="$APP_NAME-$VERSION.dmg"

rm -f "$ZIP" "$DMG" SHA256SUMS.txt
# ditto (not zip) preserves the code signature, symlinks and metadata.
ditto -c -k --keepParent "$APP" "$ZIP"

STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format ULFO "$DMG" >/dev/null
rm -rf "$STAGE"

shasum -a 256 "$ZIP" "$DMG" > SHA256SUMS.txt
cat SHA256SUMS.txt
