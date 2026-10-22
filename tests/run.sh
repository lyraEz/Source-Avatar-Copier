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
    # Skin sync ships turned off; the tests point it at the fake server in tests/run.lua.
    sed 's|^    SyncUrl = "",$|    SyncUrl = "https://sync.test/v1/sync",|' src/avatar-copier.lua
    echo
    echo 'return {Config = Config, F = F, S = S, Rig = Rig, API = API, Appearance = Appearance, Codec = Codec, Visual = Visual,'
    echo '    Overlay = Overlay, Sync = Sync, Store = Store, App = App, Repair = Repair, Auto = Auto, Catalog = Catalog, Looks = Looks,'
    echo '    Toast = Toast, UI = UI, cleanup = cleanup}'
    echo 'end'
    cat tests/run.lua
} > "$OUT"
grep -q '^    SyncUrl = "https://sync.test/v1/sync",$' "$OUT" || { echo "tests/run.sh: could not point Config.SyncUrl at the test server"; exit 1; }
"$LUAU" "$OUT"
