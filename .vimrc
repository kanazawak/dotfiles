call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tpope/vim-commentary'
    Plug 'godlygeek/tabular'
    Plug 'kanazawak/vaffle.vim'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'
    Plug 'flazz/vim-colorschemes'
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'
    Plug 'tpope/vim-fugitive'
call plug#end()

set backspace=indent,eol,start

syntax enable

" guiding item optinos
set number cursorline laststatus=2 showcmd

" indent & tab options
set smartindent expandtab tabstop=4 shiftwidth=4 softtabstop=0

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

function! StartExplorer()
    if &filetype ==# 'vaffle'
        if g:is_windows
            execute "!start" shellescape(expand('%'))
        endif
    else
        execute 'Vaffle' expand('%')
    endif
endfunction

autocmd FileType vaffle silent! call s:vaffle_init()
function! s:vaffle_init()
    unmap <buffer> <Space>
    unmap <buffer> m
    unmap <buffer> i
    nmap <buffer> <Tab> <Plug>(vaffle-toggle-current)
    vmap <buffer> <Tab> <Plug>(vaffle-toggle-current)
    nmap <buffer> o     <Plug>(vaffle-new-file)
    nmap <buffer> O     <Plug>(vaffle-mkdir)
    nnoremap <silent><buffer> l        :call GoForward()<CR>
    nnoremap <silent><buffer> <CR>     :call OpenCursorItem()<CR>
    nnoremap <silent><buffer> s        :call ChangeSortOrder()<CR>
    nnoremap <silent><buffer> mv       :call OperateFile('move')<CR>
    nnoremap <silent><buffer> cp       :call OperateFile('copy')<CR>
    nnoremap <silent><buffer> <Space>f :call FindFile()<CR>
    nnoremap <silent><buffer> <Space>g :call Rg()<CR>

    let b:vaffle_sorter = ['default', 'size', 'time']
    highlight! link VaffleSorter Keyword
endfunction

function! s:copy(from_path, to_path)
    let cmd = isdirectory(a:from_path) ? s:rec_copy_cmd : s:copy_cmd
    silent execute '!' cmd shellescape(a:from_path) shellescape(a:to_path)
    redraw!
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
        let Func = function(a:type ==# 'move' ? 'rename' : 's:copy')
        call Func(from_path, to_path)
    endfor
    if fnamemodify(to_path, ':t') =~# '^\.'
        let b:vaffle.shows_hidden_files = 1
    endif
    call RefreshVaffleWindows()
    let item = vaffle#item#create(to_path)
    call vaffle#window#save_cursor(item)
    call vaffle#window#restore_cursor()
endfunction

function! RefreshVaffleWindows()
    let curr_winnr = winnr()
    windo if &filetype ==# 'vaffle' | call vaffle#refresh() | endif
    execute curr_winnr . 'wincmd w'
endfunction

function! GetIcon(item)
    if a:item.selected
        return ''
    elseif a:item.is_link
        return isdirectory(a:item.path) ? '' : ''
    else
        return isdirectory(a:item.path) ? '' : ''
    endif
endfunction

function! FileSizePretty(byte)
    let k = (a:byte == 0 ? 0 : float2nr(log(a:byte) / log(1024)))
    let unit = 'BKMGT'[k]
    let x = a:byte / pow(1024, k)
    return k == 0 || x >= 10
        \ ? float2nr(x) . ' ' . unit
        \ : printf("%.1f %s", x, unit)
endfunction

function! g:VaffleCreateLineFromItem(item) abort
    let icon = GetIcon(a:item)
    let size = a:item.is_dir ? a:item.size : FileSizePretty(a:item.size)
    let size = printf("%6s", size)
    let time = strftime("%y/%m/%d %H:%M", a:item.ftime)
    let label = GetLabel(a:item)
    let padding = repeat(' ', LabelAreaWidth() - strdisplaywidth(label))
    return printf("%s %s%s  %s  %s", icon, label, padding, size, time)
endfunction

function! GetLabel(item) abort
    let label = a:item.basename
    if a:item.is_link
        let label .= '  ' . a:item.path
    endif
    let limit = LabelAreaWidth()
    if strdisplaywidth(label) > limit
        while strdisplaywidth(label) > limit - 2
            let label = substitute(label, '.$', '', '')
        endwhile
        let label .= '…'
    endif
    return label
endfunction

function! LabelAreaWidth() abort
    return 40
endfunction

let s:M = float2nr(pow(10, 12))
let s:vaffle_comparator = {
    \'default': 'vaffle#sorter#default#compare',
    \'size': { l, r -> (l.is_dir - r.is_dir) * s:M + r.size  - l.size  },
    \'time': { l, r -> (l.is_dir - r.is_dir) * s:M + r.ftime - l.ftime }
    \}

function! g:VaffleGetComparator()
    return s:vaffle_comparator[b:vaffle_sorter[0]]
endfunction

function! ChangeSortOrder()
    syntax clear VaffleSorter
    let b:vaffle_sorter = map([1, 2, 0], 'b:vaffle_sorter[v:val]')
    if b:vaffle_sorter[0] == 'time'
        syntax match VaffleSorter "\v.{14}$"
    elseif b:vaffle_sorter[0] == 'size'
        syntax match VaffleSorter "\v\S+( .)?\ze.{16}$"
    endif
    call vaffle#refresh()
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
    let s:copy_cmd = 'copy'
    let s:rec_copy_cmd = 'echo D | xcopy'
elseif has('mac')
    let s:target_ext = '\v^(pdf)$'
    let s:open_cmd =  'silent !open'
    let s:copy_cmd = 'cp'
    let s:rec_copy_cmd = 'cp -r'
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
    let cmd = 'fd --type file --hidden ' . shellescape(expand('%'))
    call fzf#run({'source': cmd , 'sink': funcref('Open'), 'down': '40%'})
endfunction

function! Rg()
    let str = input('grep: ')
    if !empty(str)
        call fzf#vim#grep(
            \ 'rg --vimgrep --color=always -S --no-messages ' . shellescape(str),
            \ 1, {'dir': expand('%'), 'down': '40%', 'options': '--reverse'}, 0)
    endif
endfunction

function! StartShell()
    let dir = (&filetype ==# 'vaffle' ? expand('%') : expand('%:p:h'))
    call term_start(&shell, {'term_finish': 'close', 'cwd': dir})
endfunction

let g:launcher_file_path = $HOME . '/.vim/.launcher'

function! Launch(str)
    let body = substitute(a:str, '^.*\t', '', '')
    if a:str =~# '\v^[]'
        execute s:open_cmd body
    elseif a:str =~# '\v^[]'
        if g:is_windows
            execute s:open_cmd body
        else
            execute 'silent !' body
        endif
    elseif a:str =~# '\v^[]'
        execute 'silent !' g:ie_exe_path body
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
