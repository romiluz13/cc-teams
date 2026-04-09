#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
doc="$repo/docs/cc-teams-excellence/CLAUDE-CODE-CAPABILITY-VALIDATION.md"

[[ -f "$doc" ]] || { echo "FAIL: Missing Claude Code capability validation doc" >&2; exit 1; }

require_pattern() {
  local pattern="$1"
  local message="$2"
  if ! rg -q "$pattern" "$doc"; then
    echo "FAIL: $message" >&2
    exit 1
  fi
}

require_pattern "Agent Teams" "validation doc must include Agent Teams section"
require_pattern "TaskCreate" "validation doc must validate task tools"
require_pattern "TaskGet" "validation doc must validate TaskGet"
require_pattern "TaskList" "validation doc must validate TaskList"
require_pattern "TaskUpdate" "validation doc must validate TaskUpdate"
require_pattern "SendMessage" "validation doc must validate SendMessage"
require_pattern "TeamCreate" "validation doc must validate TeamCreate"
require_pattern "TeamDelete" "validation doc must validate TeamDelete"
require_pattern "TeammateIdle" "validation doc must validate TeammateIdle hook"
require_pattern "TaskCreated" "validation doc must validate TaskCreated hook"
require_pattern "TaskCompleted" "validation doc must validate TaskCompleted hook"
require_pattern "SessionStart" "validation doc must validate SessionStart hook"
require_pattern "InstructionsLoaded" "validation doc must validate InstructionsLoaded hook"
require_pattern "PreCompact" "validation doc must validate PreCompact hook"
require_pattern "PostCompact" "validation doc must validate PostCompact hook"
require_pattern "StopFailure" "validation doc must validate StopFailure hook"
require_pattern "WorktreeCreate" "validation doc must validate WorktreeCreate hook"
require_pattern "AskUserQuestion" "validation doc must validate AskUserQuestion"
require_pattern "WebFetch" "validation doc must validate WebFetch"
require_pattern "Skill" "validation doc must validate Skill tool"
require_pattern "LSP" "validation doc must validate LSP tool"
require_pattern "memory: user" "validation doc must validate memory frontmatter"
require_pattern "memory: project" "validation doc must validate project memory"
require_pattern "isolation: worktree" "validation doc must validate worktree isolation"
require_pattern "Plugin Runtime" "validation doc must include plugin runtime section"
require_pattern 'plugin manifest at `\.claude-plugin/plugin\.json`' "validation doc must validate plugin manifest usage"
require_pattern 'plugin `settings\.json` is documented for default agent settings only' "validation doc must validate plugin settings limitation"
require_pattern "Session Context And MCP" "validation doc must include session context and MCP section"
require_pattern "project and user MCP servers remain available to teammates" "validation doc must validate teammate MCP inheritance"
require_pattern "default worktree behavior when installed" "validation doc must validate WorktreeCreate override semantics"
require_pattern "created worktree absolute path to stdout" "validation doc must validate WorktreeCreate output contract"
require_pattern "CLAUDE_PROJECT_DIR" "validation doc must validate CLAUDE_PROJECT_DIR usage"
require_pattern "Unsupported Or Undocumented Claims Removed" "validation doc must record removed undocumented claims"

echo "OK: Claude Code capability validation doc covers all repo-used capabilities."
