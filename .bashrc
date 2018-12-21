set -o vi
alias vi='vim'
PS1=\\w\\$\ 

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

fcd() {
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune \
      -o -type d -print 2> /dev/null | fzf +m) &&
    cd "$dir"
}

fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

    if [ "x$pid" != "x" ]
    then
      echo $pid | xargs kill -${1:-9}
    fi
}
