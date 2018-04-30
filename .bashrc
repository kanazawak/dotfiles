set -o vi

if [ -z "$VIM_SERVERNAME" ]; then
    alias vi="vim --servername VIM"
else
    alias vi="vim --servername $VIM_SERVERNAME --remote-send '<C-w>:tabnew<CR>' && vim --servername $VIM_SERVERNAME --remote"
fi
