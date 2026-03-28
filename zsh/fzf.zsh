# fzf
source <(fzf --zsh)

export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export FZF_COMPLETION_TRIGGER='\'

export FZF_DEFAULT_OPTS='--height 60% --tmux bottom,60% --layout reverse --border top --preview "[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500"'
