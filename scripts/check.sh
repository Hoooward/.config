#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
status=0
stub_marker="# Managed by hzht-config. Re-run bootstrap if repo path changes."

check_link() {
  local source_path="$1"
  local target_path="$2"

  if [ ! -e "$source_path" ]; then
    printf 'MISSING SOURCE %s\n' "$source_path"
    status=1
    return
  fi

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    printf 'OK %s\n' "$target_path"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    printf 'DIFF %s\n' "$target_path"
  else
    printf 'MISSING TARGET %s\n' "$target_path"
  fi
  status=1
}

check_source_stub() {
  local target_path="$1"
  local repo_file="$2"

  if [ ! -f "$target_path" ] || [ -L "$target_path" ]; then
    printf 'DIFF %s\n' "$target_path"
    status=1
    return
  fi

  if grep -Fq "$stub_marker" "$target_path" && grep -Fq "HZHT_CONFIG_ROOT=\"$repo_root\"" "$target_path" && grep -Fq "source \"\$HZHT_CONFIG_ROOT/$repo_file\"" "$target_path"; then
    printf 'OK %s\n' "$target_path"
    return
  fi

  printf 'DIFF %s\n' "$target_path"
  status=1
}

if [ -d "$repo_root/references/theniceboy-config" ]; then
  printf 'OK %s\n' "$repo_root/references/theniceboy-config"
else
  printf 'MISSING REFERENCE %s\n' "$repo_root/references/theniceboy-config"
  status=1
fi

check_source_stub "$HOME/.zshrc" ".zshrc"
check_source_stub "$HOME/.zprofile" ".zprofile"
check_source_stub "$HOME/.zshenv" ".zshenv"
check_source_stub "$HOME/.tmux.conf" ".tmux.conf"
check_link "$repo_root/claude/settings.json" "$HOME/.claude/settings.json"
check_link "$repo_root/codex/config.toml" "$HOME/.codex/config.toml"
check_link "$repo_root/cursor/mcp.json" "$HOME/.cursor/mcp.json"

exit "$status"
