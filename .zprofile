# 如果本机安装了 Homebrew，就让 brew 输出当前机器应该设置的环境变量，
# 再在当前 login shell 中执行这些 export。
# 这样无论是 Apple Silicon 还是 Intel Mac，都能得到正确的 PATH 和 HOMEBREW_*。
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
