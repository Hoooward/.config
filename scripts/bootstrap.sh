#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backup_root="${HOME}/.hzht-config-backups/$(date +%Y%m%d-%H%M%S)"
created_backup_root=0

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

link_file "$repo_root/.zshrc" "$HOME/.zshrc"
link_file "$repo_root/.zprofile" "$HOME/.zprofile"
link_file "$repo_root/.zshenv" "$HOME/.zshenv"
link_file "$repo_root/.tmux.conf" "$HOME/.tmux.conf"
link_file "$repo_root/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$repo_root/codex/config.toml" "$HOME/.codex/config.toml"
link_file "$repo_root/cursor/mcp.json" "$HOME/.cursor/mcp.json"

if [ "$created_backup_root" -eq 0 ]; then
  printf 'No backups created.\n'
else
  printf 'Backups stored under %s\n' "$backup_root"
fi
