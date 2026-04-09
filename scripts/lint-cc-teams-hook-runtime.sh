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

settings="$repo/plugins/cc-teams/settings.json"
claude="$repo/plugins/cc-teams/CLAUDE.md"
hook_readme="$repo/plugins/cc-teams/hooks/README.md"
hook_mode="$repo/plugins/cc-teams/config/hook-mode.json"
lead="$repo/plugins/cc-teams/skills/cc-teams-lead/SKILL.md"
manifest="$repo/docs/functional-governance/protocol-manifest.md"

require_file "$settings" "Missing CC-Teams settings.json"
require_file "$claude" "Missing CC-Teams CLAUDE.md"
require_file "$hook_readme" "Missing CC-Teams hooks README"
require_file "$hook_mode" "Missing CC-Teams hook-mode config"
require_file "$lead" "Missing CC-Teams lead skill"
require_file "$manifest" "Missing protocol manifest"

for script in \
  "$repo/plugins/cc-teams/scripts/cc_teams_hooklib.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_task_created_guard.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_teammate_idle_guard.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_task_completed_guard.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_sessionstart_context.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_postcompact_context.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_stop_persist.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_stop_failure_log.py" \
  "$repo/plugins/cc-teams/scripts/cc-teams_instructions_loaded_audit.py"; do
  require_file "$script" "Missing hook runtime script: $script"
done

for hook in TaskCreated SessionStart PostCompact Stop StopFailure InstructionsLoaded; do
  require_pattern "$settings" "\"$hook\"" "settings.json must register $hook hook"
done

require_pattern "$settings" "CLAUDE_PROJECT_DIR" "settings.json hook commands must use CLAUDE_PROJECT_DIR path resolution"

require_pattern "$claude" "^## Optional Hook Runtime" "CLAUDE.md must document Optional Hook Runtime"
require_pattern "$claude" "SessionStart" "CLAUDE.md must mention SessionStart hook"
require_pattern "$hook_readme" "hook-events\\.log" "hooks README must document hook-events.log"
require_pattern "$hook_readme" "precompact-state\\.json" "hooks README must document precompact-state.json"
require_pattern "$hook_readme" "forensics/" "hooks README must document forensics directory"
require_pattern "$hook_readme" "cc_teams_hooklib\\.py" "hooks README must reference cc_teams_hooklib.py"
require_pattern "$hook_mode" "taskMetadata" "hook-mode.json must define taskMetadata mode"
require_pattern "$hook_mode" "taskMemoryFinalize" "hook-mode.json must define taskMemoryFinalize mode"
require_pattern "$hook_mode" "sessionStartContext" "hook-mode.json must define sessionStartContext mode"
require_pattern "$hook_mode" "instructionsLoadedAudit" "hook-mode.json must define instructionsLoadedAudit mode"

require_pattern "$lead" "research_quality" "Lead skill must define research_quality artifact state"
require_pattern "$lead" "memory_sync" "Lead skill must define memory_sync artifact state"
require_pattern "$lead" "latency_telemetry" "Lead skill must define latency_telemetry artifact state"
require_pattern "$lead" "^## Pending Gate Canon \\(MANDATORY\\)" "Lead skill must define explicit pending gate canon"
require_pattern "$lead" "scope_decision" "Lead skill must include scope_decision pending gate"
require_pattern "$lead" "checkpoint_decision" "Lead skill must include checkpoint_decision pending gate"
require_pattern "$lead" "^## Instruction Precedence \\(MANDATORY\\)" "Lead skill must define instruction precedence"

require_pattern "$manifest" "Optional audit-first hooks may also be enabled" "Protocol manifest must describe expanded optional hooks"
require_pattern "$manifest" "research_quality" "Protocol manifest must mention research_quality"
require_pattern "$manifest" "memory_sync" "Protocol manifest must mention memory_sync"
require_pattern "$manifest" "latency_telemetry" "Protocol manifest must mention latency_telemetry"

echo "OK: CC-Teams hook runtime policy is present."
