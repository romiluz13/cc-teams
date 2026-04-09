#!/usr/bin/env bash
# CC-Teams TaskCompleted hook wrapper.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

exec python3 "$PLUGIN_ROOT/scripts/cc-teams_task_completed_guard.py"
