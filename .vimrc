set backspace=indent,eol,start
syntax on
colorscheme desert
set foldmethod=syntax
set number
set cursorline
set smartindent
set laststatus=2

set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=0

set incsearch
set hlsearch

set visualbell t_vb=

"dein Scripts-----------------------------

if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=~/.vim/bundle/repos/github.com/Shougo/dein.vim

" Required:
call dein#begin('~/.vim/bundle/')

" Let dein manage dein
" Required:
call dein#add('Shougo/dein.vim')

" plugins:
" call dein#add('Shougo/neocomplete.vim')
" call dein#add('Shougo/neosnippet.vim')
" call dein#add('Shougo/neosnippet-snippets')
call dein#add('Shougo/unite.vim')
call dein#add('Shougo/neomru.vim')
call dein#add('ujihisa/unite-colorscheme')
call dein#add('w0ng/vim-hybrid')
call dein#add('altercation/vim-colors-solarized')
call dein#add('croaker/mustang-vim')
call dein#add('nanotech/jellybeans.vim')
call dein#add('tomasr/molokai')

call dein#add('tpope/vim-endwise')
call dein#add('tomtom/tcomment_vim')
call dein#add('tpope/vim-surround')

call dein#add('Shougo/vimproc.vim', {'build' : 'make'}) 
call dein#add('Shougo/vimshell')
call dein#add('itchyny/lightline.vim')

" Required:
call dein#end()

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------

noremap <silent> <Space>ue :Unite -vertical bookmark file <CR> 
noremap <silent> <Space>um :Unite -vertical file_mru <CR>
noremap <silent> <Space>uf :Unite -start-insert file_rec/async <CR>
noremap <silent> <Space>ug :Unite grep <CR>

noremap <silent> <Space>r :! % <CR>
noremap <silent> <Space>w :w <CR>
noremap <silent> <Space>t :tabnew <CR>
noremap <silent> <Space>s :VimShell <CR>
