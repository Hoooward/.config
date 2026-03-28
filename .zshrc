# 交互式 zsh 主入口。
# 这里不直接堆配置，而是按职责拆分后再 source，便于长期维护。
# 这里通过 zsh 自身的路径展开能力，拿到当前这个 .zshrc 文件所在目录，
# 也就是 dotfiles 仓库根目录，避免把仓库绝对路径硬编码到配置里。
# 机器专属的 zsh 内容现在直接写在宿主 ~/.zshrc 里，不再额外拆单独的本地覆盖文件。
HZHT_CONFIG_ROOT="${${(%):-%N}:A:h}"

source "$HZHT_CONFIG_ROOT/zsh/env.zsh"
source "$HZHT_CONFIG_ROOT/zsh/aliases.zsh"
source "$HZHT_CONFIG_ROOT/zsh/plugins.zsh"

export PATH="$HOME/.local/bin:$PATH"