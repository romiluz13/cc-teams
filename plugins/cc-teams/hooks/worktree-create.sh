#!/usr/bin/env bash
# CC-Teams WorktreeCreate hook: sync .claude/cc-teams/ memory to new isolated worktree.
# Fires when isolation: worktree creates a worktree for the builder agent (Claude Code v2.1.50).
#
# NOTE: Per Claude Code docs, WorktreeCreate "replaces default git behavior" — this hook
# is responsible for creating the worktree AND syncing memory files. If the input format
# differs from the assumptions below, the hook falls back to exit 0 (safe no-op).
set -euo pipefail

INPUT=$(cat)

# Parse expected worktree path and branch from hook input (defensive)
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // ""' 2>/dev/null || echo "")
BRANCH=$(echo "$INPUT" | jq -r '.branch // ""' 2>/dev/null || echo "")

# Get the main repository root (first worktree = main tree)
MAIN_ROOT=$(git worktree list --porcelain 2>/dev/null | grep "^worktree " | head -1 | awk '{print $2}' || echo "")
CURRENT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

# If we can identify the target worktree path from hook input, create it + sync memory
if [[ -n "$WORKTREE_PATH" ]] && [[ -n "$MAIN_ROOT" ]]; then
  # Create the worktree (replaces default git behavior as per docs)
  if [[ -n "$BRANCH" ]]; then
    git worktree add -b "$BRANCH" "$WORKTREE_PATH" 2>/dev/null || \
    git worktree add "$WORKTREE_PATH" "$BRANCH" 2>/dev/null || true
  else
    git worktree add "$WORKTREE_PATH" 2>/dev/null || true
  fi
  # Sync cc-teams memory to new worktree
  MAIN_MEMORY="$MAIN_ROOT/.claude/cc-teams"
  if [[ -d "$MAIN_MEMORY" ]]; then
    mkdir -p "$WORKTREE_PATH/.claude"
    cp -r "$MAIN_MEMORY" "$WORKTREE_PATH/.claude/"
  fi
  exit 0
fi

# Fallback: if running inside a secondary worktree (not main), sync memory from main
if [[ -n "$MAIN_ROOT" ]] && [[ -n "$CURRENT_ROOT" ]] && [[ "$MAIN_ROOT" != "$CURRENT_ROOT" ]]; then
  MAIN_MEMORY="$MAIN_ROOT/.claude/cc-teams"
  CURRENT_MEMORY="$CURRENT_ROOT/.claude/cc-teams"
  if [[ -d "$MAIN_MEMORY" ]] && [[ ! -d "$CURRENT_MEMORY" ]]; then
    mkdir -p "$CURRENT_ROOT/.claude"
    cp -r "$MAIN_MEMORY" "$CURRENT_ROOT/.claude/"
  fi
fi

exit 0
