export PATH=$HOME/bin:$PATH

setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups

HISTSIZE=10000
SAVEHIST=10000
setopt share_history
setopt append_history
setopt inc_append_history
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt hist_lex_words


# vim-like behavior
bindkey -v
bindkey -v '^b' vi-backward-char
bindkey -v '^f' vi-forward-char
bindkey -v '^h' backward-delete-char
bindkey -v '^d' vi-delete-char
bindkey -v '^p' up-line-or-history
bindkey -v '^n' down-line-or-history

export KEYTIMEOUT=1

autoload -U colors && colors

function zle-line-init zle-keymap-select {
  case $KEYMAP in
    vicmd )
      echo -ne '\e[1 q'
      mode="$fg[cyan][NORMAL]"
    ;;
    viins|main )
      echo -ne '\e[5 q'
      mode="$fg[yellow][INSERT]"
    ;;
  esac
  PS1="$mode$reset_color %d
 %% "
  PS2="> "
  zle reset-prompt
}
zle -N zle-line-init
zle -N zle-keymap-select


# fzf
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --hidden --type f'
export FZF_DEFAULT_OPTS="--ambidouble"


# bat
export BAT_THEME=gruvbox-dark
