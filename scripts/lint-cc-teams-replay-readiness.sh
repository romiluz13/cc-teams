#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"

require_file() {
  local file="$1"
  local message="$2"
  [[ -f "$file" ]] || { echo "FAIL: $message" >&2; exit 1; }
}

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
memory="$repo/plugins/cc-teams/skills/session-memory/SKILL.md"
runbook="$repo/docs/cc-teams-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md"
manifest="$repo/docs/functional-governance/protocol-manifest.md"
readme="$repo/plugins/cc-teams/hooks/README.md"

require_file "$lead" "Missing lead skill"
require_file "$memory" "Missing session-memory skill"
require_file "$runbook" "Missing expected behavior runbook"
require_file "$manifest" "Missing protocol manifest"
require_file "$readme" "Missing hook README"

for file in \
  "$repo/plugins/cc-teams/scripts/cc_teams_hooklib.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_sessionstart_context.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_postcompact_context.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_stop_persist.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_stop_failure_log.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_instructions_loaded_audit.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_task_completed_guard.py"; do
  require_file "$file" "Missing replay/hook runtime file: $file"
done

for field in \
  "research_quality" \
  "memory_sync" \
  "latency_telemetry" \
  "challenge_decisions" \
  "regressions" \
  "boundary_history" \
  "phase_transition_summaries"; do
  require_pattern "$lead" "$field" "Lead skill must include replay/artifact field $field"
  require_pattern "$memory" "$field" "Session-memory skill must include replay/artifact field $field"
done

require_pattern "$lead" "Snapshot \\+ Event Delta Protocol|Artifact Snapshot \\+ Event Delta Protocol" "Lead skill must define snapshot/event delta protocol"
require_pattern "$memory" "Snapshot-before-event protocol" "Session-memory skill must define snapshot-before-event protocol"
require_pattern "$runbook" "research_quality" "Runbook must mention research_quality"
require_pattern "$runbook" "memory_sync" "Runbook must mention memory_sync"
require_pattern "$runbook" "latency_telemetry" "Runbook must mention latency_telemetry"
require_pattern "$runbook" "pending_gate" "Runbook must mention explicit pending_gate behavior"
require_pattern "$manifest" "boundary_history\\.timeline_tail" "Protocol manifest must mention boundary history timeline tail"
require_pattern "$readme" "Workflow artifact snapshot remains the durable runtime truth" "Hook README must define snapshot truth vs audit logs"

echo "OK: CC-Teams replay readiness audit is present."
