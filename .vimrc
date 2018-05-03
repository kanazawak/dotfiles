call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tomtom/tcomment_vim'

    Plug 'simeji/winresizer'
    Plug 'itchyny/lightline.vim'

    Plug 'francoiscabrol/ranger.vim'
    Plug 'cocopon/vaffle.vim'

    Plug '/usr/local/opt/fzf'
    Plug 'junegunn/fzf.vim'
call plug#end()

set backspace=indent,eol,start
syntax enable
colorscheme desert
set foldmethod=syntax
set number
set cursorline
set smartindent
set laststatus=2
set showcmd

set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=0

set ignorecase
set incsearch
set hlsearch

set visualbell t_vb=

let g:winresizer_vert_resize = 1
let g:winresizer_horiz_resize = 1
nnoremap <silent> <C-w>r :WinResizerStartResize<CR>
tnoremap <silent> <C-w>r <C-w>:WinResizerStartResize<CR>

" File Explorer
nnoremap <Space>e :execute 'Vaffle' expand("%:p:h")<CR>
" nnoremap <Space>e :Ranger<CR>

" fzf
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit' }
nnoremap <Space>f :Files<CR>
nnoremap <Space>h :History<CR>
nnoremap <Space>b :Buffers<CR>
nnoremap <Space>g :Rg<CR>
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --line-number --no-heading '.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({'options': '--exact --reverse --delimiter : --nth 3..'}), <bang>0)

nnoremap <Space>r :!%
