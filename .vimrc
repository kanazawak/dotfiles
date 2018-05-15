call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tomtom/tcomment_vim'
    Plug 'vim-airline/vim-airline'
    Plug 'justinmk/vim-dirvish'
    " Plug 'cocopon/vaffle.vim'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plub 'tpope/vim-surround'
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
    if (has('win32') || has ('win64')) && &filetype ==# s:file_explorer_file_type
        execute "!start" expand("%")
    else
        execute s:file_explorer_command expand("%:p:h")
    endif
endfunction
noremap <silent> <Space>e :call StartExplorer()<CR>

let g:mode_hide_sort = 'sort ,^.*[\/], | silent keeppatterns g@\v/\.[^\/]+/?$@d _ | norm gg'
let g:mode_sort = 'sort ,^.*[\/], | norm gg'
let g:dirvish_mode = g:mode_hide_sort
augroup dirvish_config
    autocmd!
    autocmd FileType dirvish silent! call s:dirvish_init()
augroup END

nmap <Plug>(nomap-dirvish_up) <Plug>(dirvish_up)
function! s:dirvish_init()
    unmap <buffer> q
    unmap <buffer> /
    unmap <buffer> ?
    nmap <buffer> h <Plug>(dirvish_up)
    nmap <buffer> l <CR>
    nnoremap <buffer> ~ :execute 'Dirvish' expand("~")<CR>
    nmap <buffer> <Esc> <Plug>(dirvish_quit)
    nnoremap <buffer> . :call Toggle()<CR>
    nmap <buffer> m :execute "!echo" expand("%:p") . ">>" expand("~")."/.vim/.bookmark" <CR>
endfunction

function! Toggle()
    let l = line(".")
    if g:dirvish_mode ==# g:mode_sort
        let g:dirvish_mode = g:mode_hide_sort
    else
        let g:dirvish_mode = g:mode_sort
    endif
    norm R
    execute l
endfunction

let g:loaded_zip = 1
let g:loaded_zipPlugin = 1

if has('win32') || has ('win64')
    function! ExecAssocApp(path)
        execute "!start" a:path
    endfunction

    augroup open_nontext_file
        autocmd!
        autocmd BufReadCmd *.pdf,*.xls,*.xlsx,*xlsm,*.docx
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

nnoremap <Space>m :execute 'vi' expand("~")."/.vim/.bookmark"<CR>:setlocal nomodifiable<CR>:set filetype=bookmark<CR>
augroup bookmark_config
    autocmd!
    autocmd FileType bookmark silent! call s:bookmark_init()
augroup END
function! s:bookmark_init()
    nnoremap <buffer> <CR> :Dirvish <cfile> <CR>
endfunction
