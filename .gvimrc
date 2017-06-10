if has("gui_running")
    set fuoptions=maxvert,maxhorz
    au GUIEnter * set fullscreen
endif

set guifont=Ricty\ Diminished\ Regular:h18
highlight CursorLine gui=underline guifg=NONE guibg=NONE
colorscheme desert

set guicursor=a:blinkon0
set guioptions-=r
set guioptions-=R
set guioptions-=l
set guioptions-=L

noremap! ¥ \
noremap! \ ¥
