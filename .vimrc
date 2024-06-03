packadd! matchit
call plug#begin('~/.vim/plugged')
  Plug 'itchyny/lightline.vim'
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'kana/vim-submode'
  Plug 'mhinz/vim-startify'
  Plug 'morhetz/gruvbox'
  " Plug 'sheerun/vim-polyglot'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  " Plug 'tpope/vim-unimpaired'
  " Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug '~/myfiler'
call plug#end()

if exists('g:plugs["vim-startify"]')
  let g:startify_change_to_dir = 0

  augroup for_startify
    autocmd!

    " See doc: startify-faq-05
    autocmd User Startified setlocal buftype=nofile

    " See doc: startify-faq-17
    autocmd BufWinEnter *
        \ if !exists('t:startify_new_tab')
        \     && empty(expand('%'))
        \     && empty(&l:buftype)
        \     && &l:modifiable |
        \   let t:startify_new_tab = 1 |
        \   Startify |
        \ endif
    " Prevent opening cmdwin just after VimEnter from kicking Startify
    autocmd VimEnter * let t:startify_new_tab = 1
  augroup END
endif

if exists('g:plugs["lightline.vim"]')
  set noshowmode

  let g:lightline = #{ colorscheme: 'gruvbox' }
  let g:lightline.component = #{
      \ cursorinfo: 'L:%4l/%L  C:%2v' }
  let g:lightline.component_function = #{
      \ buffer: 'LightlineBuffer' }
  let g:lightline.active = #{
      \ left:  [['mode', 'paste'], ['readonly', 'buffer', 'modified']],
      \ right: [['cursorinfo'], [ 'fileformat', 'fileencoding', 'filetype']] }
  let g:lightline.inactive = #{
      \ left:  [['buffer']],
      \ right: [['cursorinfo']] }
  let g:lightline.tab_component_function = #{
      \ tcd: 'LightlineTabCurrentDirectory' }
  let g:lightline.tabline = #{
      \ left:  [['tabs']],
      \ right: [] }
  let g:lightline.tab = #{
      \ active:   ['tabnum', 'tcd'],
      \ inactive: ['tabnum', 'tcd'] }

  function! LightlineTabCurrentDirectory(tabpagenr)
    return gettabvar(a:tabpagenr, 'current_directory', getcwd())
  endfunction

  function! LightlineBuffer()
    return '[' . bufnr() . '] ' . expand('%:.')
  endfunction
endif

set belloff=all
set backspace=indent,eol,start
set ttimeoutlen=1
set nowrap
set scrolloff=2
set encoding=utf8
set ambiwidth=double

set history=1000
set viminfo='1000,<0,h

" set lazyredraw
" set shellslash


" indent & tab options
set smartindent expandtab tabstop=2 shiftwidth=2 softtabstop=0

" guiding item optinos
set number cursorline laststatus=2 showcmd showtabline=2

nnoremap Y y$
nnoremap <silent> [q       :cprevious<CR>zz
nnoremap <silent> ]q       :cnext<CR>zz
" nnoremap <silent> [[q      :cpfile<CR>
" nnoremap <silent> ]]q      :cnfile<CR>
" nnoremap <silent> []q      :copen<CR>
" nnoremap <silent> ][q      :cclose<CR>
" nnoremap <silent> ][h      :helpclose<CR>

let g:normal_input_method = 'com.apple.keylayout.ABC'
function! ImeOff()
  if mode() ==# 'n'
    \ && trim(system('im-select')) != g:normal_input_method
    call system('im-select ' . g:normal_input_method)
  endif
endfunction

if !has('gui_running')
  " Change the cursor shape depending on modes
  let &t_SI = "\e[5 q"
  let &t_EI = "\e[1 q"
  let &t_SR = "\e[4 q"
  augroup cmdline_cursor
    autocmd!
    autocmd CmdlineEnter             * call echoraw(&t_SI)
    autocmd CmdlineLeave,CmdwinEnter * call echoraw(&t_EI)
  augroup END

  augroup auto_ime_off
    autocmd!
    autocmd ModeChanged *:n call ImeOff()
    autocmd FocusGained *   call ImeOff()
  augroup END
endif

augroup my_autocmds
  autocmd!

  " auto source
  autocmd BufWritePost * ++nested if &ft ==# 'vim' | source % | endif

  " Keep tab-local current directory
  autocmd DirChangedPre * call SaveTcd()
  autocmd DirChanged * call RestoreTcd()
augroup END

function! SaveTcd()
  let tabpagenr = tabpagenr()
  noautocmd tabdo let t:current_directory = getcwd()
  noautocmd execute 'normal! ' . tabpagenr . 'gt'
endfunction

function! RestoreTcd()
  let new_cwd = getcwd()
  let tabpagenr = tabpagenr()
  noautocmd tabdo execute 'tcd ' . t:current_directory
  noautocmd execute 'normal! ' . tabpagenr . 'gt'
  noautocmd execute 'tcd ' . new_cwd
  let t:current_directory = new_cwd
endfunction

" search behavior
set ignorecase smartcase incsearch hlsearch wrapscan
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap <silent> <Esc> :nohlsearch<CR>
" Search selected string (using z register)
vnoremap <silent> * "zy:let @/ = @z<CR>nzz
vnoremap <silent> # "zy:let @/ = @z<CR>Nzz
nnoremap <C-]> <C-]>zz


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
    let fzf_param = fzf#vim#with_preview({ 'dir': dir, 'options': '--reverse --nth 3..' })
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
    call myfiler#open(expand('%:p:h'))
    for lnum in range(1, line('$'))
      if myfiler#get_basename(lnum) == basename
        execute lnum
        break
      endif
    endfor
  endif
endfunction


function! LaunchTerminal()
    let dir = &filetype ==# 'myfiler' ? expand('%') : getcwd()
    let bufnr = term_start(&shell, #{ term_finish: 'close', cwd: dir })
    call setbufvar(bufnr, "&buflisted", 0)
endfunction


function! BuffersReverse()
  let fzf_param = fzf#vim#with_preview({ 'options': ['--reverse'] })
  call fzf#vim#buffers(fzf_param, 0)
endfunction


let mapleader = "\<Space>"
nnoremap <silent> <Leader>w :write<CR>
nnoremap <silent> <C-n>     :call BuffersReverse()<CR>
nnoremap <silent> <Leader>h :History<CR>
nnoremap <silent> <Leader>: :History:<CR>
nnoremap <silent> <Leader>/ :History/<CR>
nnoremap <silent> <Leader>H :Helptag<CR>
nnoremap <silent> <Leader>e :call LaunchExplorer()<CR>
nnoremap <silent> <Leader>f :call FindFile()<CR>
nnoremap <silent> <Leader>g :call RipGrep()<CR>
nnoremap <silent> <Leader>t :call LaunchTerminal()<CR>


call submode#enter_with('winsize', 'n', '', '<C-w>>', '2<C-w>>')
call submode#enter_with('winsize', 'n', '', '<C-w><', '2<C-w><')
call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>+')
call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>-')
call submode#map('winsize', 'n', '', '>', '2<C-w>>')
call submode#map('winsize', 'n', '', '<', '2<C-w><')
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
