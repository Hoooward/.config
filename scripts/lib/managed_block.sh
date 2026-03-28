#!/usr/bin/env bash

managed_block_default_id="hzht-config"

resolve_managed_block_id() {
  local block_id="${1:-}"

  if [ -n "$block_id" ]; then
    printf '%s' "$block_id"
    return
  fi

  printf '%s' "$managed_block_default_id"
}

managed_block_start() {
  local block_id
  block_id="$(resolve_managed_block_id "${1:-}")"
  printf '# >>> %s start >>>' "$block_id"
}

managed_block_end() {
  local block_id
  block_id="$(resolve_managed_block_id "${1:-}")"
  printf '# <<< %s end <<<' "$block_id"
}

render_managed_block() {
  local block_body="$1"
  local block_id
  block_id="$(resolve_managed_block_id "${2:-}")"

  printf '%s\n' "$(managed_block_start "$block_id")"
  printf '%s\n' "$block_body"
  printf '%s\n' "$(managed_block_end "$block_id")"
}

has_managed_block() {
  local target_path="$1"
  local block_id
  block_id="$(resolve_managed_block_id "${2:-}")"

  [ -f "$target_path" ] &&
    grep -Fq "$(managed_block_start "$block_id")" "$target_path" &&
    grep -Fq "$(managed_block_end "$block_id")" "$target_path"
}

managed_block_matches() {
  local target_path="$1"
  local block_body="$2"
  local block_id
  local expected_block_file actual_block_file

  block_id="$(resolve_managed_block_id "${3:-}")"
  [ -f "$target_path" ] || return 1
  expected_block_file="$(mktemp)"
  actual_block_file="$(mktemp)"

  render_managed_block "$block_body" "$block_id" >"$expected_block_file"
  extract_managed_block "$target_path" "$block_id" >"$actual_block_file" || {
    rm -f "$expected_block_file" "$actual_block_file"
    return 1
  }

  cmp -s "$expected_block_file" "$actual_block_file"
  local status=$?
  rm -f "$expected_block_file" "$actual_block_file"
  return "$status"
}

extract_managed_block() {
  local target_path="$1"
  local block_id
  local start_marker end_marker

  block_id="$(resolve_managed_block_id "${2:-}")"
  start_marker="$(managed_block_start "$block_id")"
  end_marker="$(managed_block_end "$block_id")"

  [ -f "$target_path" ] || return 1

  awk -v start="$start_marker" -v end="$end_marker" '
    BEGIN {
      in_block = 0
      found = 0
    }
    $0 == start {
      in_block = 1
      found = 1
    }
    in_block == 1 {
      print
    }
    $0 == end && in_block == 1 {
      exit
    }
    END {
      if (found == 0) {
        exit 1
      }
    }
  ' "$target_path"
}

upsert_managed_block() {
  local target_path="$1"
  local block_body="$2"
  local block_id
  local start_marker end_marker tmp_file replacement_file last_char

  block_id="$(resolve_managed_block_id "${3:-}")"
  start_marker="$(managed_block_start "$block_id")"
  end_marker="$(managed_block_end "$block_id")"
  tmp_file="$(mktemp)"
  replacement_file="$(mktemp)"
  render_managed_block "$block_body" "$block_id" >"$replacement_file"

  if [ ! -e "$target_path" ]; then
    cp "$replacement_file" "$target_path"
    rm -f "$tmp_file" "$replacement_file"
    return
  fi

  if has_managed_block "$target_path" "$block_id"; then
    awk -v start="$start_marker" -v end="$end_marker" -v replacement_file="$replacement_file" '
      BEGIN {
        in_block = 0
        replaced = 0
      }
      $0 == start {
        if (replaced == 0) {
          while ((getline line < replacement_file) > 0) {
            print line
          }
          close(replacement_file)
          replaced = 1
        }
        in_block = 1
        next
      }
      $0 == end {
        in_block = 0
        next
      }
      in_block == 0 {
        print
      }
    ' "$target_path" >"$tmp_file"
  else
    cp "$target_path" "$tmp_file"
    if [ -s "$tmp_file" ]; then
      last_char="$(tail -c 1 "$tmp_file" || true)"
      if [ "$last_char" != "" ]; then
        printf '\n' >>"$tmp_file"
      fi
      printf '\n' >>"$tmp_file"
    fi
    cat "$replacement_file" >>"$tmp_file"
  fi

  mv "$tmp_file" "$target_path"
  rm -f "$replacement_file"
}
