HZHT_CONFIG_ROOT="${${(%):-%N}:A:h}"

source "$HZHT_CONFIG_ROOT/zsh/env.zsh"
source "$HZHT_CONFIG_ROOT/zsh/aliases.zsh"
source "$HZHT_CONFIG_ROOT/zsh/plugins.zsh"

if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
