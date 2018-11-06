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
        if !b:vaffle.shows_hidden_files && basename =~# '\v^\.'
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
    vmap     <silent><buffer><nowait> <Tab> <Plug>(vaffle-toggle-current)
    nmap     <silent><buffer><nowait> o     <Plug>(vaffle-new-file)
    nmap     <silent><buffer><nowait> O     <Plug>(vaffle-mkdir)
    nnoremap <silent><buffer><nowait> l     :call GoForward()<CR>
    nnoremap <silent><buffer><nowait> <CR>  :call OpenCursorItem()<CR>
    nnoremap <silent><buffer><nowait> s     :call ChangeSortOrder()<CR>
    nnoremap <silent><buffer><nowait> mv    :call OperateFile('move')<CR>
    nnoremap <silent><buffer><nowait> cp    :call OperateFile('copy')<CR>
    nnoremap <silent><buffer><nowait> <Space>f :call FindFile()<CR>
    nnoremap <silent><buffer><nowait> <Space>g :call Rg()<CR>
    nnoremap <silent><buffer><nowait> yp    :call YankPath()<CR>

    let b:vaffle_sorter = 'default'

    highlight! link VaffleSorter Keyword
endfunction

function! OperateFile(type)
    let env = vaffle#buffer#get_env()
    let sel = vaffle#get_selection()
    if empty(sel.dir) || empty(sel.dict)
        return
    endif
    for basename in keys(sel.dict)
        let from_path = fnamemodify(sel.dir, ':p') . basename
        let to_path = fnamemodify(env.dir, ':p') . basename
        if a:type ==# 'move'
            call rename(from_path, to_path)
        else
            if g:is_windows
                if isdirectory(from_path)
                    let command = 'copy'
                else
                    let command = 'xcopy'
                endif
            else
                let command = 'cp -r'
            endif
            silent execute '!' command shellescape(from_path) shellescape(to_path)
            redraw!
        endif
    endfor
    call RefreshVaffleWindows()
    call SearchPath(to_path)
endfunction

function! YankPath()
    for item in vaffle#get_cursor_items('n')
        setlocal modifiable
        call setline('.', item.path)
        normal! yy
        call vaffle#buffer#redraw_item(item)
        setlocal nomodifiable nomodified
    endfor
endfunction

function! RefreshVaffleWindows()
    let curr_winnr = winnr()
    windo if &filetype ==# 'vaffle' | call vaffle#refresh() | endif
    execute curr_winnr . 'wincmd w'
endfunction

function! GetIcon(item)
    " require Nerd Fonts
    if a:item.selected
        return ''
    elseif a:item.is_link
        return isdirectory(a:item.path) ? '' : ''
    else
        return isdirectory(a:item.path) ? '' : ''
    endif
endfunction

function! g:VaffleCreateLineFromItem(item) abort
    if a:item.is_dir
        let size = len(glob(a:item.path . '/*', 0, 1, 1))
    else
        let byte = getfsize(a:item.path)
        let k = (byte == 0 ? 0 : float2nr(log(byte) / log(1024)))
        let unit = ['B', 'K', 'M', 'G', 'T'][k]
        let x = byte / pow(1024, k)
        if k == 0 || x >= 10
            let size = float2nr(x) . ' ' . unit
        else
            let size = printf("%.1f %s", x, unit)
        endif
    endif
    let time = strftime("%y/%m/%d %H:%M ", getftime(a:item.path))
    let label = GetLabel(a:item)
    let padding = repeat(' ', LabelAreaWidth() - strdisplaywidth(label))
    return printf("%s %s%s  %s  %s",
                \ GetIcon(a:item),
                \ label,
                \ padding,
                \ printf("%6s", size),
                \ time)
endfunction

function! GetLabel(item) abort
    let label = a:item.basename
    if a:item.is_link
        let lebel = label . '  ' . a:item.path
    endif
    let limit = LabelAreaWidth()
    if strdisplaywidth(label) > limit
        while strdisplaywidth(label) > limit - 2
            let label = substitute(label, '.$', '', '')
        endwhile
        let label = label . '…'
    endif
    return label
endfunction

function! LabelAreaWidth() abort
    return 40
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
        syntax match VaffleSorter "\v\S+( .)?\ze.{17}$"
    endif
    call vaffle#refresh()
endfunction

function! SearchPath(path)
    for item in vaffle#buffer#get_env().items
        if item.path ==# a:path
            execute item.index + 1
            break
        endif
    endfor
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
    if !empty(str)
        execute "Ack" str fnameescape(expand('%'))
    endif
endfunction

function! StartShell()
    let dir = (&filetype ==# 'vaffle' ? expand('%') : expand('%:p:h'))
    call term_start(&shell, {'term_finish': 'close', 'cwd': dir})
endfunction

let g:launcher_file_path = $HOME . '/.vim/.launcher'

function! Launch(str)
    if a:str =~# '\v^[]'
        execute s:open_cmd substitute(a:str, '^.*\t', '', '')
    elseif a:str =~# '\v^[]'
        execute 'silent !' substitute(a:str, '^.*\t', '', '')
    elseif a:str =~# '\v^[]'
        execute 'silent !' g:ie_exe_path substitute(a:str, '^.*\t', '', '')
    elseif a:str =~# '\v^[]'
        execute substitute(a:str, '^.*\t', '', '')
    elseif a:str =~# '\v^[]'
        call Open(expand(a:str[4:-1]))
    endif
    nohlsearch
    redraw!
endfunction

function! StartLauncher()
    call fzf#run({
        \ 'source': readfile(g:launcher_file_path)[1:-1],
        \ 'sink': funcref('Launch'),
        \ 'options': '--no-multi --delimiter="\t" --tabstop=32 --nth=1',
        \ 'down': '40%'})
endfunction

if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
