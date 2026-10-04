#!/usr/bin/env bash
# Opens each main page of a debug build, takes a window snapshot, and fails if any page is blank.
# Catches regressions like a view that stops the window from drawing. Changes nothing on disk
# except the snapshots (and marks the first-launch walkthrough as seen).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
OUT="${1:-$ROOT/.build/ui-smoke}"
mkdir -p "$OUT"
rm -f "$OUT"/*.png

[[ -d dist/Spacebar.app ]] && [[ "${SKIP_BUILD:-0}" == "1" ]] || DEBUG_HOOKS=1 ARCHS="$(uname -m)" ./scripts/build-app.sh >/dev/null
defaults write io.github.ovedaydin.spacebar onboardingDone -bool true

for page in overview explorer apps media offload history caches browsers; do
    SPACEBAR_SCRIPT="wait:6;route:$page;wait:12;front:1;wait:2;snap:$OUT/$page.png;wait:1;quit:1" \
        dist/Spacebar.app/Contents/MacOS/Spacebar >/dev/null 2>&1 &
    pid=$!
    for _ in $(seq 1 60); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
    kill "$pid" 2>/dev/null || true
done
swift scripts/check-snapshot.swift "$OUT"/{overview,explorer,apps,media,offload,history,caches,browsers}.png
