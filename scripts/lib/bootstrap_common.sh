#!/usr/bin/env bash

common_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$common_dir/../.." && pwd)"
deploy_root="${HZHT_CONFIG_DEPLOY_ROOT:-$HOME/.config/hzht-config}"
stub_marker="# Managed by hzht-config. Re-run bootstrap if repo path changes."
managed_block_start="# >>> hzht-config bootstrap >>>"
managed_block_end="# <<< hzht-config bootstrap <<<"

readonly repo_root
readonly deploy_root
readonly stub_marker
readonly managed_block_start
readonly managed_block_end

readonly managed_stub_specs=(
  "$HOME/.zshrc|shell|.zshrc"
  "$HOME/.zprofile|shell|.zprofile"
  "$HOME/.zshenv|shell|.zshenv"
  "$HOME/.tmux.conf|tmux|.tmux.conf"
)

readonly managed_file_link_specs=(
  "claude/settings.json|$HOME/.claude/settings.json"
  "cursor/mcp.json|$HOME/.cursor/mcp.json"
  "ghostty/config|$HOME/.config/ghostty/config"
)

readonly managed_dir_link_specs=(
  "agents|$HOME/.agents"
)

resolve_active_root() {
  if [ "$repo_root" = "$deploy_root" ]; then
    printf '%s\n' "$repo_root"
  else
    printf '%s\n' "$deploy_root"
  fi
}

build_managed_block() {
  local active_root="$1"
  local file_type="$2"
  local repo_file="$3"

  case "$file_type" in
    shell)
      cat <<EOF
$managed_block_start
HZHT_CONFIG_ROOT="$active_root"
source "\$HZHT_CONFIG_ROOT/$repo_file"
$managed_block_end
EOF
      ;;
    tmux)
      cat <<EOF
$managed_block_start
source-file "$active_root/$repo_file"
$managed_block_end
EOF
      ;;
    *)
      printf 'Unsupported managed file type: %s\n' "$file_type" >&2
      return 1
      ;;
  esac
}
