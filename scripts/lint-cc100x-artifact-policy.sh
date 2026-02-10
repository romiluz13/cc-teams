#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"

require_pattern() {
  local file="$1"
  local pattern="$2"
  local message="$3"
  if ! rg -q "$pattern" "$file"; then
    echo "FAIL: $message" >&2
    exit 1
  fi
}

lead="$repo/plugins/cc100x/skills/cc100x-lead/SKILL.md"
[[ -f "$lead" ]] || { echo "FAIL: Missing lead skill file" >&2; exit 1; }

require_pattern "$lead" "^## Artifact Governance \\(MANDATORY\\)" "Lead skill must define Artifact Governance section"
require_pattern "$lead" "Forbidden by default:" "Lead skill must define forbidden artifact behavior"
require_pattern "$lead" "CC100X REM-EVIDENCE: unauthorized artifact claim" "Lead skill must enforce REM-EVIDENCE on unauthorized artifacts"
require_pattern "$lead" "approved durable artifact paths|Approved durable artifact paths" "Lead skill must define approved durable paths"

for agent in \
  live-reviewer \
  hunter \
  security-reviewer \
  performance-reviewer \
  quality-reviewer; do
  file="$repo/plugins/cc100x/agents/$agent.md"
  [[ -f "$file" ]] || { echo "FAIL: Missing agent file $file" >&2; exit 1; }
  require_pattern "$file" "^## Artifact Discipline \\(MANDATORY\\)" "$agent must define Artifact Discipline section"
  require_pattern "$file" "Do NOT create standalone report files" "$agent must forbid standalone report files"
done

echo "OK: CC100x artifact governance policy is present."
