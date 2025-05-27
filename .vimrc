" vim: foldmethod=marker

" TODO: Check existence of vim-plug
call plug#begin('~/.vim/plugged')
" {{{
  Plug 'godlygeek/tabular'
  " Plug 'preservim/vim-markdown'
  Plug 'itchyny/lightline.vim'
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/vim-peekaboo'
  Plug 'kana/vim-submode'
  Plug 'morhetz/gruvbox'
  Plug 'NLKNguyen/papercolor-theme'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  Plug 'vim-jp/vimdoc-ja'
  Plug '~/myfiler'
" }}}
call plug#end()
function! PluginEnabled(name) abort
  return exists('g:plugs')
        \ && has_key(g:plugs, a:name)
        \ && isdirectory(g:plugs[a:name].dir)
endfunction

let mapleader = "\<Space>"

set belloff=all
set backspace=indent,eol,start
set ttimeoutlen=1
set nowrap
set scrolloff=5
set encoding=utf-8
set ambiwidth=double
set history=1000
set viminfo='1000,<0,h
set nofixendofline

" indent & tab options
set smartindent autoindent shiftwidth=2
set expandtab tabstop=2 softtabstop=0 smarttab

" guiding item optinos
set number cursorline laststatus=2 showcmd showtabline=2

" Turn IME off in entering normal mode
if has('mac') && executable('im-select')
" {{{
  let g:normal_input_method = 'com.apple.keylayout.ABC'

  function! s:ime_off() abort
    if mode() ==# 'n' && trim(system('im-select')) !=# g:normal_input_method
      call system('im-select ' . g:normal_input_method)
    endif
  endfunction

  augroup auto_ime_off
    autocmd!
    autocmd ModeChanged *:n call s:ime_off()
    autocmd FocusGained *   call s:ime_off()
  augroup END
endif
" }}}

" Change the cursor shape depending on modes
if &term =~ '^xterm'
" {{{
  let &t_SI = "\e[5 q"
  let &t_EI = "\e[1 q"
  let &t_SR = "\e[4 q"
  augroup cmdline_cursor
    autocmd!
    autocmd CmdlineEnter             * call echoraw(&t_SI)
    autocmd CmdlineLeave,CmdwinEnter * call echoraw(&t_EI)
  augroup END
endif
" }}}

augroup my_autocmds
  autocmd!

  " auto source
  autocmd BufWritePost * ++nested if &ft ==# 'vim' | source % | endif

  " Keep tab-local current directory
  autocmd DirChangedPre * call SaveTcd()
  autocmd DirChanged * call RestoreTcd()
  autocmd TabNew * tcd ~
augroup END

function! SaveTcd() abort
  let tabpagenr = tabpagenr()
  noautocmd tabdo let t:_current_directory = getcwd()
  noautocmd execute 'normal! ' . tabpagenr . 'gt'
endfunction

function! RestoreTcd() abort
  let new_cwd = getcwd()
  let tabpagenr = tabpagenr()
  noautocmd tabdo execute 'tcd ' . t:_current_directory
  noautocmd tabdo unlet t:_current_directory
  noautocmd execute 'normal! ' . tabpagenr . 'gt'
  noautocmd execute 'tcd ' . new_cwd
  let t:current_directory = new_cwd
endfunction

" search behavior
set ignorecase smartcase incsearch hlsearch wrapscan
nnoremap <silent> <Esc> :nohlsearch<CR>


" Customize behavior of '*', '#'
" {{{
nnoremap <silent> * :call SearchWord(0) \| let v:searchforward=1<CR>
nnoremap <silent> # :call SearchWord(0) \| let v:searchforward=0<CR>
vnoremap <silent> * :call SearchWord(1) \| let v:searchforward=1<CR>
vnoremap <silent> # :call SearchWord(1) \| let v:searchforward=0<CR>
function! SearchWord(visual) abort
  let saved_register = @x
  if a:visual
    normal! gv"xy
    let @/ = @x
  else
    normal! "xyiw
    let @/ = '\<' . @x . '\>'
  endif
  let @x = saved_register
  set hlsearch
  redraw
endfunction
" }}}


" Use Emacs-like key bindings in insert/cmdline mode
" {{{
noremap! <C-b> <Left>
noremap! <C-f> <Right>
noremap! <C-a> <Home>
noremap! <C-e> <End>
noremap! <C-h> <BS>
noremap! <C-d> <Delete>
" }}}


function! OsOpen(path) abort
  call system((has('win32') ? 'start ' : 'open ') . shellescape(a:path))
  redraw!
endfunction
let g:myfiler_open_func = #{
      \ pdf:  funcref('OsOpen'),
      \ xls:  funcref('OsOpen'),
      \ xlsx: funcref('OsOpen'),
      \ xlsm: funcref('OsOpen'),
      \ ppt:  funcref('OsOpen'),
      \ pptx: funcref('OsOpen')
      \ }


function! GetDir() abort
  return &filetype ==# 'myfiler' ? expand('%') : getcwd()
endfunction


nnoremap <silent> <Leader>e :call LaunchMyFiler()<CR>
function! LaunchMyFiler() abort
  if &filetype !=# 'myfiler'
    let name = expand('%:t')
    call myfiler#open(expand('%:p:h'))
    call myfiler#search_name(name)
  endif
endfunction


nnoremap <silent> <Leader>E :call LaunchOsFileExplorer()<CR>
function! LaunchOsFileExplorer() abort
  if &filetype ==# 'myfiler'
    call OsOpen(expand('%'))
  endif
endfunction


nnoremap <silent> <Leader>t :call LaunchTerminal()<CR>
function! LaunchTerminal() abort
  let bufnr = term_start(&shell, #{ term_finish: 'close', cwd: GetDir() })
  wincmd K
  8wincmd _
  call setbufvar(bufnr, "&buflisted", 0)
endfunction


nnoremap Y y$
nnoremap <silent> [t        gT
nnoremap <silent> ]t        gt
nnoremap <silent> [d        :diffthis<CR>
nnoremap <silent> ]d        :diffoff<CR>
nnoremap <silent> ][h       :helpclose<CR>
nnoremap <silent> <Leader>w :write<CR>
nnoremap <silent> <Leader>q :quit<CR>


" Add shortcuts on QuickFix
" {{{
nnoremap <silent> []q :copen<CR>
nnoremap <silent> ][q :cclose<CR>
nnoremap <silent> [[q :cpfile<CR>
nnoremap <silent> ]]q :cnfile<CR>
nnoremap <silent> ]q  :call QuickFixChange(v:true)<CR>
nnoremap <silent> [q  :call QuickFixChange(v:false)<CR>
function! QuickFixChange(forward)
  try
    if a:forward
      cnext
    else
      cprev
    endif
    return
  catch /E553/
    if a:forward
      $cc
    else
      1cc
    endif
  catch /E42/
    echohl Error
    echomsg v:exception
    echohl None
    return
  endtry
endfunction
" }}}


" Replace behavior of <C-w>o
" {{{
nnoremap <silent> <C-w>o          :call MaximizeCurrentWindow()<CR>
nnoremap <silent> <C-w><C-o>      :call MaximizeCurrentWindow()<CR>
tnoremap <silent> <C-w>o     <C-w>:call MaximizeCurrentWindow()<CR>
tnoremap <silent> <C-w><C-o> <C-w>:call MaximizeCurrentWindow()<CR>
function! MaximizeCurrentWindow() abort
  if !has_key(t:, 'saved_winsize')
    let t:saved_winsize = { 'h': {}, 'w': {} }
    for winnr in range(1, winnr('$'))
      let t:saved_winsize['h'][winnr] = winheight(winnr)
      let t:saved_winsize['w'][winnr] = winwidth(winnr)
    endfor
    resize
    vertical resize
    for winnr in range(1, winnr('$'))
      execute            winnr . 'resize' max([2, winheight(winnr)])
      execute 'vertical' winnr . 'resize' max([5, winwidth(winnr)])
    endfor
  else
    for winnr in range(1, winnr('$'))
      execute            winnr . 'resize' get(t:saved_winsize['h'], winnr, 4)
      execute 'vertical' winnr . 'resize' get(t:saved_winsize['w'], winnr, 10)
    endfor
    unlet t:saved_winsize
  endif
endfunction
" }}}


let _HOME = fnamemodify($HOME, ':p')
let g:myfiler_bookmark_file = _HOME . 'myfiler_bookmarks'
let g:myfiler_trashbox_directory = _HOME . 'myfiler_trashbox'
let g:myfiler_default_view = {}
let g:myfiler_default_sort = {}
let g:myfiler_default_visibility = {}

let _path = g:myfiler_trashbox_directory
let g:myfiler_default_view[_path] = 'TsbDl'
let g:myfiler_default_sort[_path] = 'T'

let _path = _HOME . 'Downloads'
let g:myfiler_default_view[_path] = 'TsbDl'
let g:myfiler_default_sort[_path] = 'T'

let _path = _HOME . 'dotfiles'
let g:myfiler_default_visibility[_path] = v:true


if PluginEnabled('fzf.vim')
" {{{
  nnoremap <silent> <Leader>f :call FindFile()<CR>
  " {{{
  function! FindFile() abort
    call fzf#vim#files(GetDir(), fzf#vim#with_preview())
  endfunction
  " }}}

  if executable('rg')
    nnoremap <silent> <Leader>g :call Ripgrep()<CR>
    nnoremap <silent> <Leader>* :call Ripgrep(expand('<cword>'))<CR>
    vnoremap <silent> <Leader>* :call RipgrepSelected()<CR>
    " {{{
    function! Ripgrep(str = '') abort
      let str = input('grep: ', a:str)
      if !empty(str)
        let rg_options = [
              \ '--hidden',
              \ '--line-number',
              \ '--no-heading',
              \ '--color=always',
              \ '--crlf',
              \ '--smart-case']
        let rg_cmd = join(['rg'] + rg_options + ['--', printf('%s', str)], ' ')
        let fzf_param = #{ dir: GetDir(), options: '--reverse --nth 3..' }
        call fzf#vim#grep(rg_cmd, fzf#vim#with_preview(fzf_param))
      endif
    endfunction
    function! RipgrepSelected() abort
      let saved_register = @x
      normal! gv"xy
      call Ripgrep(@x)
      let @x = saved_register
    endfunction
    " }}}
  endif

  nnoremap <silent> <C-n> :call Integrated()<CR>
  " {{{
  function! Integrated() abort
    let listed = {}

    let bufnrs = filter(range(1, bufnr('$')), { _, b -> buflisted(b) && bufname(b) != '' })
    let bufnrs = sort(bufnrs, 's:compare')
    for b in bufnrs
      let listed[s:normalize(bufname(b))] = 1
    endfor
    let buffer_lines = map(bufnrs, { _, bufnr -> s:format_buffer(bufnr) })

    let bookmarks = filter(readfile(g:myfiler_bookmark_file), { _, path ->
          \ !has_key(listed, s:normalize(path))
          \ })
    for path in bookmarks
      let listed[s:normalize(path)] = 1
    endfor
    let bookmark_lines = map(bookmarks, { _, path -> s:format_bookmark(path) })

    let history = fzf#vim#_recent_files()
    call filter(history, { _, path ->
          \ !has_key(listed, s:normalize(path))
          \ && filereadable(path)
          \ && path !~ '\.jax$'
          \ && path !~ 'Cellar/.*/vim/.*/doc/.*\.txt$'
          \ && path !~ 'plugged/.*/doc/.*\.txt$' })
    let history_lines = map(history, { _, path -> s:format_history(path) })

    call fzf#run(fzf#wrap(fzf#vim#with_preview(#{
          \ source: buffer_lines + bookmark_lines + history_lines,
          \ sink: function('s:open'),
          \ options: [
          \   '--reverse',
          \   '--delimiter=\t',
          \   '--with-nth=2..',
          \   '--nth=2',
          \   '--tiebreak=index',
          \   '--prompt', 'Buf + Bookmark + History> ',
          \   '--ansi'
          \ ] })))
  endfunction

  function! s:normalize(path)
    return fnamemodify(a:path, ":p:~:.")
  endfunction

  function! s:compare(...)
    let [b1, b2] = map(copy(a:000), 'get(g:fzf#vim#buffers, v:val, v:val)')
    return b1 < b2 ? 1 : -1
  endfunction

  function! s:format_buffer(bufnr)
    let name = bufname(a:bufnr)
    let line = getbufinfo(a:bufnr)[0]['lnum']
    return s:format('Buff', 32, name, line)
  endfunction

  function! s:format_bookmark(path)
    let path = s:normalize(a:path)
    return s:format('Book', 34, path, 1)
  endfunction

  function! s:format_history(path)
    let path = s:normalize(a:path)
    return s:format('Hist', 31, path, 1)
  endfunction

  function! s:format(type, color_code, path, line)
    return printf("%s:%d\t[%s]\t%s", a:path, a:line, s:color(a:color_code, a:type), a:path)
  endfunction

  function! s:color(color_code, str)
    return printf("\x1b[%d;1m%s\x1b[m", a:color_code, a:str)
  endfunction

  function! s:open(line)
    call myfiler#open(split(a:line, '\t')[2])
  endfunction
  " }}}

  nnoremap <silent> <Leader>: :History:<CR>
  nnoremap <silent> <Leader>/ :History/<CR>
  nnoremap <silent> <Leader>H :Helptag<CR>
else
  echoerr "fzf.vim is not installed."
" }}}
endif


if PluginEnabled("lightline.vim")
" {{{
  set noshowmode

  let g:lightline = #{}
  let g:lightline.component = #{
        \ buffer: '[%n] %f',
        \ cursorinfo: '%3l/%L:%2v' }
  let g:lightline.active = #{
        \ left:  [['mode', 'paste'], ['readonly', 'buffer', 'modified']],
        \ right: [['cursorinfo'], [ 'fileformat', 'fileencoding', 'filetype']] }
  let g:lightline.inactive = #{
        \ left:  [['buffer']],
        \ right: [['cursorinfo']] }
  let g:lightline.tab_component_function = #{
        \ tcd: 'LightlineTabCurrentDirectory' }
  let g:lightline.tabline = #{
        \ left:  [['tabs']],
        \ right: [] }
  let g:lightline.tab = #{
        \ active:   ['tabnum', 'tcd'],
        \ inactive: ['tabnum', 'tcd'] }

  function! LightlineTabCurrentDirectory(tabpagenr) abort
    let cwd = getcwd(-1, a:tabpagenr)
    if cwd ==# $HOME
      return cwd
    else
      return fnamemodify(cwd, ':~')
    endif
  endfunction
" }}}
endif


if PluginEnabled("vim-submode")
" {{{
  call submode#enter_with('winsize', 'n', '', '<C-w>>', '2<C-w>>')
  call submode#enter_with('winsize', 'n', '', '<C-w><', '2<C-w><')
  call submode#enter_with('winsize', 'n', '', '<C-w>+',  '<C-w>+')
  call submode#enter_with('winsize', 'n', '', '<C-w>-',  '<C-w>-')
  call submode#map('winsize', 'n', '', '>', '2<C-w>>')
  call submode#map('winsize', 'n', '', '<', '2<C-w><')
  call submode#map('winsize', 'n', '', '+',  '<C-w>+')
  call submode#map('winsize', 'n', '', '-',  '<C-w>-')
  let g:submode_timeoutlen=2000
  let g:submode_always_show_submode=1
" }}}
endif

" Try to keep ratio of windows' size whenever Vim itself is resized
" {{{
augroup keep_win_size_ratio
  autocmd!
  autocmd VimEnter,WinResized,TabEnter * call s:record_win_size()
  autocmd VimResized * call s:restore_win_size_ratio()
augroup END

function! s:record_win_size() abort
  let g:last_size = { 'vim': { 'h': &lines, 'w': &columns } }
  for winnr in range(1, winnr('$'))
    let g:last_size[winnr] =  { 'h': winheight(winnr), 'w': winwidth(winnr) }
  endfor
endfunction

function! s:restore_win_size_ratio() abort
  if !exists('g:last_size')
    call s:record_win_size()
    return
  endif

  let last_vim_size = g:last_size['vim']
  let new_vim_size = { 'h': &lines, 'w': &columns }

  for winnr in range(1, winnr('$'))
    let last_win_size = g:last_size[winnr]
    let h = (0.0 + last_win_size['h']) * new_vim_size['h'] / last_vim_size['h']
    execute             winnr . 'resize' float2nr(round(h))
    let w = (0.0 + last_win_size['w']) * new_vim_size['w'] / last_vim_size['w']
    execute 'vertical ' winnr . 'resize' float2nr(round(w))
  endfor

  call s:record_win_size()
endfunction
" }}}

nnoremap <silent> <C-p> :call TogglePreview()<CR>
" {{{
function! TogglePreview() abort
  if exists('g:preview_paneid')
    call system(
          \ 'wezterm cli kill-pane --pane-id '
          \ . g:preview_paneid)
    unlet g:preview_paneid
    return
  endif

  let preview_width = 40

  let split_command = 'wezterm cli split-pane --right --cells ' . preview_width
  let output = system(split_command)
  let g:preview_paneid = str2nr(output)
  call system('wezterm cli activate-pane --pane-id ' . $WEZTERM_PANE)

  if &filetype ==# 'myfiler' && !myfiler#buffer#is_empty()
    call s:preview(myfiler#util#get_entry().path.ToString())
  endif
endfunction

function! s:update_preview() abort
  if exists('g:preview_paneid') && &filetype ==# 'myfiler'
    call s:preview(myfiler#util#get_entry().path.ToString())
  endif
endfunction

function! s:preview(path) abort
  call system(
        \ 'echo "q\n preview.pl ' . shellescape(a:path)
        \ . '" | wezterm cli send-text --no-paste --pane-id '
        \ . g:preview_paneid .  ' ')
endfunction

augroup update_preview
  autocmd!
  autocmd CursorMoved * call s:update_preview()
augroup END
" }}}


if filereadable($MYVIMRC . '_local')
  execute 'source' ($MYVIMRC . '_local')
endif
