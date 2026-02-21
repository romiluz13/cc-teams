#!/usr/bin/env bash
# CC-Teams TaskCompleted hook: enforce completion criteria for CC-TEAMS tasks.
# Input: JSON on stdin with task_id, task_subject, task_description?, teammate_name?, team_name?.
# Exit 2 → prevents task completion, sends stderr to model as feedback.
# Core orchestration is unchanged if this hook is not installed.
set -euo pipefail

INPUT=$(cat)
SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // ""' 2>/dev/null || echo "")

# Only enforce for CC-TEAMS namespaced tasks
if ! echo "$SUBJECT" | grep -q "^CC-TEAMS "; then
  exit 0
fi

# Memory Update task: verify .claude/cc-teams/ files actually exist
if echo "$SUBJECT" | grep -q "CC-TEAMS Memory Update"; then
  MEMORY_DIR=".claude/cc-teams"
  if [[ ! -d "$MEMORY_DIR" ]]; then
    echo "[CC-Teams] Memory Update task completing, but .claude/cc-teams/ directory not found." >&2
    echo "The lead must run the memory persistence steps (mkdir + Write/Edit pattern) before closing this task." >&2
    exit 2
  fi
  if [[ ! -f "$MEMORY_DIR/activeContext.md" ]]; then
    echo "[CC-Teams] Memory Update task completing, but activeContext.md not found." >&2
    echo "Persist learnings to .claude/cc-teams/activeContext.md before completing the Memory Update task." >&2
    exit 2
  fi
  exit 0
fi

# All other CC-TEAMS tasks: pass through (lead validates Router Contracts manually)
exit 0
