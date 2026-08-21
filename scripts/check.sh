#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/managed_block.sh"

status=0

# 单文件 symlink 校验：检查宿主路径是否指回仓库文件。
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

# 仓库接管目录校验：这里只验证“是否已经切到仓库目录”，
# 不再重复检查 adopt 之前的迁移过程。
check_dir_link() {
  local source_dir="$1"
  local target_dir="$2"

  if [ ! -d "$source_dir" ]; then
    printf 'MISSING SOURCE %s\n' "$source_dir"
    status=1
    return
  fi

  if [ -L "$target_dir" ] && [ "$(readlink "$target_dir")" = "$source_dir" ]; then
    printf 'OK %s\n' "$target_dir"
    return
  fi

  printf 'DIFF %s\n' "$target_dir"
  status=1
}

# 入口文件托管块校验：宿主文件必须存在，并且受控 block 内容要精确匹配。
check_managed_block() {
  local target_path="$1"
  local block_body="$2"

  if [ ! -f "$target_path" ] || [ -L "$target_path" ]; then
    printf 'DIFF %s\n' "$target_path"
    status=1
    return
  fi

  if managed_block_matches "$target_path" "$block_body"; then
    printf 'OK %s\n' "$target_path"
    return
  fi

  printf 'DIFF %s\n' "$target_path"
  status=1
}

# 和 bootstrap 保持同样的 body 生成规则，避免“写入逻辑”和“校验逻辑”分叉。
build_shell_source_block_body() {
  local repo_file="$1"

  printf 'HZHT_CONFIG_ROOT="%s"\n' "$repo_root"
  printf 'source "$HZHT_CONFIG_ROOT/%s"' "$repo_file"
}

build_tmux_source_block_body() {
  local repo_file="$1"

  printf 'source-file "%s/%s"' "$repo_root" "$repo_file"
}

check_shell_source_block() {
  local target_path="$1"
  local repo_file="$2"

  check_managed_block "$target_path" "$(build_shell_source_block_body "$repo_file")"
}

check_tmux_source_block() {
  local target_path="$1"
  local repo_file="$2"

  check_managed_block "$target_path" "$(build_tmux_source_block_body "$repo_file")"
}

if [ -d "$repo_root/references/theniceboy-config" ]; then
  printf 'OK %s\n' "$repo_root/references/theniceboy-config"
else
  printf 'MISSING REFERENCE %s\n' "$repo_root/references/theniceboy-config"
  status=1
fi

# 1. 入口文件：校验 managed block。
check_shell_source_block "$HOME/.zshrc" ".zshrc"
check_shell_source_block "$HOME/.zprofile" ".zprofile"
check_shell_source_block "$HOME/.zshenv" ".zshenv"
check_tmux_source_block "$HOME/.tmux.conf" ".tmux.conf"

# 2. 单文件：校验 symlink。
check_link "$repo_root/cursor/mcp.json" "$HOME/.cursor/mcp.json"
check_link "$repo_root/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# 3. 仓库接管目录：校验 symlink。
check_dir_link "$repo_root/agents" "$HOME/.agents"
check_dir_link "$repo_root/codex" "$HOME/.codex"
check_dir_link "$repo_root/claude" "$HOME/.claude"
check_dir_link "$repo_root/ghostty" "$HOME/.config/ghostty"
check_dir_link "$repo_root/yazi" "$HOME/.config/yazi"

exit "$status"
