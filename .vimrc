" vim: foldmethod=marker

packadd! matchit
call plug#begin('~/.vim/plugged')
" {{{
  Plug 'godlygeek/tabular'
  Plug 'itchyny/lightline.vim'
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/vim-peekaboo'
  Plug 'kana/vim-submode'
  " Plug 'mhinz/vim-startify'
  Plug 'morhetz/gruvbox'
  Plug 'NLKNguyen/papercolor-theme'
  Plug 'prabirshrestha/vim-lsp'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-repeat'
  Plug 'tpope/vim-surround'
  " Plug 'tpope/vim-unimpaired'
  Plug 'vim-jp/vimdoc-ja'
  Plug '~/myfiler'
call plug#end()
" }}}

function! PluginEnabled(name) abort
  return has_key(g:plugs, a:name) && isdirectory(g:plugs[a:name].dir)
endfunction

let mapleader = "\<Space>"

if PluginEnabled('vim-lsp')
" {{{
  augroup lsp_register_server
    autocmd!
    if executable('vim-language-server')
      " https://github.com/iamcco/vim-language-server
      autocmd User lsp_setup call lsp#register_server(#{
            \ name: 'vim-ls',
            \ cmd: { server_info -> ['vim-language-server', '--stdio'] },
            \ allowlist: ['vim'],
            \ initialization_options: #{
            \   vimruntime: $VIMRUNTIME,
            \   runtimepath: &runtimepath,
            \ }})
    endif
  augroup END

  function! LspBufferConfigCommon() abort
    if exists('+tagfunc')
      setlocal tagfunc=lsp#tagfunc
    endif
    setlocal omnifunc=lsp#complete

    let g:lsp_diagnostics_virtual_text_delay = 1000
    let g:lsp_diagnostics_float_delay = 1000

    nmap <buffer> gd         <Plug>(lsp-definition)
    nmap <buffer> gr         <Plug>(lsp-references)
    nmap <buffer> gi         <Plug>(lsp-implementation)
    " nmap <buffer> gt         <Plug>(lsp-type-definition)
    nmap <buffer> <Leader>rn <Plug>(lsp-rename)
    nmap <buffer> [g         <Plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g         <Plug>(lsp-next-diagnostic)
    nmap <buffer> K          <Plug>(lsp-hover)
    " nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
    " nnoremap <buffer> <expr><c-d> lsp#scroll(-4)
  endfunction

  function! LspBufferConfigVim() abort
    unmap <buffer> K
  endfunction

  augroup lsp_buffer_config
    autocmd!
    autocmd User lsp_buffer_enabled call LspBufferConfigCommon()
          \ | if &filetype ==# 'vim' | call LspBufferConfigVim() | endif
    autocmd CmdwinEnter * call lsp#disable_diagnostics_for_buffer()
  augroup END
endif
" }}}


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
    return getcwd(-1, a:tabpagenr)
  endfunction
endif
" }}}


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
nnoremap <silent> * :call SearchWord(0) \| let v:searchforward=1<CR>
nnoremap <silent> # :call SearchWord(0) \| let v:searchforward=0<CR>
vnoremap <silent> * :call SearchWord(1) \| let v:searchforward=1<CR>
vnoremap <silent> # :call SearchWord(1) \| let v:searchforward=0<CR>

" Emacs-like key bindings in insert/cmdline mode
noremap! <C-b> <Left>
noremap! <C-f> <Right>
noremap! <C-a> <Home>
noremap! <C-e> <End>
noremap! <C-h> <BS>
noremap! <C-d> <Delete>

function! s:delegate(path) abort
  silent execute (has('win32') ? '!start' : '!open') shellescape(a:path)
  redraw!
endfunction
command! -nargs=1 DelegateToOS call s:delegate(<args>)
let g:myfiler_open_command = #{
      \ pdf: 'DelegateToOS'
      \ }

function! FindFile() abort
  let dir = &filetype == 'myfiler' ? expand('%') : getcwd()
  call fzf#vim#files(dir, fzf#vim#with_preview())
endfunction


function! RipGrep() abort
  let str = input('grep: ')
  if !empty(str)
    let rg_options = [
          \ '--hidden',
          \ '--line-number',
          \ '--no-heading',
          \ '--color=always',
          \ '--crlf',
          \ '--smart-case']
    let rg_cmd = join(['rg'] + rg_options + ['--', printf('%s', str)], ' ')
    let dir = &filetype == 'myfiler' ? expand('%') : getcwd()
    let fzf_param = #{ dir: dir, options: '--reverse --nth 3..' }
    call fzf#vim#grep(rg_cmd, fzf#vim#with_preview(fzf_param))
  endif
endfunction


function! LaunchMyFiler() abort
  if &filetype !=# 'myfiler'
    let name = expand('%:t')
    call myfiler#open(expand('%:p:h'))
    call myfiler#search_name(name)
  endif
endfunction


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


function! LaunchTerminal() abort
    let dir = &filetype ==# 'myfiler' ? expand('%') : getcwd()
    let bufnr = term_start(&shell, #{ term_finish: 'close', cwd: dir })
    call setbufvar(bufnr, "&buflisted", 0)
endfunction


function! BuffersReverse() abort
  let fzf_param = fzf#vim#with_preview({ 'options': ['--reverse'] })
  call fzf#vim#buffers(fzf_param, 0)
endfunction


function! OpenBookmarkDir(tabedit = v:false)
  execute (a:tabedit ? 'tabedit' : 'edit') g:myfiler_bookmark_directory
endfunction
nnoremap <silent> <Leader>S :call OpenBookmarkDir(v:true)<CR>
nnoremap <silent> <Leader>s :call OpenBookmarkDir(v:false)<CR>


nnoremap Y y$
nnoremap <silent> [q        :cprevious<CR>
nnoremap <silent> ]q        :cnext<CR>
nnoremap <silent> [t        gT
nnoremap <silent> ]t        gt
" nnoremap <silent> [[q       :cpfile<CR>
" nnoremap <silent> ]]q       :cnfile<CR>
" nnoremap <silent> []q       :copen<CR>
nnoremap <silent> ][q       :cclose<CR>
nnoremap <silent> ][h       :helpclose<CR>
nnoremap <silent> <Leader>w :write<CR>
nnoremap <silent> <Leader>q :quit<CR>
nnoremap <silent> <C-n>     :call BuffersReverse()<CR>
nnoremap <silent> <C-p>     :call History()<CR>
nnoremap <silent> <Leader>: :History:<CR>
nnoremap <silent> <Leader>/ :History/<CR>
nnoremap <silent> <Leader>H :Helptag<CR>
nnoremap <silent> <Leader>e :call LaunchMyFiler()<CR>
nnoremap <silent> <Leader>E :call LaunchOsFileExplorer()<CR>
nnoremap <silent> <Leader>f :call FindFile()<CR>
nnoremap <silent> <Leader>g :call RipGrep()<CR>
nnoremap <silent> <Leader>t :call LaunchTerminal()<CR>

function! History() abort
  let files = fzf#vim#_recent_files()
  call filter(files, { _, file ->
        \    file !~ '\.jax$'
        \ && file !~ 'Cellar/.*/vim/.*/doc/.*\.txt$'
        \ && file !~ 'plugged/.*/doc/.*\.txt$' })
  let param = fzf#vim#with_preview(#{ source: files })
  call fzf#vim#history(param)
endfunction

nnoremap <silent> <C-w>o     <C-w>:call SafeWinOnly()<CR>
nnoremap <silent> <C-w><C-o> <C-w>:call SafeWinOnly()<CR>
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

if PluginEnabled("vim-submode")
" {{{
  call submode#enter_with('winsize', 'n', '', '<C-w>>', '2<C-w>>')
  call submode#enter_with('winsize', 'n', '', '<C-w><', '2<C-w><')
  call submode#enter_with('winsize', 'n', '', '<C-w>+', '<C-w>+')
  call submode#enter_with('winsize', 'n', '', '<C-w>-', '<C-w>-')
  call submode#map('winsize', 'n', '', '>', '2<C-w>>')
  call submode#map('winsize', 'n', '', '<', '2<C-w><')
  call submode#map('winsize', 'n', '', '+', '<C-w>+')
  call submode#map('winsize', 'n', '', '-', '<C-w>-')
  let g:submode_timeoutlen=2000
  let g:submode_always_show_submode=1
endif
" }}}

let g:myfiler_bookmark_directory =
      \ fnamemodify($HOME, ':p') . 'myfiler_bookmarks'
let g:myfiler_default_view = {}
let g:myfiler_default_sort = {}
let g:myfiler_default_visibility = {}

let _path = g:myfiler_bookmark_directory
let g:myfiler_default_view[_path] = 'DlA'
let g:myfiler_default_sort[_path] = 'n'
let g:myfiler_default_visibility[_path] = v:true

let _path = fnamemodify($HOME, ':p' . 'Downloads')
let g:myfiler_default_view[_path] = 'TsbDl'
let g:myfiler_default_sort[_path] = 'T'

let _path = fnamemodify($HOME, ':p' . 'dotfiles')
let g:myfiler_default_visibility[_path] = v:true

function! AddBookmark() abort
  let entry = myfiler#get_entry()
  let path = entry.path
  let dir = g:myfiler_bookmark_directory
  let linkpath = fnamemodify(dir, ':p') . entry.name
  " TODO: For Windows
  let command = 'ln -s '
  call system(command . shellescape(path) . ' ' . shellescape(linkpath))
  if v:shell_error
    call myfiler#util#echoerr('Adding bookmark failed.')
  else
    call myfiler#buffer#reload()
    let bookmark_bufnr = bufnr(g:myfiler_bookmark_directory)
    if bookmark_bufnr > 0
      let current_bufnr = bufnr()
      noautocmd silent execute 'keepjumps buffer' bookmark_bufnr
      call myfiler#buffer#reload()
      noautocmd silent execute 'keepjumps buffer' current_bufnr
    endif
  endif
endfunction

augroup for_myfiler
  autocmd!
  autocmd FileType myfiler
        \ nmap <silent><buffer><nowait> <Leader>* :call AddBookmark()<CR>
augroup END


if filereadable($MYVIMRC . '_local')
  execute 'source' ($MYVIMRC . '_local')
endif

syntax enable

syntax match TrailingWhitespaces '\s\+$'
highlight! default link TrailingWhitespaces Error
