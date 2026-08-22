# Codex 启动器。
# xlm 选择模型和推理深度后启动 codex；权限配置沿用当前 Codex 默认值。

_xlm_fzf_select() {
  local prompt="$1"
  local header="$2"
  local selected
  local preview_cmd='awk -F "\t" -v id="{1}" '\''$1 == id { print "配置: " $2; print ""; print "命令:"; print "  " $3; print ""; print "说明:"; print "  " $4 }'\'''

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 'xlm: fzf 未安装或不在 PATH 中'
    return 1
  fi

  selected="$(fzf \
    --height 80% \
    --layout reverse \
    --border rounded \
    --border-label ' xlm ' \
    --header "$header" \
    --prompt "$prompt" \
    --delimiter $'\t' \
    --with-nth=2 \
    --no-multi \
    --preview-window 'right,55%,border-left,wrap' \
    --preview "$preview_cmd")"

  [[ -n "$selected" ]] || return 130
  print -r -- "$selected"
}

_xlm_select_model() {
  local records
  records=$'default\tdefault\tcodex\t不覆盖当前 Codex 配置中的模型和推理深度。'
  records+=$'\ngpt-5.6-medium\tGPT-5.6 Sol · medium\tcodex -m gpt-5.6 -c model_reasoning_effort=medium\t旗舰模型；适合大多数编码和专业任务。'
  records+=$'\ngpt-5.6-low\tGPT-5.6 Sol · low\tcodex -m gpt-5.6 -c model_reasoning_effort=low\t降低推理投入，适合快速迭代和常规修改。'
  records+=$'\ngpt-5.6-high\tGPT-5.6 Sol · high\tcodex -m gpt-5.6 -c model_reasoning_effort=high\t适合复杂 bug、架构取舍和多步骤任务。'
  records+=$'\ngpt-5.6-xhigh\tGPT-5.6 Sol · xhigh\tcodex -m gpt-5.6 -c model_reasoning_effort=xhigh\t适合困难任务，允许更高延迟。'
  records+=$'\ngpt-5.6-max\tGPT-5.6 Sol · max\tcodex -m gpt-5.6 -c model_reasoning_effort=max\t使用 Sol 支持的最高推理深度。'
  records+=$'\ngpt-5.6-terra-medium\tGPT-5.6 Terra · medium\tcodex -m gpt-5.6-terra -c model_reasoning_effort=medium\t平衡智能、速度和成本。'
  records+=$'\ngpt-5.6-terra-low\tGPT-5.6 Terra · low\tcodex -m gpt-5.6-terra -c model_reasoning_effort=low\t平衡模型下的快速迭代。'
  records+=$'\ngpt-5.6-luna-medium\tGPT-5.6 Luna · medium\tcodex -m gpt-5.6-luna -c model_reasoning_effort=medium\t成本敏感场景下的平衡选项。'
  records+=$'\ngpt-5.6-luna-low\tGPT-5.6 Luna · low\tcodex -m gpt-5.6-luna -c model_reasoning_effort=low\t高频、低延迟和成本敏感任务。'

  printf '%s\n' "$records" | _xlm_fzf_select 'Codex > ' '选择模型 + 推理深度；default 表示沿用当前配置'
}

xlm() {
  if ! command -v codex >/dev/null 2>&1; then
    print -u2 'xlm: codex 未安装或不在 PATH 中'
    return 1
  fi

  local model model_id
  local -a codex_args

  model="$(_xlm_select_model)" || return $?

  model_id="${model%%$'\t'*}"

  case "$model_id" in
    default) codex_args=() ;;
    gpt-5.6-medium) codex_args=(-m gpt-5.6 -c model_reasoning_effort=medium) ;;
    gpt-5.6-low) codex_args=(-m gpt-5.6 -c model_reasoning_effort=low) ;;
    gpt-5.6-high) codex_args=(-m gpt-5.6 -c model_reasoning_effort=high) ;;
    gpt-5.6-xhigh) codex_args=(-m gpt-5.6 -c model_reasoning_effort=xhigh) ;;
    gpt-5.6-max) codex_args=(-m gpt-5.6 -c model_reasoning_effort=max) ;;
    gpt-5.6-terra-medium) codex_args=(-m gpt-5.6-terra -c model_reasoning_effort=medium) ;;
    gpt-5.6-terra-low) codex_args=(-m gpt-5.6-terra -c model_reasoning_effort=low) ;;
    gpt-5.6-luna-medium) codex_args=(-m gpt-5.6-luna -c model_reasoning_effort=medium) ;;
    gpt-5.6-luna-low) codex_args=(-m gpt-5.6-luna -c model_reasoning_effort=low) ;;
    *) print -u2 "xlm: 未知模型配置: $model_id"; return 1 ;;
  esac

  command codex "${codex_args[@]}" "$@"
}
