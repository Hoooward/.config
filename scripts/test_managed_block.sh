#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/scripts/lib/managed_block.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file_equals() {
  local expected="$1"
  local actual_path="$2"
  local actual

  actual="$(cat "$actual_path")"
  if [ "$actual" != "$expected" ]; then
    printf 'Expected:\n%s\n' "$expected" >&2
    printf 'Actual:\n%s\n' "$actual" >&2
    fail "content mismatch for $actual_path"
  fi
}

test_creates_block_in_new_file() {
  local file="$tmp_root/new.zshrc"
  local expected

  upsert_managed_block "$file" "source /repo/.zshrc"
  expected="$(render_managed_block "source /repo/.zshrc")"
  assert_file_equals "$expected" "$file"
}

test_appends_block_without_touching_user_content() {
  local file="$tmp_root/existing.zshrc"
  local expected

  printf 'export FOO=bar\nalias ll="ls -la"\n' >"$file"
  upsert_managed_block "$file" "source /repo/.zshrc"

  expected="$(cat <<'EOF'
export FOO=bar
alias ll="ls -la"

# >>> hzht-config start >>>
source /repo/.zshrc
# <<< hzht-config end <<<
EOF
)"
  assert_file_equals "$expected" "$file"
}

test_replaces_existing_block_in_place() {
  local file="$tmp_root/replace.zshrc"
  local expected

  cat >"$file" <<'EOF'
export FOO=bar
# >>> hzht-config start >>>
source /old/.zshrc
# <<< hzht-config end <<<
alias gs="git status"
EOF

  upsert_managed_block "$file" "source /new/.zshrc"

  expected="$(cat <<'EOF'
export FOO=bar
# >>> hzht-config start >>>
source /new/.zshrc
# <<< hzht-config end <<<
alias gs="git status"
EOF
)"
  assert_file_equals "$expected" "$file"
}

test_match_requires_exact_body() {
  local file="$tmp_root/match.zshrc"

  upsert_managed_block "$file" "source /repo/.zshrc"

  managed_block_matches "$file" "source /repo/.zshrc" ||
    fail "expected exact managed block match"

  if managed_block_matches "$file" "source /other/.zshrc"; then
    fail "unexpected match for different managed block body"
  fi
}

test_repeated_upsert_is_idempotent() {
  local file="$tmp_root/idempotent.zshrc"
  local first second

  printf 'alias v="nvim"\n' >"$file"
  upsert_managed_block "$file" "source /repo/.zshrc"
  first="$(cat "$file")"

  upsert_managed_block "$file" "source /repo/.zshrc"
  second="$(cat "$file")"

  if [ "$first" != "$second" ]; then
    fail "repeated upsert changed file contents"
  fi
}

test_supports_multiline_block_body() {
  local file="$tmp_root/tmux.conf"
  local expected

  upsert_managed_block "$file" "set -g mouse on
source-file /repo/.tmux.conf"

  expected="$(cat <<'EOF'
# >>> hzht-config start >>>
set -g mouse on
source-file /repo/.tmux.conf
# <<< hzht-config end <<<
EOF
)"
  assert_file_equals "$expected" "$file"
}

test_supports_custom_block_id_when_needed() {
  local file="$tmp_root/custom.zshrc"
  local expected

  upsert_managed_block "$file" "source /repo/custom.zshrc" "hzht-config custom"
  expected="$(render_managed_block "source /repo/custom.zshrc" "hzht-config custom")"
  assert_file_equals "$expected" "$file"
}

test_creates_block_in_new_file
test_appends_block_without_touching_user_content
test_replaces_existing_block_in_place
test_match_requires_exact_body
test_repeated_upsert_is_idempotent
test_supports_multiline_block_body
test_supports_custom_block_id_when_needed

printf 'PASS managed_block tests\n'
