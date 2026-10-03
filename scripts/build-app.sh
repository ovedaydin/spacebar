#!/usr/bin/env bash
# Builds dist/Spacebar.app (universal by default) and signs it as the LAST step.
#
# Env:
#   VERSION        e.g. 1.2.0 (default: latest git tag, else 0.1.0)
#   BUILD_NUMBER   CFBundleVersion (default: commit count, else 1)
#   ARCHS          "arm64 x86_64" (default) or just "arm64" for a fast local build
#   SIGN_IDENTITY  codesign identity: a "Developer ID Application: …" name or the
#                  SHA-1 of your self-signed cert. Default: signing/identity.txt, else ad-hoc ("-").
#   KEYCHAIN       optional keychain to look the identity up in (CI)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source packaging/app.env

VERSION="${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null || echo 0.1.0)}"
VERSION="${VERSION#v}"
BUILD_NUMBER="${BUILD_NUMBER:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"
ARCHS="${ARCHS:-arm64 x86_64}"
# Local builds: use the self-signed identity from scripts/create-signing-cert.sh if present,
# so Full Disk Access survives rebuilds.
if [[ -z "${SIGN_IDENTITY:-}" && -f "$ROOT/signing/identity.txt" ]]; then
    SIGN_IDENTITY="$(tr -d '[:space:]' < "$ROOT/signing/identity.txt")"
fi
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

arch_flags=()
for a in $ARCHS; do arch_flags+=(--arch "$a"); done

# DEBUG_HOOKS=1 compiles in the scripted test hooks (local testing only, never for releases).
[[ "${DEBUG_HOOKS:-0}" == "1" ]] && arch_flags+=(-Xswiftc -DSPACEBAR_DEBUG_HOOKS) && echo "==> WITH debug hooks (test build)"
echo "==> Building $APP_NAME $VERSION ($BUILD_NUMBER) for: $ARCHS"
swift build -c release "${arch_flags[@]}"
BIN_DIR="$(swift build -c release "${arch_flags[@]}" --show-bin-path)"

APP="$ROOT/dist/$APP_NAME.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN_DIR/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"
cp packaging/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
sed -e "s|__EXECUTABLE__|$EXECUTABLE|g" \
    -e "s|__BUNDLE_ID__|$BUNDLE_ID|g" \
    -e "s|__APP_NAME__|$APP_NAME|g" \
    -e "s|__VERSION__|$VERSION|g" \
    -e "s|__BUILD__|$BUILD_NUMBER|g" \
    -e "s|__MIN_MACOS__|$MIN_MACOS|g" \
    -e "s|__SPARKLE_FEED_URL__|$SPARKLE_FEED_URL|g" \
    -e "s|__SPARKLE_PUBLIC_KEY__|$SPARKLE_PUBLIC_KEY|g" \
    packaging/Info.plist > "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Drop absolute toolchain rpaths SwiftPM adds (they point into the build machine's Xcode).
while read -r rpath; do
    [[ "$rpath" == /*Xcode*.app/* ]] && install_name_tool -delete_rpath "$rpath" "$APP/Contents/MacOS/$EXECUTABLE"
done < <(otool -l "$APP/Contents/MacOS/$EXECUTABLE" | awk '/LC_RPATH/ {getline; getline; print $2}')

# Sparkle (auto-updates). ditto keeps the framework's symlinks intact.
SPARKLE="$(find "$ROOT/.build/artifacts" -path "*macos-arm64_x86_64/Sparkle.framework" -maxdepth 6 | head -1)"
[[ -d "$SPARKLE" ]] || { echo "Sparkle.framework not found; run: swift package resolve" >&2; exit 1; }
mkdir -p "$APP/Contents/Frameworks"
ditto "$SPARKLE" "$APP/Contents/Frameworks/Sparkle.framework"

# --- Sign last: anything modified after this would invalidate the signature
# ("app is damaged" on Apple silicon).
# Without a Team ID (self-signed or ad-hoc), the embedded Sparkle.framework only loads
# with library validation disabled; Developer ID builds keep it on.
entitlements=packaging/Spacebar.selfsigned.entitlements
[[ "$SIGN_IDENTITY" == Developer\ ID* ]] && entitlements=packaging/Spacebar.entitlements
sign_args=(--force --options runtime --entitlements "$entitlements")
[[ -n "${KEYCHAIN:-}" ]] && sign_args+=(--keychain "$KEYCHAIN")
if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "==> Signing ad-hoc (Full Disk Access will need re-granting after each update)"
    identity=(--sign -)
elif [[ "$SIGN_IDENTITY" == Developer\ ID* ]]; then
    echo "==> Signing with Developer ID"
    identity=(--timestamp --sign "$SIGN_IDENTITY")
else
    echo "==> Signing with self-signed identity $SIGN_IDENTITY"
    identity=(--timestamp=none --sign "$SIGN_IDENTITY")
fi
nested_args=(--force --options runtime)
[[ -n "${KEYCHAIN:-}" ]] && nested_args+=(--keychain "$KEYCHAIN")
# Inside out: Sparkle's helpers, then the framework, then the app (no --deep).
FW="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
for nested in "$FW/XPCServices/Installer.xpc" "$FW/XPCServices/Downloader.xpc" "$FW/Autoupdate" "$FW/Updater.app" \
              "$APP/Contents/Frameworks/Sparkle.framework"; do
    [[ -e "$nested" ]] && codesign "${nested_args[@]}" "${identity[@]}" "$nested"
done
codesign "${sign_args[@]}" "${identity[@]}" "$APP"
codesign --verify --strict --deep --verbose=2 "$APP"
echo "==> Designated requirement:"
codesign -d -r- "$APP" 2>&1 | sed -n 's/^designated => /  /p'
echo "==> Built $APP"
