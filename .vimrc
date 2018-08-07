call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tpope/vim-commentary'
    Plug 'godlygeek/tabular'
    Plug 'kanazawak/vaffle.vim'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'
    Plug 'mileszs/ack.vim'
    Plug 'flazz/vim-colorschemes'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'tpope/vim-fugitive'
call plug#end()

set backspace=indent,eol,start

syntax enable

set number
set cursorline
set smartindent
set laststatus=2
set showcmd

" tab options
set expandtab tabstop=4 shiftwidth=4 softtabstop=0

" search options
set ignorecase smartcase incsearch hlsearch

set visualbell t_vb=

set history=1000
set viminfo='1000,<0,h

set complete+=k

set encoding=utf8
set ambiwidth=double

set diffopt+=vertical

set lazyredraw

nnoremap Y y$
nnoremap <silent> [q       :cprevious<CR>
nnoremap <silent> [[q      :cpfile<CR>
nnoremap <silent> ]q       :cnext<CR>
nnoremap <silent> ]]q      :cnfile<CR>
nnoremap <silent> []q      :copen<CR>
nnoremap <silent> ][q      :cclose<CR>
nnoremap <silent> ][h      :helpclose<CR>
nnoremap <silent> <Space>r :call ExecuteThisFile()<CR>
nnoremap <silent> <Space>s :call StartShell()<CR>
nnoremap <silent> <Space>e :call StartExplorer()<CR>
nnoremap <silent> <Space>l :call StartLauncher()<CR>
nnoremap <silent> <Space>m :call ShowBookmark()<CR>
nnoremap <silent> <Space>h :History<CR>
nnoremap <silent> <Space>b :Buffers<CR>
nnoremap <silent> <Space>: :History:<CR>

let g:is_windows = has('win32') || has ('win64')

" File Explorer
function! StartExplorer()
    if &filetype ==# 'vaffle'
        if g:is_windows
            execute "!start" shellescape(expand('%'))
        endif
    else
        let path = expand('%:p')
        let basename = expand("%:t")
        execute 'edit' expand("%:p:h")
        if basename =~# '\v^\.'
            execute "normal \<Plug>(vaffle-toggle-hidden)"
        endif
        call SearchPath(path)
    endif
endfunction

augroup vaffle_config
    autocmd!
    autocmd FileType vaffle silent! call s:vaffle_init()
augroup END

let g:vaffle_use_default_mappings = 1
function! s:vaffle_init()
    unmap <buffer> <Space>
    unmap <buffer> m
    unmap <buffer> i
    unmap <buffer> q
    nmap     <silent><buffer><nowait> Q     <Plug>(vaffle-quit)
    nmap     <silent><buffer><nowait> <Tab> <Plug>(vaffle-toggle-current)
    nmap     <silent><buffer><nowait> o     <Plug>(vaffle-new-file)
    nmap     <silent><buffer><nowait> O     <Plug>(vaffle-mkdir)
    nnoremap <silent><buffer><nowait> l     :call GoForward()<CR>
    nnoremap <silent><buffer><nowait> <CR>  :call OpenCursorItem()<CR>
    nnoremap <silent><buffer><nowait> a     :call AddBookmark()<CR>
    nnoremap <silent><buffer><nowait> mp    :call OperateFileBetweenWindow('move', 'put')<CR>
    nnoremap <silent><buffer><nowait> mo    :call OperateFileBetweenWindow('move', 'obtain')<CR>
    nnoremap <silent><buffer><nowait> cp    :call OperateFileBetweenWindow('copy', 'put')<CR>
    nnoremap <silent><buffer><nowait> co    :call OperateFileBetweenWindow('copy', 'obtain')<CR>
    nnoremap <silent><buffer><nowait> s     :call ChangeSortOrder()<CR>
    nnoremap <silent><buffer><nowait> gy    :call EnterCopyMoveMode('copy')<CR>
    nnoremap <silent><buffer><nowait> gx    :call EnterCopyMoveMode('move')<CR>
    nnoremap <silent><buffer><nowait> p     :call PasteFile()<CR>
    nnoremap <silent><buffer><nowait> <Space>f :call FindFile()<CR>
    nnoremap <silent><buffer><nowait> <Space>g :call Rg()<CR>

    let b:vaffle_sorter = 'default'

    highlight! link VaffleSorter Keyword
    syntax match VaffleCopyMove  "\v^[].*"
    highlight! link VaffleCopyMove Error
endfunction

function! RefreshVaffleWindows()
    let curr_winnr = winnr()
    windo if &filetype ==# 'vaffle' | call vaffle#refresh() | endif
    execute curr_winnr . 'wincmd w'
endfunction

function! EnterCopyMoveMode(type)
    for item in vaffle#get_cursor_items('n')
        if exists('t:copy_move') && t:copy_move.type ==# a:type && t:copy_move.path ==# item.path
            unlet t:copy_move
        else
            let t:copy_move = { 'type': a:type, 'path': item.path }
        endif
        call RefreshVaffleWindows()
    endfor
endfunction

function! PasteFile()
    if !exists('t:copy_move')
        return
    endif
    let from_path = t:copy_move.path
    let to_path = expand('%:p') . fnamemodify(t:copy_move.path, ':t')
    let to_path = CheckOperable(from_path, to_path, t:copy_move.type)
    if !empty(to_path)
        call ExecOperation(from_path, to_path, t:copy_move.type)
        unlet t:copy_move
        call RefreshVaffleWindows()
        call SearchPath(to_path)
    endif
endfunction

function! CheckOperable(from_path, to_path, type)
    if filereadable(a:to_path) || isdirectory(a:to_path)
        let basename = fnamemodify(a:to_path, ':t')
        let new_name = input('File exists. New name: ', basename)
        if empty(new_name)
            echo ' Cancelled.'
            return ''
        endif
        return CheckOperable(a:from_path, fnamemodify(a:to_path, ':p:h') . '/' . new_name, a:type)
    elseif a:type ==# 'copy' && isdirectory(a:from_path)
        echoerr "Can\'t copy directory."
        return ''
    endif
    return a:to_path
endfunction

function! GetIcon(item)
    " require Nerd Fonts
    if exists('t:copy_move') && t:copy_move.path == a:item.path
        return t:copy_move.type ==# 'copy' ? '' : ''
    elseif a:item.selected
        return ''
    elseif a:item.is_link
        return isdirectory(a:item.path) ? '' : ''
    else
        return isdirectory(a:item.path) ? '' : ''
    endif
endfunction

function! g:VaffleCreateLineFromItem(item) abort
    let time = strftime("%y/%m/%d %H:%M ", getftime(a:item.path))
    if a:item.is_dir
        let size = len(glob(a:item.path . '/*', 0, 1, 1))
    else
        let byte = getfsize(a:item.path)
        let k = 1024
        for unit in ['B', 'K', 'M', 'G', 'T']
            if byte < k
                let size = (byte * 1024 / k) . ' ' . unit
                break
            else
                let k = k * 1024
            endif
        endfor
    endif
    if a:item.index == 0
        let names_width = CalcNamesWidth()
    else
        let names_width = strdisplaywidth(getline(1)) - 26
    endif
    let name = GetLabel(a:item)
    let padding = repeat(' ', names_width - strdisplaywidth(name))
    return printf("%s %s%s%s %s",
                \ GetIcon(a:item),
                \ name,
                \ padding,
                \ printf("%7s", size),
                \ time)
endfunction

function! GetLabel(item) abort
    return printf("%s%s",
        \ a:item.basename . (a:item.is_dir ? '/' : ''),
        \ a:item.is_link ? '  ' . a:item.path: '')
endfunction

function! CalcNamesWidth() abort
    let items = copy(vaffle#buffer#get_env().items)
    return max(map(items, 'strdisplaywidth(GetLabel(v:val))'))
endfunction

let g:vaffle_comparator = {
    \'default': 'vaffle#sorter#default#compare',
    \'size': { lhs, rhs ->
        \ lhs.is_dir != rhs.is_dir
        \ ? rhs.is_dir - lhs.is_dir
        \ : lhs.is_dir
        \ ? len(glob(rhs.path . '/*', 0, 1, 1)) - len(glob(lhs.path . '/*', 0, 1, 1))
        \ : getfsize(rhs.path) - getfsize(lhs.path) },
    \'time': { lhs, rhs ->
        \ lhs.is_dir != rhs.is_dir
        \ ? rhs.is_dir - lhs.is_dir
        \ : getftime(rhs.path) - getftime(lhs.path) }
    \}

function! g:VaffleGetComparator()
    return g:vaffle_comparator[b:vaffle_sorter]
endfunction

function! ChangeSortOrder()
    let b:vaffle_sorter = {
        \ 'default' : 'size',
        \ 'size'    : 'time',
        \ 'time'    : 'default'
        \}[b:vaffle_sorter]

    syntax clear VaffleSorter
    if b:vaffle_sorter == 'time'
        syntax match VaffleSorter "\v.{15}$"
    elseif b:vaffle_sorter == 'size'
        syntax match VaffleSorter "\v\S+( .)?\ze.{16}$"
    endif
    call vaffle#refresh()
endfunction

function! SearchPath(path)
    let env = vaffle#buffer#get_env()
    for i in range(1, len(env.items))
        if env.items[i-1].path ==# a:path
            execute i
            break
        endif
    endfor
endfunction

function! OperateFile(from_winnr, to_winnr, operation)
    let curr_winnr = winnr()
    execute a:from_winnr . 'wincmd w'
    for item in vaffle#get_cursor_items('n')
        execute a:to_winnr . 'wincmd w'
        let to_path = expand('%:p') . item.basename
        let to_path = CheckOperable(item.path, to_path, a:operation)
        if !empty(to_path)
            call ExecOperation(item.path, to_path, a:operation)
            call RefreshVaffleWindows()
            call SearchPath(to_path)
        endif
    endfor
    execute curr_winnr . 'wincmd w'
endfunction

function! ExecOperation(from_path, to_path, operation)
    if a:operation ==# 'move'
        call rename(a:from_path, a:to_path)
    elseif a:operation ==# 'copy'
        let command = (g:is_windows ? '!copy' : '!cp')
        silent execute command shellescape(a:from_path) shellescape(a:to_path)
        redraw!
    end
endfunction

function! OperateFileBetweenWindow(operation, direction)
    let my_winnr = winnr()
    for other_winnr in FindOtherVaffle()
        if a:direction ==# 'put'
            call OperateFile(my_winnr, other_winnr, a:operation)
        else
            call OperateFile(other_winnr, my_winnr, a:operation)
        endif
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

let g:bookmark_file_path = $HOME . '/.vim/.bookmark'

function! AddBookmark()
    let env = vaffle#buffer#get_env()
    execute 'redir >>' g:bookmark_file_path
        echo env.dir
    redir END
    echo "added to bookmark list"
endfunction

function! ShowBookmark()
    call fzf#run({
        \ 'source': readfile(g:bookmark_file_path),
        \ 'sink': funcref('Open'),
        \ 'down': '40%'})
endfunction

function! GoForward()
    for item in vaffle#get_cursor_items('n')
        if item.is_dir
            call vaffle#open_current('')
        endif
    endfor
endfunction

function! OpenCursorItem()
    for item in vaffle#get_cursor_items('n')
        call Open(item.path)
    endfor
endfunction

if g:is_windows
    let s:target_ext = '\v^(pdf|xls[xm]?)$'
    let s:open_cmd = 'silent !start'
elseif has('mac')
    let s:target_ext = '\v^(pdf)$'
    let s:open_cmd =  'silent !open'
end

function! Open(path)
    let ext = fnamemodify(a:path, ":e")
    if !isdirectory(a:path) && ext =~# s:target_ext
        execute s:open_cmd fnameescape(a:path)
        redraw!
        return
    endif
    execute 'edit' fnameescape(a:path)
endfunction

try
    function! ExecuteThisFile()
        w
        if &filetype ==# 'vim'
            source %
        elseif expand('%:e') =~# '\v^(rb)$'
            execute '!' expand('%:p')
        endif
    endfunction
catch
endtry

function! FindFile()
    let dir = shellescape(expand('%'))
    if g:is_windows
        let dir = iconv(dir, &encoding, "cp932")
        let source = printf("rg --files --hidden %s 2> nul", dir)
    else
        let source = printf("rg --files --hidden %s", dir)
    endif
    call fzf#run({'source': source , 'sink': funcref('Open'), 'down': '40%'})
endfunction

let g:ack_mappings = {}
if g:is_windows
    let g:ackprg = 'rg_wrapper.bat'
else
    let g:ackprg = 'rg -S --vimgrep'
end

function! Rg()
    let str = input('grep: ')
    if empty(str)
        return
    endif
    execute "Ack" str fnameescape(expand('%'))
endfunction

function! StartShell()
    let dir = (&filetype ==# 'vaffle' ? expand('%') : expand('%:p:h'))
    call term_start(&shell, {'term_finish': 'close', 'cwd': dir})
endfunction

let g:launcher_file_path = $HOME . '/.vim/.launcher'

function! Launch(str)
    silent execute substitute(a:str, '^.*\t', '', '')
    redraw!
endfunction

function! StartLauncher()
    call fzf#run({
        \ 'source': readfile(g:launcher_file_path),
        \ 'sink': funcref('Launch'),
        \ 'options': '--no-multi --delimiter="\t" --nth=1',
        \ 'down': '40%'})
endfunction

if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
