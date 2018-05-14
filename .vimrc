call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tomtom/tcomment_vim'
    Plug 'vim-airline/vim-airline'
    Plug 'justinmk/vim-dirvish'
    " Plug 'cocopon/vaffle.vim'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
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

set smartcase
set incsearch
set hlsearch

set visualbell t_vb=

set history=1000

" File Explorer
let s:file_explorer_command = 'Dirvish'
let s:file_explorer_file_type = tolower(s:file_explorer_command)
function! StartExplorer()
    if (has('win32') || has ('win64')) && &filetype ==# s:file_explorer_type
        execute "!start" expand("%")
    else
        execute s:file_explorer_command expand("%:p:h")
        norm gg
    endif
endfunction
noremap <silent> <Space>e :call StartExplorer()<CR>

function! s:dirvish_init()
    nmap <buffer> h <Plug>(dirvish_up)
    nmap <buffer> l <CR>
    nmap <buffer> <Esc> <Plug>(dirvish_quit)
    if !empty(maparg('q', 'n')) | unmap <buffer> q | endif
endfunction

let g:dirvish_mode = ':sort ,^.*[\/],'
augroup dirvish_config
    autocmd!
    autocmd FileType dirvish silent! call s:dirvish_init()
augroup END

let g:loaded_zip = 1
let g:loaded_zipPlugin = 1

if has('win32') || has ('win64')
    function! ExecAssocApp(path)
        execute "!start" a:path
    endfunction

    augroup open_nontext_file
        autocmd!
        autocmd BufReadCmd *.pdf, *.xlsx, *xlsm, *.docx
            \call ExecAssocApp(shellescape(expand("<afile>")))
    augroup END
endif

try
    function! ExecuteThisFile()
        w
        if &filetype ==# 'vim'
            source %
        else
            !%
        endif
    endfunction
catch
endtry
nnoremap <Space>r :call ExecuteThisFile()<CR>

function! s:find_file()
    if &filetype ==# s:file_explorer_file_type
        FZF %
    else
        FZF
    endif
endfunction
command! FindFile call s:find_file()
nnoremap <Space>f :FindFile<CR>

function! s:find_dir()
    if has('win32') || has ('win64')
        let cmd = 'dir'
        let opt = '/b /s/ ad'
    else
        let cmd = 'find'
        let opt = '-type d'
    endif

    if &filetype ==# s:file_explorer_file_type
        let dir = expand("%:p:h")
    else
        let dir = '.'
    end

    call fzf#run({
        \ 'source': join([cmd, dir, opt], ' '),
        \ 'sink': s:file_explorer_command,
        \ 'down': '40%',
        \})
endfunction
command! FindDir call s:find_dir()
nnoremap <Space>d :FindDir<CR>

nnoremap <Space>h :History<CR>
nnoremap <Space>b :Buffers<CR>
nnoremap <Space>: :History:<CR>

if executable('rg')
    command! -bang -nargs=* Rg
    \ call fzf#vim#grep(
    \ 'rg --line-number --no-heading '.shellescape(<q-args>), 0,
    \ fzf#vim#with_preview({'options': '--exact --reverse --delimiter : --nth 3..'}, 'right:50%:wrap'))
    nnoremap <Space>g :Rg<CR>
endif

function! s:start_shell()
    if &filetype ==# s:file_explorer_file_type
        call term_start('bash', {'term_finish': 'close', 'cwd': expand("%")})
    else
        ter
    endif
endfunction
command! StartShell call s:start_shell()
nnoremap <Space>s :StartShell<CR>
