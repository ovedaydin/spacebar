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

# The `spacebar` command: the app's own binary, linked into a writable folder on PATH (no sudo).
binary="$DEST/Spacebar.app/Contents/MacOS/Spacebar"
linked=""
for dir in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin"; do
    if [[ ":$PATH:" == *":$dir:"* && -d "$dir" && -w "$dir" ]]; then
        [[ -e "$dir/spacebar" && ! -L "$dir/spacebar" ]] && continue   # never replace someone else's file
        ln -sf "$binary" "$dir/spacebar" && linked="$dir/spacebar" && break
    fi
done
if [[ -n "$linked" ]]; then
    echo "Command-line tool: $linked (try: spacebar help)"
else
    echo "For the command-line tool, run: sudo ln -sf \"$binary\" /usr/local/bin/spacebar"
fi
open "$DEST/Spacebar.app"
