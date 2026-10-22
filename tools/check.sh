#!/usr/bin/env bash
# Static checks for src/avatar-copier.lua: syntax, unknown globals, URLs, version strings and text hygiene.
# Usage: tools/check.sh [directory with luau-compile and luau-analyze]   (defaults to PATH)
set -euo pipefail
cd "$(dirname "$0")/.."
BIN="${1:-}"
COMPILE="${BIN:+$BIN/}luau-compile"
ANALYZE="${BIN:+$BIN/}luau-analyze"
SRC=src/avatar-copier.lua
status=0
fail() { echo "FAIL: $*"; status=1; }

# 1. Syntax.
"$COMPILE" --null "$SRC" >/dev/null || fail "luau-compile rejected $SRC"

# 2. Unknown globals: a typo such as `Instnace` shows up here.
allowed="$(grep -v '^#' tools/globals.txt | grep -v '^$' | sort -u)"
found="$("$ANALYZE" "$SRC" 2>&1 | grep -oE "Unknown global '[^']+'" | sed -E "s/Unknown global '([^']+)'/\1/" | sort -u || true)"
unexpected="$(comm -23 <(echo "$found") <(echo "$allowed") | grep -v '^$' || true)"
[ -z "$unexpected" ] || fail "unknown globals: $(echo $unexpected)"

# 3. Every URL in the source is listed in tools/allowed-urls.txt.
urls="$(grep -oE 'https?://[^"'"'"' )]+' "$SRC" | sort -u)"
allowedUrls="$(grep -v '^#' tools/allowed-urls.txt | grep -v '^$' | sort -u)"
extra="$(comm -23 <(echo "$urls") <(echo "$allowedUrls") | grep -v '^$' || true)"
[ -z "$extra" ] || fail "URLs not in tools/allowed-urls.txt: $(echo $extra)"

# 4. The version in the header, the window subtitle and the newest changelog entry agree.
header="$(head -n 1 "$SRC" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || true)"
subtitle="$(grep -oE 'by lyraEz   ·   v[0-9]+\.[0-9]+\.[0-9]+' "$SRC" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || true)"
changelog="$(grep -m 1 -oE '^## v?[0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || true)"
[ -n "$header" ] && [ "$header" = "$subtitle" ] && [ "$header" = "v$changelog" ] \
    || fail "version mismatch: header=$header subtitle=$subtitle changelog=$changelog"

# 5. Text hygiene for every tracked text file.
files="$(git ls-files --cached --others --exclude-standard)"
for file in $files; do
    case "$file" in *.png|*.jpg|*.ico) continue ;; esac
    [ -f "$file" ] || continue
    if grep -q $'\r' "$file"; then fail "$file has CRLF line endings"; fi
    if grep -nE '[[:space:]]+$' "$file" >/dev/null; then fail "$file has trailing whitespace"; fi
done

# 6. Nothing that looks like a credential.
patterns='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|discord(app)?\.com/api/webhooks|xox[abpr]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{20,}|Bearer [A-Za-z0-9._-]{20,}'
if git grep --untracked -nIE "$patterns" -- ':!tools/check.sh' >/dev/null 2>&1; then
    fail "possible credential: $(git grep --untracked -nIE "$patterns" -- ':!tools/check.sh' | head -n 3)"
fi

[ "$status" -eq 0 ] && echo "OK: static checks passed"
exit "$status"
