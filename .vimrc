call plug#begin('~/.vim/plugged')
    Plug 'tpope/vim-endwise'
    Plug 'tomtom/tcomment_vim'
    Plug 'vim-airline/vim-airline'
    Plug 'justinmk/vim-dirvish'
    " Plug 'cocopon/vaffle.vim'
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
    Plug 'junegunn/fzf.vim'
    Plug 'tpope/vim-surround'
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
let s:file_explorer_command = 'StartDirvish'
let s:file_explorer_file_type = 'dirvish'
function! StartExplorer()
    if g:is_windows && &filetype ==# s:file_explorer_file_type
        execute "!start" expand("%")
    else
        execute s:file_explorer_command expand("%:p:h")
    endif
endfunction
noremap <silent> <Space>e :call StartExplorer()<CR>

let sort = 'sort ,^.*[\/],'
if g:is_windows
    let hide = 'silent keeppatterns g@\v\\\.[^\\]+\\?$@d'
else
    let hide = 'silent keeppatterns g@\v/\.[^\/]+/?$@d'
endif
let go_top = 'norm gg'
let g:mode_hide_sort = join ([sort, hide, go_top], ' | ')
let g:mode_sort = join ([sort, go_top], ' | ')
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
    nnoremap <silent><buffer> h :call Back()<CR>
    nnoremap <silent><buffer> l :call Foward()<CR>
    nnoremap <silent><buffer> <CR> :call Open()<CR>
    nnoremap <silent><buffer> ~ :execute 'StartDirvish' expand("~")<CR>
    nmap <buffer> <Esc> <Plug>(dirvish_quit)
    nnoremap <silent><buffer> . :call Toggle()<CR>
    nmap <buffer> a :execute "!echo" expand("%:p") . ">>" expand("~")."/.vim/.bookmark" <CR>
    nmap <buffer> b :call Bookmark()<CR>
    nmap <silent><buffer> m :call MoveFile()<CR>

    let w:operation = ''
    if !exists('b:saved_pos')
        let b:saved_pos = {}
    endif
    autocmd BufEnter <buffer> if exists('w:from_path') | let w:operation = '' | endif
    autocmd BufLeave <buffer> let b:saved_pos[win_getid()] = line(".")
endfunction

command! -nargs=1 StartDirvish call s:start_dirvish(<q-args>)
function! s:start_dirvish(path)
    execute 'Dirvish' a:path
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

function! MoveFile()
    if w:operation !=# ''
        let error_file = tempname()
        let to_path = expand("%") . fnamemodify(w:from_path, ":t")
        let g:ret = system(join(["mv", w:from_path, to_path, '2>', error_file], ' '))
        if v:shell_error == 0
            let w:operation = ''
            norm R
            call search("^" . to_path . "$")
        else
            execute "split" error_file
        endif
    else
        "TODO: empty_line
        let w:operation = 'move'
        let w:from_path = getline(".")
    endif
endfunction

let g:bookmark_file_path = $HOME . '/.vim/.bookmark'
function! Bookmark()
    let temp_dir = tempname()
    call mkdir(temp_dir, 'p')
    let jumped_from = expand('%')
    let operation = w:operation
    execute 'Dirvish' temp_dir
    let w:operation = operation
    let b:jumped_from = jumped_from
    nnoremap <buffer> h :call Return()<CR>
    nnoremap <buffer> m <Nop>

    execute 'read' g:bookmark_file_path
    v/\S/d
    sort u
    execute 'w' g:bookmark_file_path
endfunction

function! Return()
    let operation = w:operation
    execute 'Dirvish' b:jumped_from
    let w:operation = operation
    let win_id = win_getid()
    if exists('b:saved_pos') && has_key(b:saved_pos, win_id)
        execute b:saved_pos[win_id]
    endif
endfunction

function! Back()
    let operation = w:operation
    execute "normal \<Plug>(dirvish_up)"
    let w:operation = operation
endfunction

function! Foward()
    if isdirectory(getline("."))
        call Open()
    endif
endfunction

function! Open()
    let path = getline(".")
    let ext = fnamemodify(path, ":e")
    if g:is_windows && match(ext, '\v^(pdf|xls[xm]?)$') >= 0
        execute "!start" path
    else
        let operation = w:operation
        call dirvish#open('edit', '0')
        let w:operation = operation
        let win_id = win_getid()
        if exists('b:saved_pos') && has_key(b:saved_pos, win_id)
            execute b:saved_pos[win_id]
        endif
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
    if &filetype ==# s:file_explorer_file_type
        FZF %
    else
        FZF
    endif
endfunction
command! FindFile call s:find_file()
nnoremap <Space>f :FindFile<CR>

function! s:find_dir()
    if g:is_windows
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

function! FileOperationStatus()
    if &filetype ==# 'dirvish' && exists('w:operation') && w:operation !=# ''
        return 'moving'
    else
        return ''
    endif
endfunction

let g:airline_section_b = '%{FileOperationStatus()}'
