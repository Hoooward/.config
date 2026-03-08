export ZSH="$HOME/.oh-my-zsh"
export NVM_DIR="$HOME/.nvm"

# 这些是当前常用开发工具的环境初始化。
# 都先判断文件是否存在，再决定是否加载，避免新机器还没安装时报错。

# autojump 的 shell 集成脚本。
# 加载后可以使用 autojump 提供的跳转能力。
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# nvm 主脚本。
# 加载后才能使用 nvm / node / npm 的版本切换能力。
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"

# nvm 的补全脚本。
# 加载后 zsh 里会有 nvm 相关命令补全。
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# 如果安装了 pyenv，就把它的 shims 放到 PATH 前面。
# 这样执行 python / pip 时，会优先走 pyenv 当前选择的版本。
if command -v pyenv >/dev/null 2>&1; then
  PATH="$(pyenv root)/shims:$PATH"
fi
