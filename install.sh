#!/usr/bin/env bash
# Installs the latest Spacebar release into /Applications.
#   curl -fsSL https://raw.githubusercontent.com/ovedaydin/spacebar/main/install.sh | bash
set -euo pipefail

REPO="ovedaydin/spacebar"
DEST="/Applications"

tag="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')"
[[ -n "$tag" ]] || { echo "Could not find the latest release of $REPO" >&2; exit 1; }
version="${tag#v}"
zip="Spacebar-$version.zip"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading Spacebar $version…"
curl -fsSL -o "$tmp/$zip" "https://github.com/$REPO/releases/download/$tag/$zip"
curl -fsSL -o "$tmp/SHA256SUMS.txt" "https://github.com/$REPO/releases/download/$tag/SHA256SUMS.txt"
(cd "$tmp" && grep " $zip\$" SHA256SUMS.txt | shasum -a 256 -c -)

ditto -x -k "$tmp/$zip" "$tmp/out"
if [[ -d "$DEST/Spacebar.app" ]]; then
    osascript -e 'quit app id "io.github.ovedaydin.spacebar"' 2>/dev/null || true
    mv "$DEST/Spacebar.app" "$tmp/Spacebar.old.app"
fi
mv "$tmp/out/Spacebar.app" "$DEST/"
xattr -dr com.apple.quarantine "$DEST/Spacebar.app" 2>/dev/null || true
echo "Installed to $DEST/Spacebar.app"
open "$DEST/Spacebar.app"
