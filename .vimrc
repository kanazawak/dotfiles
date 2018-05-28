call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tpope/vim-commentary'
    Plug 'godlygeek/tabular'
    Plug 'vim-airline/vim-airline'
    " Plug 'justinmk/vim-dirvish'
    Plug 'cocopon/vaffle.vim'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-surround'
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

set smartcase
set incsearch
set hlsearch

set visualbell t_vb=

set history=1000

nnoremap Y y$

let g:is_windows = has('win32') || has ('win64')

" File Explorer
let s:file_explorer_command = 'Vaffle'
let s:file_explorer_file_type = 'vaffle'
function! StartExplorer()
    let env = vaffle#buffer#get_env()
    if &filetype ==# s:file_explorer_file_type
        if g:is_windows
            execute "!start" env.dir
        endif
    else
        execute s:file_explorer_command expand("%:p:h")
    endif
endfunction
noremap <silent> <Space>e :call StartExplorer()<CR>

let g:vaffle_use_default_mappings = 0
augroup vaffle_config
    autocmd!
    autocmd FileType vaffle silent! call s:vaffle_init()
augroup END

let g:bookmark_file_path = $HOME . '/.vim/.bookmark'

function! s:vaffle_init()
    nnoremap <silent><buffer> h :call GoBackward()<CR>
    nnoremap <silent><buffer> l :call GoForward()<CR>
    nnoremap <silent><buffer> <CR> :call Open()<CR>
    nmap <silent><buffer> <Esc> <Plug>(vaffle-quit)
    nmap <silent><buffer> <C-^> <Plug>(vaffle-open-home)
    " nmap <buffer> a :execute "!echo" expand("%:p") . ">>" g:bookmark_file_path <CR>
    nmap <silent><buffer> b :call Bookmark()<CR>
    nmap <silent><buffer> d <Plug>(vaffle-delete-selected)
    vmap <silent><buffer> d <Plug>(vaffle-delete-selected)
    nmap <silent><buffer> <Tab> <Plug>(vaffle-toggle-current)
    nmap <silent><buffer> . <Plug>(vaffle-toggle-hidden)
    nmap <silent><buffer> ~ <Plug>(vaffle-open-home)
    nmap <silent><buffer> m <Plug>(vaffle-move-selected)
    nmap <silent><buffer> f :call FindChar(1)<CR>
    nmap <silent><buffer> F :call FindChar(-1)<CR>
    nmap <silent><buffer> ; :call RepeatFindChar(1)<CR>
    nmap <silent><buffer> , :call RepeatFindChar(-1)<CR>

    if exists("w:jumped_from")
        unlet w:jumped_from
    endif
endfunction

function! JumpToChar(direction, char)
    let items = vaffle#buffer#get_env().items
    if empty(items)
        return
    endif
    let j = line(".")
    while v:true
        let j += a:direction
        if j <= 0 || j > len(items)
            return
        end
        if items[j-1].basename[0] ==? a:char
            execute j
            break
        endif
    endwhile
endfunction

function! FindChar(direction)
    let env = vaffle#buffer#get_env()
    if empty(env.items)
        return
    endif
    let char = getchar()
    if type(char) == type(0)
        let char = nr2char(char)
    endif
    call JumpToChar(a:direction, char)
    let b:find_char_direction = a:direction
    let b:find_char_target = char
endfunction

function! RepeatFindChar(direction)
    if !exists("b:find_char_direction") || !exists("b:find_char_target")
        return
    endif
    call JumpToChar(b:find_char_direction * a:direction, b:find_char_target)
endfunction

function! GoBackward()
    if exists("w:jumped_from")
        execute "Vaffle" w:jumped_from
    else
        let env = vaffle#buffer#get_env()
        let parent_dir = fnameescape(fnamemodify(env.dir, ':h'))
        if parent_dir !=# env.dir
            execute "norm \<Plug>(vaffle-open-parent)"
        endif
    endif
endfunction

function! Bookmark()
    let temp_dir = tempname()
    call mkdir(temp_dir, 'p')
    let jumped_from = bufname('%')
    execute 'Vaffle' temp_dir
    let w:jumped_from = jumped_from
    nnoremap <buffer> l :Vaffle <cfile><CR>
    setlocal modifiable
    execute 'read' g:bookmark_file_path
    1d
    silent v/\S/d
    sort u
    execute 'w!' g:bookmark_file_path
    setlocal nomodifiable
endfunction

function! GoForward()
    let items = vaffle#buffer#get_env().items
    if empty(items)
        return
    endif
    if items[line(".")-1].is_dir
        execute "norm \<Plug>(vaffle-open-selected)"
    endif
endfunction

function! Open()
    let items = vaffle#buffer#get_env().items
    if empty(items)
        return
    endif
    let item = items[line(".")-1]
    let ext = fnamemodify(item.path, ":e")
    let associated = (match(ext, '\v^(pdf|xls[xm]?)$') >= 0)
    if g:is_windows && !item.is_dir && associated
        execute "!start" item.path
    else
        execute "norm \<Plug>(vaffle-open-selected)"
    end
endfunction

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
    let env = vaffle#buffer#get_env()
    let dir = (&filetype ==# s:file_explorer_file_type ? env.dir : getcwd())
    if g:is_windows
        let dir = iconv(dir, &encoding, "cp932")
        let source = printf("rg --files --hidden %s 2> nul", dir)
    else
        let source = printf("rg --files --hidden %s", dir)
    endif
    call fzf#run({"source": source , "sink": "edit", "down": "40%"})
endfunction
nnoremap <Space>f :call <SID>find_file()<CR>

function! s:find_dir()
    let env = vaffle#buffer#get_env()
    if g:is_windows
        let cmd = 'dir'
        let opt = '/b /s/ ad'
    else
        let cmd = 'find'
        let opt = '-type d'
    endif

    if &filetype ==# s:file_explorer_file_type
        let dir = env.dir
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

if g:is_windows
    let g:ackprg = 'rg_wrapper.bat'
else
    let g:ackprg = 'rg -S --vimgrep'
end
nnoremap <Space>g :Ack!<Space>

function! s:start_shell()
    if &filetype ==# s:file_explorer_file_type
        let env = vaffle#buffer#get_env()
        call term_start(&shell, {'term_finish': 'close', 'cwd': env.dir})
    else
        ter
    endif
endfunction
command! StartShell call s:start_shell()
nnoremap <Space>s :StartShell<CR>
