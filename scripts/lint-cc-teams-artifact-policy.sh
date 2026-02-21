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

lead="$repo/plugins/cc-teams/skills/cc-teams-lead/SKILL.md"
[[ -f "$lead" ]] || { echo "FAIL: Missing lead skill file" >&2; exit 1; }

require_pattern "$lead" "^## Artifact Governance \\(MANDATORY\\)" "Lead skill must define Artifact Governance section"
require_pattern "$lead" "Forbidden by default:" "Lead skill must define forbidden artifact behavior"
require_pattern "$lead" "CC-TEAMS REM-EVIDENCE: unauthorized artifact claim" "Lead skill must enforce REM-EVIDENCE on unauthorized artifacts"
require_pattern "$lead" "approved durable artifact paths|Approved durable artifact paths" "Lead skill must define approved durable paths"
require_pattern "$lead" "contract\\.CLAIMED_ARTIFACTS" "Lead skill must use CLAIMED_ARTIFACTS for artifact validation"
require_pattern "$lead" "EVIDENCE_COMMANDS" "Lead skill must define command-evidence validation"

router_contract="$repo/plugins/cc-teams/skills/router-contract/SKILL.md"
[[ -f "$router_contract" ]] || { echo "FAIL: Missing router-contract skill file" >&2; exit 1; }
require_pattern "$router_contract" "CONTRACT_VERSION" "Router Contract skill must define CONTRACT_VERSION"
require_pattern "$router_contract" "CLAIMED_ARTIFACTS" "Router Contract skill must define CLAIMED_ARTIFACTS"
require_pattern "$router_contract" "EVIDENCE_COMMANDS" "Router Contract skill must define EVIDENCE_COMMANDS"

for agent in \
  builder \
  planner \
  live-reviewer \
  hunter \
  investigator \
  verifier \
  security-reviewer \
  performance-reviewer \
  quality-reviewer; do
  file="$repo/plugins/cc-teams/agents/$agent.md"
  [[ -f "$file" ]] || { echo "FAIL: Missing agent file $file" >&2; exit 1; }
  require_pattern "$file" "CONTRACT_VERSION: \"2\\.3\"" "$agent must emit Router Contract schema version"
  require_pattern "$file" "CLAIMED_ARTIFACTS:" "$agent must emit CLAIMED_ARTIFACTS in Router Contract"
  require_pattern "$file" "EVIDENCE_COMMANDS:" "$agent must emit EVIDENCE_COMMANDS in Router Contract"
done

for agent in \
  live-reviewer \
  hunter \
  security-reviewer \
  performance-reviewer \
  quality-reviewer; do
  file="$repo/plugins/cc-teams/agents/$agent.md"
  require_pattern "$file" "^## Artifact Discipline \\(MANDATORY\\)" "$agent must define Artifact Discipline section"
  require_pattern "$file" "Do NOT create standalone report files" "$agent must forbid standalone report files"
done

for agent in investigator verifier; do
  file="$repo/plugins/cc-teams/agents/$agent.md"
  [[ -f "$file" ]] || { echo "FAIL: Missing agent file $file" >&2; exit 1; }
  require_pattern "$file" "^## Shell Safety \\(MANDATORY\\)" "$agent must define Shell Safety section"
  require_pattern "$file" "Do NOT create standalone .*report files" "$agent must forbid standalone report files"
done

for agent in builder planner; do
  file="$repo/plugins/cc-teams/agents/$agent.md"
  [[ -f "$file" ]] || { echo "FAIL: Missing agent file $file" >&2; exit 1; }
  require_pattern "$file" "^## Write Policy \\(MANDATORY\\)" "$agent must define Write Policy section"
  require_pattern "$file" "Do NOT generate ad-hoc report artifacts" "$agent must forbid ad-hoc report artifacts"
done

echo "OK: CC-Teams artifact governance policy is present."
