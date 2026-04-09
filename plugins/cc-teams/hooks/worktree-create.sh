#!/usr/bin/env bash
# CC-Teams WorktreeCreate hook: create the worktree and print its absolute path.
# Per Claude Code docs, WorktreeCreate replaces the default git behavior entirely.
set -euo pipefail

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REPO_ROOT="$(cd "$PROJECT_ROOT" && git rev-parse --show-toplevel)"
INPUT="$(cat)"
NAME="$(printf '%s' "$INPUT" | jq -r '.name // empty' 2>/dev/null || true)"

if [[ -z "$NAME" ]]; then
  echo "CC-Teams WorktreeCreate: missing required input field 'name'" >&2
  exit 1
fi

WORKTREE_ROOT="$HOME/.claude/worktrees"
WORKTREE_PATH="$WORKTREE_ROOT/$NAME"
mkdir -p "$WORKTREE_ROOT"

if [[ ! -d "$WORKTREE_PATH/.git" ]] && [[ ! -f "$WORKTREE_PATH/.git" ]]; then
  rm -rf "$WORKTREE_PATH"
  (
    cd "$REPO_ROOT"
    git worktree add --detach "$WORKTREE_PATH" >&2
  )
fi

SOURCE_MEMORY="$REPO_ROOT/.claude/cc-teams"
TARGET_MEMORY="$WORKTREE_PATH/.claude/cc-teams"

if [[ -d "$SOURCE_MEMORY" ]] && [[ ! -d "$TARGET_MEMORY" ]]; then
  mkdir -p "$WORKTREE_PATH/.claude"
  cp -R "$SOURCE_MEMORY" "$TARGET_MEMORY"
fi

printf '%s\n' "$WORKTREE_PATH"
