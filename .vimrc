" vim: foldmethod=marker

" TODO: Check existence of vim-plug
call plug#begin('~/.vim/plugged')
" {{{
  Plug 'godlygeek/tabular'
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
  silent execute (has('win32') ? '!start' : '!open') shellescape(a:path)
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
    if has('mac')
      silent execute "!open" shellescape(expand('%'))
    elseif has('win32')
      silent execute "!start" shellescape(expand('%'))
    endif
    redraw!
  endif
endfunction


nnoremap <silent> <Leader>t :call LaunchTerminal()<CR>
function! LaunchTerminal() abort
  let bufnr = term_start(&shell, #{ term_finish: 'close', cwd: GetDir() })
  wincmd K
  call setbufvar(bufnr, "&buflisted", 0)
endfunction


function! OpenBookmarkFile()
  execute 'edit' g:myfiler_bookmark_file
endfunction
nnoremap <silent> <Leader>s :call OpenBookmarkFile()<CR>


nnoremap Y y$
nnoremap <silent> [t        gT
nnoremap <silent> ]t        gt
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


" Prevent <C-w>o from closing windows unintensionally
" {{{
nnoremap <silent> <C-w>o     :call SafeWinOnly()<CR>
nnoremap <silent> <C-w><C-o> :call SafeWinOnly()<CR>
tnoremap <silent> <C-w>o     <C-w>:call SafeWinOnly()<CR>
tnoremap <silent> <C-w><C-o> <C-w>:call SafeWinOnly()<CR>
function! SafeWinOnly() abort
  if len(tabpagebuflist()) <= 1
    return
  endif
  let confirm = input('Close all other windows? (y/N): ')
  if confirm ==# 'y'
    call feedkeys(':', 'nx')
    only
  endif
  redraw
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

  nnoremap <silent> <C-n> :call BufferReverse()<CR>
  " {{{
  function! BufferReverse() abort
    let fzf_param = fzf#vim#with_preview({ 'options': ['--reverse'] })
    call fzf#vim#buffers(fzf_param, 0)
  endfunction
  " }}}

  nnoremap <silent> <C-p> :call History()<CR>
  " {{{
  function! History() abort
    let files = fzf#vim#_recent_files()
    call filter(files, { _, file ->
          \    file !~ '\.jax$'
          \ && file !~ 'Cellar/.*/vim/.*/doc/.*\.txt$'
          \ && file !~ 'plugged/.*/doc/.*\.txt$' })
    let param = fzf#vim#with_preview(#{ source: files })
    call fzf#vim#history(param)
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


if filereadable($MYVIMRC . '_local')
  execute 'source' ($MYVIMRC . '_local')
endif
