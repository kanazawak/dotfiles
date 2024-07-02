set -o vi
alias vi='vim'
PS1=\\w\\$\ 

eval $(fzf --bash)
export FZF_DEFAULT_OPTS='--ambidouble'
export FZF_DEFAULT_COMMAND='fd --hidden --type file'

fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

    if [ "x$pid" != "x" ]
    then
      echo $pid | xargs kill -${1:-9}
    fi
}
