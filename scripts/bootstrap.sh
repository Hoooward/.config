#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backup_root="${HOME}/.hzht-config-backups/$(date +%Y%m%d-%H%M%S)"
created_backup_root=0
stub_marker="# Managed by hzht-config. Re-run bootstrap if repo path changes."

backup_target() {
  local target="$1"

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  if [ "$created_backup_root" -eq 0 ]; then
    mkdir -p "$backup_root"
    created_backup_root=1
  fi

  local relative="${target#$HOME/}"
  local destination="$backup_root/$relative"
  mkdir -p "$(dirname "$destination")"
  mv "$target" "$destination"
  printf 'Backed up %s -> %s\n' "$target" "$destination"
}

link_file() {
  local source_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
    printf 'OK %s\n' "$target_path"
    return
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    backup_target "$target_path"
  fi

  ln -s "$source_path" "$target_path"
  printf 'Linked %s -> %s\n' "$target_path" "$source_path"
}

write_source_stub() {
  local target_path="$1"
  local repo_file="$2"
  local desired_content
  desired_content="$(cat <<EOF
$stub_marker
HZHT_CONFIG_ROOT="$repo_root"
source "\$HZHT_CONFIG_ROOT/$repo_file"
EOF
)"

  mkdir -p "$(dirname "$target_path")"

  if [ -f "$target_path" ] && [ ! -L "$target_path" ]; then
    local current_content
    current_content="$(cat "$target_path")"
    if [ "$current_content" = "$desired_content" ]; then
      printf 'OK %s\n' "$target_path"
      return
    fi
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    backup_target "$target_path"
  fi

  printf '%s\n' "$desired_content" >"$target_path"
  printf 'Wrote %s\n' "$target_path"
}

write_source_stub "$HOME/.zshrc" ".zshrc"
write_source_stub "$HOME/.zprofile" ".zprofile"
write_source_stub "$HOME/.zshenv" ".zshenv"
write_source_stub "$HOME/.tmux.conf" ".tmux.conf"
link_file "$repo_root/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$repo_root/codex/config.toml" "$HOME/.codex/config.toml"
link_file "$repo_root/cursor/mcp.json" "$HOME/.cursor/mcp.json"

if [ "$created_backup_root" -eq 0 ]; then
  printf 'No backups created.\n'
else
  printf 'Backups stored under %s\n' "$backup_root"
fi
