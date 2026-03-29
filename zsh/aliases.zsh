# 通用 alias 放这里。
# 只保留适合多设备复用的快捷命令。
alias l='ls -la'
alias t='tmux'
alias ta='tmux a'
alias reloadzsh='source ~/.zshrc'
alias tmuxconfig='vim ~/.tmux.conf'
alias zshconfig='vim ~/.zshrc'
alias vim='nvim'
alias vi='nvim'
alias yz='yazi'
alias lg='lazygit'

# 默认代理命令放在公共配置里。
# 本机如果要改端口或协议，直接在宿主 ~/.zshrc 里重定义这些 alias 即可。
# 示例：
# alias proxy='export https_proxy=http://127.0.0.1:7890; export http_proxy=http://127.0.0.1:7890; export all_proxy=socks5://127.0.0.1:7891'
alias proxy='export https_proxy=http://127.0.0.1:6152; export http_proxy=http://127.0.0.1:6152; export all_proxy=http://127.0.0.1:1086'
alias unproxy='unset all_proxy http_proxy https_proxy'
alias ip='curl cip.cc'
