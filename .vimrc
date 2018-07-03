call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tpope/vim-commentary'
    Plug 'godlygeek/tabular'
    Plug 'vim-airline/vim-airline'
    Plug 'kanazawak/vaffle.vim'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-repeat'
    Plug 'mileszs/ack.vim'
    Plug 'flazz/vim-colorschemes'
    Plug 'vim-airline/vim-airline-themes'
call plug#end()

set backspace=indent,eol,start

syntax enable
" colorscheme spacegray
" colorscheme landscape
" colorscheme PaperColor
colorscheme kalisi
" colorscheme desert

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
set smartcase
set incsearch
set hlsearch

set visualbell t_vb=

set history=1000
set viminfo='1000,<0,h

set complete+=k

set encoding=utf8
set ambiwidth=double

nnoremap Y y$
nnoremap j gj
nnoremap k gk

let g:is_windows = has('win32') || has ('win64')

" File Explorer
function! StartExplorer()
    if &filetype ==# 'vaffle'
        if g:is_windows
            let env = vaffle#buffer#get_env()
            execute "!start" env.dir
        endif
    else
        let basename = expand("%:t")
        execute 'Vaffle' expand("%:p:h")
        if basename =~# '\v^\.'
            execute "normal \<Plug>(vaffle-toggle-hidden)"
        endif
        let env = vaffle#buffer#get_env()
        let a = filter(copy(env.items), 'v:val.basename ==# basename')
        if !empty(a)
            execute a[0].index + 1
        endif
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
    nmap <silent><buffer> h <Plug>(vaffle-open-parent)
    nnoremap <silent><buffer> l :call GoForward()<CR>
    nnoremap <silent><buffer> <CR> :call Open()<CR>
    nmap <silent><buffer><nowait> <Esc> <Plug>(vaffle-quit)
    nmap <silent><buffer><nowait> <C-^> <Plug>(vaffle-open-home)
    nmap <silent><buffer><nowait> a :call AddBookmark()<CR>
    nmap <silent><buffer><nowait> b :call ShowBookmark()<CR>
    nmap <silent><buffer><nowait> d <Plug>(vaffle-delete-selected)
    vmap <silent><buffer><nowait> d <Plug>(vaffle-delete-selected)
    nmap <silent><buffer><nowait> <Tab> <Plug>(vaffle-toggle-current)
    nmap <silent><buffer><nowait> . <Plug>(vaffle-toggle-hidden)
    nmap <silent><buffer><nowait> ~ <Plug>(vaffle-open-home)
    nmap <silent><buffer><nowait> mv <Plug>(vaffle-move-selected)
    nmap <silent><buffer><nowait> f :call FindChar(1)<CR>
    nmap <silent><buffer><nowait> F :call FindChar(-1)<CR>
    nmap <silent><buffer><nowait> ; :call RepeatFindChar(1)<CR>
    nmap <silent><buffer><nowait> , :call RepeatFindChar(-1)<CR>
    nmap <silent><buffer><nowait> R <Plug>(vaffle-refresh)
    nmap <silent><buffer><nowait> o <Plug>(vaffle-new-file)
    nmap <silent><buffer><nowait> O <Plug>(vaffle-mkdir)
    nmap <silent><buffer><nowait> r <Plug>(vaffle-rename-selected)
    nmap <silent><buffer><nowait> mp :call OperateFileBetweenWindow('move', 'put')<CR>
    nmap <silent><buffer><nowait> mo :call OperateFileBetweenWindow('move', 'obtain')<CR>
    nmap <silent><buffer><nowait> cp :call OperateFileBetweenWindow('copy', 'put')<CR>
    nmap <silent><buffer><nowait> co :call OperateFileBetweenWindow('copy', 'obtain')<CR>
    nmap <silent><buffer><nowait> x <Plug>(vaffle-fill-cmdline)
    nmap <silent><buffer><nowait> s :call ChangeSortOrder()<CR>
    nmap <silent><buffer><nowait> p :call TogglePreview()<CR>
    nmap <silent><buffer><nowait> <C-j> :call ScrollPreview(1)<CR>
    nmap <silent><buffer><nowait> <C-k> :call ScrollPreview(-1)<CR>

    if !exists('b:vaffle_sorter_list')
        let b:vaffle_sorter_list = ['default', 'time']
    endif

    autocmd BufLeave <buffer>
        \  for item in CursorItem()
        \| call vaffle#buffer#save_cursor(item)
        \| endfor

    autocmd CursorMoved <buffer>
        \  for item in CursorItem()
        \| if Previewing()
        \| call Preview(item)
        \| endif
        \| endfor
endfunction

function! ScrollPreview(direction)
    let curr_winnr = winnr()
    if a:direction >= 0
        let command = "normal! " . a:direction . "\<C-e>"
    else
        let command = "normal! " . -a:direction . "\<C-y>"
    endif
    set eventignore=BufEnter
    windo if &previewwindow | execute command | endif
    execute curr_winnr . 'wincmd w'
    set eventignore=
endfunction

function! Any(list, predicate)
    return !empty(filter(a:list, a:predicate))
endfunction

function! Previewing()
    return Any(range(1, winnr('$')), 'getwinvar(v:val, "&previewwindow") == 1')
endfunction

augroup VaffleAutoCommands
    autocmd!
    autocmd BufEnter * if !&previewwindow | doautocmd filetypedetect BufRead | endif
    autocmd BufEnter *
        \  if !Any(tabpagebuflist(), 'getbufvar(v:val, "&filetype") ==# "vaffle"')
        \| pclose
        \| endif
    autocmd User VaffleRedrawPost if !&previewwindow | call Align() | endif
augroup END

function! Align()
    if search("\t") > 0
        Tabularize/\t/l0r0r0
        %s/\t/  /g
    endif
endfunction

function! Preview(item)
    set eventignore=WinNew,BufEnter,BufLeave
    let limit = 1024 * 1024
    if getfsize(a:item.path) >= limit
        execute printf('pedit +call\ PreviewLargeFileCallback() %s', tempname())
    elseif buflisted(a:item.path)
        execute 'pedit +setlocal\ nocursorline' a:item.path
    else
        execute printf('pedit +call\ PreviewCallback() %s', a:item.path)
    endif
    set eventignore=
endfunction

function! PreviewLargeFileCallback()
    call setline(1, ' (Too large for preview)')
    setlocal nomodifiable nomodified nobuflisted bufhidden=wipe
endfunction

function! PreviewCallback()
    setlocal nocursorline nobuflisted noswapfile
    if isdirectory(expand("%"))
        let env = vaffle#env#create(expand("%"))
        let env.items = vaffle#env#create_items(env)
        let b:vaffle = env
        call vaffle#buffer#redraw()
    end
endfunction

function! TogglePreview()
    if Previewing()
        pclose
    else
        for item in CursorItem()
            call Preview(item)
        endfor
    end
endfunction

function! g:VaffleCreateLineFromItem(item) abort
    " require Nerd Fonts
    if a:item.selected
        let icon = ''
    elseif a:item.is_link
        let icon = (isdirectory(a:item.path) ? '' : '')
    else
        let icon = (isdirectory(a:item.path) ? '' : '')
    endif
    let env = vaffle#buffer#get_env()
    if &previewwindow
        let time = ''
    else
        let time = strftime("%y/%m/%d %H:%M ", getftime(a:item.path))
    endif
    if &previewwindow
        let size = ''
    elseif a:item.is_dir
        let size = len(glob(a:item.path . '/*', 0, 1, 1))
    else
        let byte = getfsize(a:item.path)
        let k = 1024
        for unit in ['B', 'K', 'M', 'G', 'T']
            if byte < k
                let size = (byte * 1024 / k) . unit
                break
            else
                let k = k * 1024
            endif
        endfor
    endif
    return printf("%s %s%s\t%s\t%s",
                \ icon,
                \ a:item.basename . (a:item.is_dir ? '/' : ''),
                \ a:item.is_link ? '  ' . a:item.path: '',
                \ size,
                \ time)
endfunction

let g:vaffle_comparator = {
            \'default': 'vaffle#sorter#default#compare',
            \'time'   : { lhs, rhs -> getftime(rhs.path) - getftime(lhs.path) }
            \}

function! g:VaffleGetComparator()
    return g:vaffle_comparator[b:vaffle_sorter_list[0]]
endfunction

function! RotateList(list)
    let orig = copy(a:list)
    let n = len(a:list)
    for i in range(1, n)
        let a:list[i - 1] = orig[i % n]
    endfor
endfunction

function! ChangeSortOrder()
    call RotateList(b:vaffle_sorter_list)
    call vaffle#refresh()
endfunction

augroup DuplicateWhenSplitted
    autocmd!
    autocmd WinNew * call timer_start(0, { ->
                \ &filetype ==# 'vaffle'
                \ && vaffle#buffer#duplicate() })
augroup END

function! CursorItem()
    let items = vaffle#buffer#get_env().items
    return empty(items) ? [] : [items[line(".")-1]]
endfunction

function! OperateFile(from_winnr, to_winnr, operation)
    let curr_winnr = winnr()
    execute a:from_winnr . 'wincmd w'
    for item in CursorItem()
        execute a:to_winnr . 'wincmd w'
        let to_path = vaffle#buffer#get_env().dir . '/' . item.basename
        if filereadable(to_path) || isdirectory(to_path)
            echoerr 'File exists.'
        elseif a:operation ==# 'copy' && item.is_dir
            echoerr "Can\'t copy directory."
        else
            call ExecOperation(item.path, to_path, a:operation)
            call vaffle#refresh()
            call search('\V' . item.basename)
            execute a:from_winnr . 'wincmd w'
            execute item.index + 1
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

function! JumpToChar(direction, char)
    let items = vaffle#buffer#get_env().items
    let j = line(".")
    while v:true
        let j += a:direction
        if j <= 0 || j > len(items)
            return
        end
        if items[j-1].basename =~? '\v^\.?\V' . a:char
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
    let b:jumped_from = jumped_from
    nnoremap <buffer> l :execute 'Vaffle' getline(".")<CR>
    nnoremap <buffer> h :execute 'Vaffle' b:jumped_from<CR>
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
        if isdirectory(item.path)
            call vaffle#open_current('')
        endif
    endfor
endfunction

function! Open()
    for item in CursorItem()
        if item.is_dir
            call vaffle#open_current('')
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
    let dir = (&filetype ==# 'vaffle' ? env.dir : getcwd())
    let dir = shellescape(dir)
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
    if &filetype ==# 'vaffle'
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
nnoremap []q :copen<CR>
nnoremap ][q :cclose<CR>
nnoremap ][h :helpclose<CR>

function! s:start_shell()
    if &filetype ==# 'vaffle'
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
