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
    Plug 'tpope/vim-repeat'
    Plug 'mileszs/ack.vim'
call plug#end()

set backspace=indent,eol,start
syntax enable
colorscheme desert
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
    nmap <silent><buffer> a :call AddBookmark()<CR>
    nmap <silent><buffer> b :call ShowBookmark()<CR>
    nmap <silent><buffer> d <Plug>(vaffle-delete-selected)
    vmap <silent><buffer> d <Plug>(vaffle-delete-selected)
    nmap <silent><buffer> <Tab> <Plug>(vaffle-toggle-current)
    nmap <silent><buffer> . <Plug>(vaffle-toggle-hidden)
    nmap <silent><buffer> ~ <Plug>(vaffle-open-home)
    nmap <silent><buffer> mv <Plug>(vaffle-move-selected)
    nmap <silent><buffer> f :call FindChar(1)<CR>
    nmap <silent><buffer> F :call FindChar(-1)<CR>
    nmap <silent><buffer> ; :call RepeatFindChar(1)<CR>
    nmap <silent><buffer> , :call RepeatFindChar(-1)<CR>
    nmap <silent><buffer> R <Plug>(vaffle-refresh)
    nmap <silent><buffer> o <Plug>(vaffle-new-file)

    nmap <silent><buffer> mp :call MovePut()<CR>
    nmap <silent><buffer> mo :call MoveObtain()<CR>

    augroup SaveCursor
        autocmd! BufLeave <buffer> for item in CursorItem() | call vaffle#buffer#save_cursor(item) | endfor
    augroup END

    if exists("w:jumped_from")
        unlet w:jumped_from
    endif
endfunction

function! CursorItem()
    let items = vaffle#buffer#get_env().items
    if empty(items)
        return []
    else
        return [items[line(".")-1]]
    endif
endfunction

function! MoveFile(from_winnr, to_winnr)
    let curr_winnr = winnr()
    execute a:from_winnr . 'wincmd w'
    for item in CursorItem()
        execute a:to_winnr . 'wincmd w'
        let to_path = vaffle#buffer#get_env().dir . '/' . item.basename
        if filereadable(to_path) || isdirectory(to_path)
            echoerr 'File exists.'
        else
            call rename(item.path, to_path)
            call vaffle#refresh()
            call search('\V' . item.basename)
            execute a:from_winnr . 'wincmd w'
            execute item.index + 1
        endif
    endfor
    execute curr_winnr . 'wincmd w'
endfunction

function! MoveFilePut()
    let from_winnr = winnr()
    for to_winnr in FindOtherVaffle()
        call MoveFile(from_winnr, to_winnr)
    endfor
endfunction

function! MoveFileObtain()
    let to_winnr = winnr()
    for from_winnr in FindOtherVaffle()
        call MoveFile(from_winnr, to_winnr)
    endfor
endfunction

function! FindOtherVaffle()
    let wins = []
    let curr_winnr = winnr()
    for winnr in range(1, winnr('$'))
        execute winnr . 'wincmd w'
        if winnr != curr_winnr && &filetype == 'vaffle'
            call add(wins, winnr)
        endif
    endfor
    execute curr_winnr . 'wincmd w'
    return len(wins) == 1 ? wins : []
endfunction

function! JumpToChar(direction, char)
    let items = vaffle#buffer#get_env().items
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
    let char = getchar()
    if type(char) == type(0)
        let char = nr2char(char)
    endif
    call JumpToChar(a:direction, char)
    let b:find_char_direction = a:direction
    let b:find_char_target = char
endfunction

function! RepeatFindChar(direction)
    if exists("b:find_char_direction") && exists("b:find_char_target")
        call JumpToChar(b:find_char_direction * a:direction, b:find_char_target)
    endif
endfunction

function! GoBackward()
    if exists("w:jumped_from")
        execute "Vaffle" w:jumped_from
    else
        let env = vaffle#buffer#get_env()
        let parent_dir = fnameescape(fnamemodify(env.dir, ':h'))
        if parent_dir !=# env.dir
            call vaffle#open(parent_dir)
        endif
    endif
endfunction

function! AddBookmark()
    let env = vaffle#buffer#get_env()
    execute 'redir >>' g:bookmark_file_path
        echo env.dir
    redir END
    echo "added to bookmark list"
endfunction

function! ShowBookmark()
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
    for item in CursorItem()
        if item.is_dir
            call vaffle#open_current('edit')
        endif
    endfor
endfunction

function! Open()
    for item in CursorItem()
        if item.is_dir
            call vaffle#open_current('edit')
        else
            execute 'OpenFile' item.path
        endif
    endfor
endfunction

command! -nargs=1 OpenFile :call s:open_file(<f-args>)
function! s:open_file(path)
    let ext = fnamemodify(a:path, ":e")
    if g:is_windows
        if ext =~# '\v^(pdf|xls[xm]?)$'
            execute "silent !start" a:path
            redraw!
            return
        endif
    elseif has('mac')
        if ext =~# '\v^(pdf)$'
            execute "silent !open" a:path
            redraw!
            return
        endif
    end
    execute 'edit' a:path
endfunction

try
    function! ExecuteThisFile()
        w
        if &filetype ==# 'vim'
            source %
        else
            execute '!' expand("%:p")
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
    call fzf#run({"source": source , "sink": "OpenFile", "down": "40%"})
endfunction
nnoremap <Space>f :call <SID>find_file()<CR>

nnoremap <Space>h :History<CR>
nnoremap <Space>b :Buffers<CR>
nnoremap <Space>: :History:<CR>

let g:ack_mappings = {}
if g:is_windows
    let g:ackprg = 'rg_wrapper.bat'
else
    let g:ackprg = 'rg -S --vimgrep'
end
nnoremap <Space>g :Rg<Space>
command! -nargs=1 Rg call s:rg(<f-args>)
function! s:rg(str)
    if &filetype ==# s:file_explorer_file_type
        let env = vaffle#buffer#get_env()
        execute "Ack" a:str env.dir
        execute "normal \<CR>"
    else
        execute "Ack" a:str
        execute "normal \<CR>"
    endif
endfunction

nnoremap [q :cprevious<CR>
nnoremap [[q :cpfile<CR>
nnoremap ]q :cnext<CR>
nnoremap ]]q :cnfile<CR>

function! s:start_shell()
    if &filetype ==# s:file_explorer_file_type
        let env = vaffle#buffer#get_env()
        call term_start(&shell, {'term_finish': 'close', 'cwd': env.dir})
    else
        call term_start(&shell, {'term_finish': 'close', 'cwd': expand("%:p:h")})
    endif
endfunction
command! StartShell call s:start_shell()
nnoremap <Space>s :StartShell<CR>

if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
