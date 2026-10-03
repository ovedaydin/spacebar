#!/usr/bin/env bash
# Signs the release ZIP for Sparkle and writes dist/appcast.xml describing it.
# The appcast is uploaded with each GitHub release; the app's feed URL
# (…/releases/latest/download/appcast.xml) always resolves to the newest one.
#
#   SPARKLE_KEY_FILE=signing/sparkle_private_key ./scripts/make-appcast.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/packaging/app.env"
KEY="${SPARKLE_KEY_FILE:?set SPARKLE_KEY_FILE to the Sparkle private key file}"
SIGN_UPDATE="$(find "$ROOT/.build/artifacts" -path "*/bin/sign_update" | head -1)"
[[ -x "$SIGN_UPDATE" ]] || { echo "sign_update not found; run: swift package resolve" >&2; exit 1; }

PLIST="$ROOT/dist/$APP_NAME.app/Contents/Info.plist"
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")"
BUILD="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")"
ZIP="$ROOT/dist/$APP_NAME-$VERSION.zip"
[[ -f "$ZIP" ]] || { echo "Missing $ZIP; run scripts/package.sh first" >&2; exit 1; }

# Prints: sparkle:edSignature="…" length="…"
SIGNATURE="$("$SIGN_UPDATE" -f "$KEY" "$ZIP")"

cat > "$ROOT/dist/appcast.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>$APP_NAME</title>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MIN_MACOS</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>https://github.com/$GITHUB_REPO/releases/tag/v$VERSION</sparkle:releaseNotesLink>
      <enclosure url="https://github.com/$GITHUB_REPO/releases/download/v$VERSION/$APP_NAME-$VERSION.zip"
                 $SIGNATURE type="application/octet-stream"/>
    </item>
  </channel>
</rss>
XML
echo "Wrote dist/appcast.xml for $VERSION ($BUILD)"
