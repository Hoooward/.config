export ZSH="$HOME/.oh-my-zsh"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export NVM_DIR="$HOME/.nvm"

# Homebrew-managed tools commonly installed on macOS machines.
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

if command -v pyenv >/dev/null 2>&1; then
  PATH="$(pyenv root)/shims:$PATH"
fi
