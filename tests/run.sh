#!/usr/bin/env bash
# Runs the Avatar Copier test scenario with the Luau CLI.
# Usage: tests/run.sh [path-to-luau]   (defaults to "luau" on PATH)
set -euo pipefail
cd "$(dirname "$0")/.."
LUAU="${1:-${LUAU:-luau}}"
WORK="$(mktemp -d)"
OUT="$WORK/avatar-copier-test.lua"
trap 'rm -rf "$WORK"' EXIT
{
    cat tests/mock.lua
    echo 'function Mock.Run()'
    cat src/avatar-copier.lua
    echo
    echo 'return {Config = Config, F = F, S = S, Rig = Rig, API = API, Appearance = Appearance, Codec = Codec, Visual = Visual,'
    echo '    Overlay = Overlay, Sync = Sync, Store = Store, App = App, Repair = Repair, Auto = Auto, Catalog = Catalog, Looks = Looks,'
    echo '    Toast = Toast, UI = UI, cleanup = cleanup}'
    echo 'end'
    cat tests/run.lua
} > "$OUT"
"$LUAU" "$OUT"
