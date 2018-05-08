call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tomtom/tcomment_vim'
    Plug 'itchyny/lightline.vim'
    Plug 'cocopon/vaffle.vim'
    Plug 'ctrlpvim/ctrlp.vim'
    Plug 'mileszs/ack.vim'
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

" File Explorer
function! StartExplorer()
    if (has('win32') || has ('win64')) && &filetype ==# 'vaffle'
        execute "!start" split(expand("%"), '/')[3]
    else
        execute "Vaffle" expand("%:p:h")
    endif
endfunction
noremap <Space>e :call StartExplorer()<CR>

let g:loaded_zip = 1
let g:loaded_zipPlugin = 1

if has('win32') || has ('win64')
    function! ExecAssocApp(path)
        execute "!start" a:path
    endfunction

    augroup open_nontext_file
        autocmd!
        autocmd BufReadCmd *.pdf,*.xlsx,*.docx call ExecAssocApp(shellescape(expand("<afile>")))
    augroup END
endif

let g:ctrlp_max_height = 20
nnoremap <Space>f :CtrlPCurWD<CR>
nnoremap <Space>h :CtrlPMRU<CR>
nnoremap <Space>b :CtrlPBuffer<CR>
nnoremap <Space>g :Ack!
if executable('rg')
  let g:ctrlp_user_command = 'rg %s --files --color=never --glob ""'
  let g:ctrlp_use_caching = 0
  let g:ackprg = 'rg --vimgrep --no-heading'
endif
