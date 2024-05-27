packadd! matchit
call plug#begin('~/.vim/plugged')
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'kana/vim-submode'
  Plug 'morhetz/gruvbox'
  Plug 'sheerun/vim-polyglot'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  " Plug 'tpope/vim-unimpaired'
  " Plug 'vim-airline/vim-airline'
  " Plug 'vim-airline/vim-airline-themes'
  Plug '~/myfiler'
call plug#end()


set belloff=all
set backspace=indent,eol,start
set ttimeoutlen=1
set nowrap
set encoding=utf8
set ambiwidth=double

set history=200
set viminfo='1000,<0,h

" set lazyredraw
" set shellslash


" indent & tab options
set smartindent expandtab tabstop=2 shiftwidth=2 softtabstop=0

" guiding item optinos
set number cursorline laststatus=2 showcmd

nnoremap Y y$
" nnoremap <silent> [q       :cprevious<CR>
" nnoremap <silent> [[q      :cpfile<CR>
" nnoremap <silent> ]q       :cnext<CR>
" nnoremap <silent> ]]q      :cnfile<CR>
" nnoremap <silent> []q      :copen<CR>
" nnoremap <silent> ][q      :cclose<CR>
" nnoremap <silent> ][h      :helpclose<CR>

function! ImeOff()
  silent !im-select com.apple.keylayout.ABC
endfunction

if !has('gui_running')
  " Change the cursor shape depending on modes
  let &t_SI = "\e[5 q"
  let &t_EI = "\e[1 q"
  let &t_SR = "\e[4 q"
  augroup cmdline_cursor
    autocmd!
    autocmd CmdlineEnter             * :call echoraw(&t_SI)
    autocmd CmdlineLeave,CmdwinEnter * :call echoraw(&t_EI)
  augroup END

  augroup auto_ime_off
    autocmd!
    autocmd ModeChanged *:n :call ImeOff()
    autocmd FocusGained * :if mode() ==# 'n' | call ImeOff() | endif
  augroup END
endif


" search behavior
set ignorecase smartcase incsearch hlsearch wrapscan
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap <silent> <Esc> :nohlsearch<CR>
" selected string search (using z register)
vnoremap <silent> * "zy:let @/ = @z<CR>nzz
vnoremap <silent> # "zy:let @/ = @z<CR>Nzz


" Emacs-like key bindings in insert/cmdline mode
noremap! <C-b> <Left>
noremap! <C-f> <Right>
noremap! <C-a> <Home>
noremap! <C-e> <End>
noremap! <C-h> <BS>
noremap! <C-d> <Delete>


function! FindFile()
  let dir = &filetype == 'myfiler' ? expand('%') : getcwd()
  call fzf#vim#files(dir, fzf#vim#with_preview())
endfunction


function! RipGrep()
  let str = input('grep: ')
  if !empty(str)
    let rg_cmd = 'rg --line-number --no-heading --color=always --smart-case -- ' . str
    let dir = &filetype == 'myfiler' ? expand('%') : getcwd()
    let fzf_param = fzf#vim#with_preview({'dir': dir, 'options': '--reverse --nth 3..'})
    call fzf#vim#grep(rg_cmd, fzf_param)
  endif
endfunction


function! LaunchExplorer()
  if &filetype ==# 'myfiler'
    " if g:is_windows
    "   execute "!start" shellescape(expand('%'))
    " endif
  else
    let basename = expand('%:t')
    let pattern = '^.\{22\}' . basename . '$'
    call myfiler#open(expand('%:p:h'))
    call search(pattern)
  endif
endfunction


function! LaunchTerminal()
    let dir = &filetype ==# 'myfiler' ? expand('%') : getcwd()
    let bufnr = term_start(&shell, #{ term_finish: 'close', cwd: dir })
    call setbufvar(bufnr, "&buflisted", 0)
endfunction


function! SaveAndDo()
  write
  if &filetype ==# 'vim'
    try
      source %
    catch /^Vim\%((\a\+)\)\=:E127:/
    endtry
  endif
endfunction


let mapleader = "\<Space>"

nnoremap <silent> <Leader>w :call SaveAndDo()<CR>
nnoremap <silent> <Leader>b :Buffers<CR>
nnoremap <silent> <Leader>h :History<CR>
nnoremap <silent> <Leader>: :History:<CR>
nnoremap <silent> <Leader>/ :History/<CR>
nnoremap <silent> <Leader>H :Helptag<CR>
nnoremap <silent> <Leader>e :call LaunchExplorer()<CR>
nnoremap <silent> <Leader>f :call FindFile()<CR>
nnoremap <silent> <Leader>g :call RipGrep()<CR>
nnoremap <silent> <Leader>t :call LaunchTerminal()<CR>


call submode#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
call submode#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>+')
call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>-')
call submode#map('winsize', 'n', '', '>', '<C-w>>')
call submode#map('winsize', 'n', '', '<', '<C-w><')
call submode#map('winsize', 'n', '', '+', '<C-w>+')
call submode#map('winsize', 'n', '', '-', '<C-w>-')
let g:submode_timeoutlen=2000
let g:submode_always_show_submode=1


syntax enable
set background=dark
colorscheme gruvbox

if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
