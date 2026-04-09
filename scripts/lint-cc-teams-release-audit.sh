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

version="$(python3 - <<'PY'
import json, pathlib
pkg = json.loads(pathlib.Path("package.json").read_text(encoding="utf-8"))
print(pkg["version"])
PY
)"

agent_count="$(find "$repo/plugins/cc-teams/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
skill_count="$(find "$repo/plugins/cc-teams/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' | wc -l | tr -d ' ')"

readme="$repo/README.md"
changelog="$repo/CHANGELOG.md"
plugin_json="$repo/plugins/cc-teams/.claude-plugin/plugin.json"
marketplace_json="$repo/.claude-plugin/marketplace.json"
agents_dir="$repo/plugins/cc-teams/agents"

require_file "$readme" "Missing README.md"
require_file "$changelog" "Missing CHANGELOG.md"
require_file "$plugin_json" "Missing plugin.json"
require_file "$marketplace_json" "Missing marketplace.json"

require_pattern "$readme" "\\*\\*Current version:\\*\\* $version" "README current version must match package.json"
require_pattern "$changelog" "^## \\[$version\\]" "CHANGELOG must include current package version section"
require_pattern "$plugin_json" "\"version\": \"$version\"" "plugin.json version must match package.json"
require_pattern "$marketplace_json" "\"version\": \"$version\"" "marketplace.json version must match package.json"
require_pattern "$readme" "<strong>$agent_count Agents</strong>" "README agent count banner must match actual agent count"
require_pattern "$readme" "^## The $agent_count Agents" "README agent heading must match actual agent count"
require_pattern "$readme" "<strong>$skill_count Skills</strong>" "README skill count banner must match actual skill count"
require_pattern "$readme" "router-contract\\*\\* \\| YAML contract format for all agents \\(v2\\.5\\)" "README must advertise Router Contract v2.5"

while IFS= read -r agent_file; do
  require_pattern "$agent_file" "^model: inherit$" "All shipped CC-Teams agents must use model: inherit ($agent_file)"
done < <(find "$agents_dir" -maxdepth 1 -name '*.md' | sort)

echo "OK: CC-Teams release/publication audit is consistent."
