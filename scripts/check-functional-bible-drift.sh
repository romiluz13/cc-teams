#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing file: $path"
}

command -v rg >/dev/null 2>&1 || fail "ripgrep (rg) is required"

repo="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$repo/docs/functional-governance/protocol-manifest.md"
bible="$repo/docs/functional-governance/cc-teams-bible-functional.md"

require_file "$manifest"
require_file "$bible"

rg -q '^-\s+`plugins/cc-teams/skills`$' "$manifest" || fail "Manifest missing skills source root"
rg -q '^-\s+`plugins/cc-teams/agents`$' "$manifest" || fail "Manifest missing agents source root"

mapfile -t citations < <(sed -n 's/^Source: `\([^`]*\)`[[:space:]]*$/\1/p' "$bible")
(( ${#citations[@]} >= 12 )) || fail "Bible must include at least 12 Source citations"

for citation in "${citations[@]}"; do
  path="${citation%%:*}"
  line="${citation##*:}"

  case "$path" in
    plugins/cc-teams/skills/*|plugins/cc-teams/agents/*) ;;
    *) fail "Non-functional source citation: $citation" ;;
  esac

  require_file "$repo/$path"

  if [[ "$citation" == *:* ]]; then
    [[ "$line" =~ ^[0-9]+$ ]] || fail "Invalid line number in citation: $citation"
    max_line="$(wc -l < "$repo/$path" | tr -d ' ')"
    (( line >= 1 && line <= max_line )) || fail "Line number out of range in citation: $citation (max $max_line)"
  fi
done

echo "OK: Functional bible citations are valid and constrained to functional files."
