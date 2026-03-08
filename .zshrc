# 交互式 zsh 主入口。
# 这里不直接堆配置，而是按职责拆分后再 source，便于长期维护。
# 这里通过 zsh 自身的路径展开能力，拿到当前这个 .zshrc 文件所在目录，
# 也就是 dotfiles 仓库根目录，避免把仓库绝对路径硬编码到配置里。
HZHT_CONFIG_ROOT="${${(%):-%N}:A:h}"

source "$HZHT_CONFIG_ROOT/zsh/env.zsh"
source "$HZHT_CONFIG_ROOT/zsh/aliases.zsh"
source "$HZHT_CONFIG_ROOT/zsh/plugins.zsh"

# 本机专属配置入口，不进入 Git。
# 适合放代理、绝对路径、公司机器差异等内容。
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
