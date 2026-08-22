#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/managed_block.sh"

backup_root="${HOME}/.hzht-config-backups/$(date +%Y%m%d-%H%M%S)"
created_backup_root=0

# 通用备份：凡是要改写宿主路径，先统一走这里，避免各个同步类型各自实现一套备份逻辑。
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

# 单文件同步：宿主路径最终应该是一个指向仓库文件的 symlink。
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

# 目录接管同步：
# 1. 如果宿主已有真实目录，先把内容并入仓库目录。
# 2. 再把宿主路径切成指向仓库目录的 symlink。
adopt_and_link_dir() {
  local source_dir="$1"
  local target_dir="$2"

  mkdir -p "$source_dir"
  mkdir -p "$(dirname "$target_dir")"

  if [ -L "$target_dir" ] && [ "$(readlink "$target_dir")" = "$source_dir" ]; then
    printf 'OK %s\n' "$target_dir"
    return
  fi

  if [ -d "$target_dir" ] && [ ! -L "$target_dir" ]; then
    rsync -a --ignore-existing "$target_dir"/ "$source_dir"/
    backup_target "$target_dir"
  elif [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
    backup_target "$target_dir"
  fi

  ln -s "$source_dir" "$target_dir"
  printf 'Linked %s -> %s\n' "$target_dir" "$source_dir"
}

# 入口文件托管块同步：
# 宿主文件保留为普通文件，只在其中维护一个受控 block，
# block 内负责 source 仓库里的真正入口文件。
ensure_managed_block_file() {
  local target_path="$1"
  local block_body="$2"

  mkdir -p "$(dirname "$target_path")"

  if [ -L "$target_path" ]; then
    backup_target "$target_path"
  elif [ -e "$target_path" ] && [ ! -f "$target_path" ]; then
    backup_target "$target_path"
  fi

  if managed_block_matches "$target_path" "$block_body"; then
    printf 'OK %s\n' "$target_path"
    return
  fi

  upsert_managed_block "$target_path" "$block_body"
  printf 'Updated %s\n' "$target_path"
}

# shell 类入口文件统一走这一套 block body：
# 先记录 repo_root，再 source 仓库里的目标文件。
build_shell_source_block_body() {
  local repo_file="$1"

  printf 'HZHT_CONFIG_ROOT="%s"\n' "$repo_root"
  printf 'source "$HZHT_CONFIG_ROOT/%s"' "$repo_file"
}

# tmux 不是 shell 语法，所以单独生成 source-file 形式的 body。
build_tmux_source_block_body() {
  local repo_file="$1"

  printf 'source-file "%s/%s"' "$repo_root" "$repo_file"
}

# 下面开始声明“这个仓库真正会同步什么”。
# 这里不用 spec 字符串表，是因为当前真正重要的是三种同步语义，
# 直接按 helper 调用会比额外包装一层 DSL 更清楚。
ensure_shell_source_block() {
  local target_path="$1"
  local repo_file="$2"

  ensure_managed_block_file "$target_path" "$(build_shell_source_block_body "$repo_file")"
}

ensure_tmux_source_block() {
  local target_path="$1"
  local repo_file="$2"

  ensure_managed_block_file "$target_path" "$(build_tmux_source_block_body "$repo_file")"
}

# Herdr plugin 使用官方 registry link，而不是额外维护软链位置。
# 重复 link 同一路径会刷新 manifest，适合 bootstrap 的幂等同步语义。
link_herdr_plugin() {
  local plugin_dir="$1"

  if ! command -v herdr >/dev/null 2>&1; then
    printf 'SKIP Herdr plugin %s (herdr not found)\n' "$plugin_dir"
    return
  fi

  herdr plugin link "$plugin_dir" >/dev/null
  printf 'Linked Herdr plugin %s\n' "$plugin_dir"
}

# 1. 入口文件：宿主保留，写入 managed block。
ensure_shell_source_block "$HOME/.zshrc" ".zshrc"
ensure_shell_source_block "$HOME/.zprofile" ".zprofile"
ensure_shell_source_block "$HOME/.zshenv" ".zshenv"
ensure_tmux_source_block "$HOME/.tmux.conf" ".tmux.conf"

# 2. 单文件：直接 symlink 到仓库文件。
# link_file "$repo_root/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$repo_root/cursor/mcp.json" "$HOME/.cursor/mcp.json"
link_file "$repo_root/starship/starship.toml" "$HOME/.config/starship.toml"
link_file "$repo_root/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link_herdr_plugin "$repo_root/herdr/plugins/auto-approve"

# 3. 目录：先 adopt 宿主已有内容，再 symlink 到仓库目录。
adopt_and_link_dir "$repo_root/agents" "$HOME/.agents"
adopt_and_link_dir "$repo_root/codex" "$HOME/.codex"
adopt_and_link_dir "$repo_root/claude" "$HOME/.claude"

adopt_and_link_dir "$repo_root/ghostty" "$HOME/.config/ghostty"
adopt_and_link_dir "$repo_root/yazi" "$HOME/.config/yazi"
adopt_and_link_dir "$repo_root/neovim" "$HOME/.config/nvim"

if [ "$created_backup_root" -eq 0 ]; then
  printf 'No backups created.\n'
else
  printf 'Backups stored under %s\n' "$backup_root"
fi
