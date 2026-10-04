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
swift build -c release --product "$EXECUTABLE" "${arch_flags[@]}"
BIN_DIR="$(swift build -c release --product "$EXECUTABLE" "${arch_flags[@]}" --show-bin-path)"

# A second, single-arch compile collects what Xcode normally generates for us: the strings to
# translate and the Shortcuts actions' constant values. It uses SwiftPM's native build system on
# purpose: Xcode's (used for universal builds) runs its own App Intents step and trips over these
# flags. Only the app's product is built, so the Spacebar module (compiled after SpacebarCore)
# is the one whose constant values end up in the file.
META_DIR="$ROOT/.build/metadata"
STRINGS_DIR="$META_DIR/stringsdata"
INTENTS_DIR="$META_DIR/appintents"
rm -rf "$META_DIR" && mkdir -p "$STRINGS_DIR" "$INTENTS_DIR"
echo '["AppIntent","EntityQuery","AppEntity","TransientEntity","AppEnum","AppShortcutsProvider","DynamicOptionsProvider","IntentValueQuery"]' \
    > "$INTENTS_DIR/protocols.json"
echo "==> Collecting strings and Shortcuts metadata"
swift build -c release --build-system native --arch "$(uname -m)" --product "$EXECUTABLE" \
    --scratch-path "$ROOT/.build/metadata-build" \
    -Xswiftc -emit-localized-strings -Xswiftc -emit-localized-strings-path -Xswiftc "$STRINGS_DIR" \
    -Xswiftc -emit-const-values-path -Xswiftc "$INTENTS_DIR/Spacebar.swiftconstvalues" \
    -Xswiftc -Xfrontend -Xswiftc -const-gather-protocols-file -Xswiftc -Xfrontend -Xswiftc "$INTENTS_DIR/protocols.json" \
    >/dev/null

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

# Translations: new strings from the code go into the catalog (for translating), then every
# catalog compiles into <language>.lproj folders. Needs Xcode's xcstringstool; English otherwise.
if xcrun --find xcstringstool >/dev/null 2>&1; then
    stringsdata=()
    while IFS= read -r file; do stringsdata+=(--stringsdata "$file"); done < <(find "$STRINGS_DIR" -name '*.stringsdata')
    [[ ${#stringsdata[@]} -gt 0 ]] && xcrun xcstringstool sync packaging/Localizable.xcstrings "${stringsdata[@]}"
    for catalog in packaging/*.xcstrings; do
        xcrun xcstringstool compile "$catalog" --output-directory "$APP/Contents/Resources" >/dev/null
    done
    echo "==> Added translations: $(cd "$APP/Contents/Resources" && ls -d *.lproj | sed 's/.lproj//' | tr '\n' ' ')"
else
    echo "==> Skipping translations (needs Xcode's xcstringstool)" >&2
fi

# Shortcuts metadata (Contents/Resources/Metadata.appintents). Needs Xcode, not just the Command Line Tools.
if PROCESSOR="$(xcrun --find appintentsmetadataprocessor 2>/dev/null)" && [[ -f "$INTENTS_DIR/Spacebar.swiftconstvalues" ]]; then
    find "$ROOT/Sources/$EXECUTABLE" -name '*.swift' > "$INTENTS_DIR/sources.txt"
    echo "$INTENTS_DIR/Spacebar.swiftconstvalues" > "$INTENTS_DIR/constvalues.txt"
    "$PROCESSOR" --output "$APP/Contents/Resources" \
        --toolchain-dir "$(dirname "$(dirname "$(dirname "$PROCESSOR")")")" \
        --module-name "$EXECUTABLE" --sdk-root "$(xcrun --sdk macosx --show-sdk-path)" \
        --xcode-version "$(xcodebuild -version | awk '/Build version/ {print $3}')" \
        --platform-family macOS --deployment-target "$MIN_MACOS" --target-triple "arm64-apple-macos$MIN_MACOS" \
        --source-file-list "$INTENTS_DIR/sources.txt" --swift-const-vals-list "$INTENTS_DIR/constvalues.txt" 2>&1 \
        | grep -v "^20.. .*appintentsmetadataprocessor" || true
    [[ -d "$APP/Contents/Resources/Metadata.appintents" ]] && echo "==> Added Shortcuts actions"
else
    echo "==> Skipping Shortcuts actions (needs Xcode's appintentsmetadataprocessor)" >&2
fi

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
