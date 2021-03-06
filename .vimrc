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
    Plug 'kana/vim-submode'
    Plug 'morhetz/gruvbox'
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

set noshowmode

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
" nnoremap <silent> <ESC>    :nohl<CR>

" slightly Emacs-like in insert mode or cmdline
noremap! <silent> <C-b> <Left>
noremap! <silent> <C-f> <Right>
noremap! <silent> <C-a> <Home>
noremap! <silent> <C-e> <End>
noremap! <silent> <C-d> <Delete>

call submode#enter_with('winsize', 'n', '', '<C-w>>', '<C-w>>')
call submode#enter_with('winsize', 'n', '', '<C-w><', '<C-w><')
call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>+')
call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>-')
call submode#map('winsize', 'n', '', '>', '<C-w>>')
call submode#map('winsize', 'n', '', '<', '<C-w><')
call submode#map('winsize', 'n', '', '+', '<C-w>+')
call submode#map('winsize', 'n', '', '-', '<C-w>-')
let g:submode_timeoutlen=2000
let g:submode_always_show_submode=1

" cursor shape corresponding to modes
if !has('gui_running')
    set ttimeoutlen=1
    let &t_SI = "\e[5 q"
    let &t_EI = "\e[1 q"
    let &t_SR = "\e[4 q"
    augroup cmdline_cursor
        autocmd!
        autocmd CmdlineEnter             * execute "silent !echo -n " . &t_SI
        autocmd CmdlineLeave,CmdwinEnter * execute "silent !echo -n " . &t_EI
    augroup END
endif

let g:is_windows = has('win32') || has ('win64')

function! StartExplorer()
    if &filetype ==# 'vaffle'
        if g:is_windows
            execute "!start" shellescape(expand('%'))
        endif
    else
        execute 'Vaffle' expand('%:p:h')
    endif
endfunction

let g:vaffle_use_default_mappings = 1
autocmd FileType vaffle silent! call s:vaffle_init()
function! s:vaffle_init()
    unmap <buffer> i
    nmap <buffer> o     <Plug>(vaffle-new-file)
    nmap <buffer> O     <Plug>(vaffle-mkdir)
    nmap <buffer> <ESC> <Plug>(vaffle-refresh)
    nmap <silent><buffer><nowait> d    :call vaffle#cut('n')<CR>
    vmap <silent><buffer><nowait> d    :call vaffle#cut('v')<CR>
    nmap <silent><buffer><nowait> yy   :call vaffle#copy('n')<CR>
    vmap <silent><buffer><nowait> y    :call vaffle#copy('v')<CR>
    nnoremap <silent><buffer> l        :call GoForward()<CR>
    nnoremap <silent><buffer> <CR>     :call OpenCursorItem()<CR>
    nnoremap <silent><buffer> s        :call ChangeSortOrder()<CR>
    nnoremap <silent><buffer> p        :call OperateFile()<CR>
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

function! OperateFile()
    let type = get(g:, 'vaffle_operation', '')
    if type !=# 'cut' && type !=# 'copy'
        return
    endif

    let env = vaffle#buffer#get_env()
    let sel = vaffle#get_selection()
    if empty(sel.dir) || empty(sel.basenames)
        return
    endif
    for basename in sel.basenames
        let from_path = fnamemodify(sel.dir, ':p') . basename
        let to_path = fnamemodify(env.dir, ':p') . basename
        let Func = function(type ==# 'cut' ? 'rename' : 's:copy')
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
        if get(g:, 'vaffle_operation', 'cut') ==# 'cut'
            return ''
        else
            return ''
        endif
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
    let label = a:item.label
    let padding = repeat(' ', b:vaffle.max_labeldispwidth - strdisplaywidth(label))
    return printf("%s %s%s  %s  %s", icon, label, padding, size, time)
endfunction

augroup vaffle_conceal
    autocmd!
    autocmd! BufEnter,WinEnter *
                \   if &filetype ==# 'vaffle'
                \ | call <SID>vaffle_conceal()
                \ | endif
augroup END

function! s:vaffle_conceal()
    set conceallevel=2
    set concealcursor=nvic
    ownsyntax
    let labeldispwidth_limit = winwidth(0) - 1 - 28 - 3
    let overflow = b:vaffle.max_labeldispwidth - labeldispwidth_limit
    if overflow <=0
        return
    endif
    for item in b:vaffle.items
        if strdisplaywidth(item.label) <= labeldispwidth_limit
            continue
        endif
        let w = 0
        let right = ""
        for char in split(item.label, '\zs')
            if w >= labeldispwidth_limit
                let right = right . char
            endif
            let w = w + strdisplaywidth(char)
        endfor
        let right = substitute(right, '/', '\\/', 'g')
        let space = b:vaffle.max_labeldispwidth - w
        let pat = '/\V' . right . '\v {'. (space + 2) . '}\ze.{22}$/'
        execute 'syntax match Hoge' pat 'conceal cchar=…'
    endfor
    let pat = '/\v {' . overflow . '}\ze.{24}$/'
    execute 'syntax match Hoge' pat 'conceal'
    highlight! def link Conceal Error
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
            call vaffle#open_current()
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

if filereadable(expand("~/.vimrc.local"))
    source ~/.vimrc.local
endif
