#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
lead="$repo/plugins/cc100x/skills/cc100x-lead/SKILL.md"
runbook="$repo/docs/cc100x-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md"

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

require_pattern() {
  local pattern="$1"
  local message="$2"
  if ! rg -q "$pattern" "$lead"; then
    fail "$message"
  fi
}

require_pattern_file() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  if ! rg -q "$pattern" "$file"; then
    fail "$message"
  fi
}

line_of() {
  local pattern="$1"
  rg -n "$pattern" "$lead" | head -n1 | cut -d: -f1
}

[[ -f "$lead" ]] || { echo "FAIL: Missing lead skill file: $lead" >&2; exit 1; }
[[ -f "$runbook" ]] || { echo "FAIL: Missing runbook file: $runbook" >&2; exit 1; }

# Required protocol sections
require_pattern "^## Remediation Re-Review Loop" "Lead must define Remediation Re-Review Loop section"
require_pattern "^##+# Task Status Lag \(Agent Teams\)" "Lead must define Task Status Lag escalation section"
require_pattern "^## Team Shutdown \(Gate #13\)" "Lead must define Team Shutdown gate section"
require_pattern "^## Gates \(Must Pass\)" "Lead must define mandatory gates section"
require_pattern "^## Phase-Scoped Teammate Activation \(MANDATORY\)" "Lead must define phase-scoped teammate activation"
require_pattern "^## Orphan Task Recovery \(MANDATORY\)" "Lead must define deterministic orphan task recovery"
require_pattern "^## Workflow Identity Stamp \(MANDATORY\)" "Lead must define workflow identity stamping"
require_pattern "^## Operational State Vocabulary \(MANDATORY\)" "Lead must define operational state vocabulary"
require_pattern "^#### Severity Escalation Model \(MANDATORY\)" "Lead must define severity escalation model"
require_pattern "^## Session Handoff Payload \(MANDATORY\)" "Lead must define session handoff payload schema"
require_pattern "^## Resume Checklist \(MANDATORY\)" "Lead must define resume checklist"
require_pattern "^## Execution Depth Selector \(MANDATORY\)" "Lead must define deterministic execution depth selector"

# Team shutdown requirements
require_pattern "shutdown_request" "Lead must require shutdown_request messages"
require_pattern "TeamDelete\(\)" "Lead must require TeamDelete()"
require_pattern "retry up to 3" "Lead must require retry loop for shutdown/delete"

# Idle escalation ladder
require_pattern "T\+2 minutes" "Lead must define T+2 idle escalation"
require_pattern "T\+5 minutes" "Lead must define T+5 idle escalation"
require_pattern "T\+8 minutes" "Lead must define T+8 idle escalation"
require_pattern "T\+10 minutes" "Lead must define T+10 idle escalation"
require_pattern "status unknown, status request sent" "Lead must avoid fake working claims when teammate state is unknown"
require_pattern "idle-blocked" "Lead must distinguish blocked idle state"
require_pattern "idle-unresponsive" "Lead must distinguish unresponsive idle state"
require_pattern "stalled" "Lead must define stalled state"
require_pattern "\*\*LOW\*\*" "Lead must define LOW severity condition"
require_pattern "\*\*MEDIUM\*\*" "Lead must define MEDIUM severity condition"
require_pattern "\*\*HIGH\*\*" "Lead must define HIGH severity condition"
require_pattern "\*\*CRITICAL\*\*" "Lead must define CRITICAL severity condition"
require_pattern "ask user for explicit decision" "Lead must require user decision on critical stall"

# Orphan / identity controls
require_pattern "Workflow Instance: \\{team_name\\}" "Lead must stamp tasks with workflow instance"
require_pattern "Project Root: \\{cwd\\}" "Lead must stamp tasks with project root"
require_pattern "run Orphan Task Recovery sweep first" "Execution loop must normalize orphans before scheduling"
require_pattern "stale_assumptions" "Handoff payload must require stale_assumptions field"
require_pattern "resume_entrypoint" "Handoff payload must require resume_entrypoint field"
require_pattern "RESUME_CONFIRMED" "Resume checklist must publish RESUME_CONFIRMED note"
require_pattern "TaskList wins" "Resume conflict resolution must prefer TaskList truth"
require_pattern "Quick path eligibility" "Lead must define quick path eligibility rules"
require_pattern "quick path still requires Router Contracts, verifier evidence, and memory update" "Quick path must preserve core quality gates"
require_pattern "if QUICK path emits blocking/remediation -> escalate to FULL immediately" "Quick path must auto-escalate to full on blocking findings"

# Build structural blockers (no verifier shortcut)
require_pattern "challenge blocked by all 3 reviewers" "Lead must enforce challenge blocked by all reviewers"
require_pattern "verifier blocked by challenge" "Lead must enforce verifier blocked by challenge"
require_pattern "memory update blocked by verifier" "Lead must enforce memory update blocked by verifier"
require_pattern 'spawn `builder` \+ `live-reviewer` only' "BUILD must start with phased spawn (builder + live-reviewer only)"
require_pattern 'defer `hunter` / triad / `verifier` until runnable' "BUILD must defer downstream teammate spawns"
require_pattern_file "Depth is selected before task creation" "$runbook" "Runbook must define depth selection before BUILD task creation"
require_pattern_file "S16 - BUILD quick-path bounded change" "$runbook" "Runbook must include quick-path validation scenario"
require_pattern_file "S17 - BUILD quick-path forced escalation" "$runbook" "Runbook must include quick-path escalation scenario"

# Required gates presence
for gate in \
  "1\\. \*\*AGENT_TEAMS_READY\*\*" \
  "2\\. \*\*MEMORY_LOADED\*\*" \
  "3\\. \*\*TASKS_CHECKED\*\*" \
  "4\\. \*\*INTENT_CLARIFIED\*\*" \
  "5\\. \*\*RESEARCH_EXECUTED\*\*" \
  "6\\. \*\*RESEARCH_PERSISTED\*\*" \
  "7\\. \*\*REQUIREMENTS_CLARIFIED\*\*" \
  "8\\. \*\*TEAM_CREATED\*\*" \
  "9\\. \*\*TASKS_CREATED\*\*" \
  "10\\. \*\*CONTRACTS_VALIDATED\*\*" \
  "11\\. \*\*ALL_TASKS_COMPLETED\*\*" \
  "12\\. \*\*MEMORY_UPDATED\*\*" \
  "13\\. \*\*TEAM_SHUTDOWN\*\*"; do
  require_pattern "$gate" "Missing gate definition: $gate"
done

# Gate ordering sanity (TEAM_CREATED before TASKS_CREATED)
team_created_line="$(line_of "8\\. \*\*TEAM_CREATED\*\*")"
tasks_created_line="$(line_of "9\\. \*\*TASKS_CREATED\*\*")"
if [[ -z "$team_created_line" || -z "$tasks_created_line" ]]; then
  fail "Unable to verify TEAM_CREATED/TASKS_CREATED order"
elif (( team_created_line >= tasks_created_line )); then
  fail "TEAM_CREATED must appear before TASKS_CREATED in gate sequence"
fi

# Remediation loop must include re-review triad + re-hunt + verifier re-block
require_pattern "Re-review after remediation" "Remediation loop must create re-review tasks"
require_pattern "Re-hunt after remediation" "Remediation loop must create re-hunt task"
require_pattern "Block verifier on re-reviews" "Remediation loop must re-block verifier"

if (( failures > 0 )); then
  echo "Protocol integrity lint failed with $failures error(s)." >&2
  exit 1
fi

echo "OK: CC100x protocol integrity is present in lead skill."
