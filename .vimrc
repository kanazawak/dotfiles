packadd! matchit
call plug#begin('~/.vim/plugged')
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

function! PluginEnabled(name) abort
  return has_key(g:plugs, a:name) && isdirectory(g:plugs[a:name].dir)
endfunction

let mapleader = "\<Space>"

if PluginEnabled('vim-lsp')
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


if PluginEnabled("vim-startify")
  let g:startify_change_to_dir = 0
  let g:startify_change_cmd = 'tcd'
  let g:startify_enable_special = 0
  let g:startify_session_autoload = 0
  let g:startify_custom_header = 'StartifyCustomHeader()'

  let g:startify_lists = [
      \ #{ type: 'bookmarks',    header: ['   Bookmarks'] },
      \ #{ type: 'commands',     header: ['   Commands'] },
      \ ]

  let g:startify_bookmarks = []

  function! AddBookmark(path)
    call add(g:startify_bookmarks, { len(g:startify_bookmarks) + 1 : a:path })
  endfunction

  call AddBookmark($MYVIMRC)
  call AddBookmark($MYVIMRC . '_local')
  call AddBookmark($HOME)

  let g:startify_commands = [
      \ { 'D': 'call delete("Session.vim") | Startify' },
      \ ]

  function! StartifyCustomHeader() abort
    let major_version = v:version / 100
    let minor_version = v:version % 100
    let ver = 'VIM - Vi IMproved ' . major_version . '.' . minor_version

    let art = [
      \ '                               ',
      \ ' ____     ____                 ',
      \ '  \ \\   / // (*) ._. _   _    ', 
      \ '   \ \\ / //  ._. | |/ \_/ \   ', 
      \ '    \ \/ //   | | | .^. .^. |  ', 
      \ '     \  //    | | | | | | | |  ', 
      \ '      \//     |_| |_| |_| |_|  ',
      \ printf('%29s  ', ver),
      \ '                               ',
      \ '                               '
      \ ]
    let quote = startify#fortune#boxed()
    if len(art) > len(quote)
      let lpad = (len(art) - len(quote)) / 2
      let upad = len(art) - len(quote) - lpad
      let quote = map(range(upad), '""') + quote + map(range(lpad), '""')
    endif
    let joined = map(art, { i, str -> str . get(quote, i, '') })
    return filter(joined, { _, str -> str =~ '\S' })
  endfunction

  augroup for_startify
    autocmd!

    " See doc: startify-faq-01
    autocmd User Startified setlocal cursorline

    " See doc: startify-faq-05
    autocmd User Startified setlocal buftype=nofile

    " See doc: startify-faq-16
    autocmd User Startified for key in ['q', 'b', 's', 'v', 't'] |
        \ execute 'nunmap <buffer>' key | endfor
  augroup END

  function! StartifyTab() abort
    tabnew
    Startify
  endfunction

  nnoremap <silent> <Leader>S :call StartifyTab()<CR>
  nnoremap <silent> <Leader>s :Startify<CR>
endif


if PluginEnabled("lightline.vim")
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


set belloff=all
set backspace=indent,eol,start
set ttimeoutlen=1
set nowrap
set scrolloff=5
set encoding=utf8
set ambiwidth=double
set history=1000
set viminfo='1000,<0,h
" set lazyredraw


" indent & tab options
set smartindent autoindent shiftwidth=2 
set expandtab tabstop=2 softtabstop=0 smarttab

" guiding item optinos
set number cursorline laststatus=2 showcmd showtabline=2

if has('mac') && executable('im-select')
  let g:normal_input_method = 'com.apple.keylayout.ABC'

  function! ImeOff() abort
    if mode() ==# 'n'
      \ && trim(system('im-select')) != g:normal_input_method
      call system('im-select ' . g:normal_input_method)
    endif
  endfunction

  augroup auto_ime_off
    autocmd!
    autocmd ModeChanged *:n call ImeOff()
    autocmd FocusGained *   call ImeOff()
  augroup END
endif

if &term =~ '^xterm'
  " Change the cursor shape depending on modes
  let &t_SI = "\e[5 q"
  let &t_EI = "\e[1 q"
  let &t_SR = "\e[4 q"
  augroup cmdline_cursor
    autocmd!
    autocmd CmdlineEnter             * call echoraw(&t_SI)
    autocmd CmdlineLeave,CmdwinEnter * call echoraw(&t_EI)
  augroup END
endif

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
" Search selected string (using z register)
" TODO: save/restore z register
vnoremap <silent> * "zy:let @/ = @z<CR>n
vnoremap <silent> # "zy:let @/ = @z<CR>N


" Emacs-like key bindings in insert/cmdline mode
noremap! <C-b> <Left>
noremap! <C-f> <Right>
noremap! <C-a> <Home>
noremap! <C-e> <End>
noremap! <C-h> <BS>
noremap! <C-d> <Delete>

function! s:os_open(path) abort
  if has('win32')
    silent execute '!start' a:path
  else
    silent execute '!open' a:path
  endif
  redraw!
endfunction
command! -nargs=1 OsOpen call s:os_open(<q-args>)
let g:myfiler_open_command = #{
    \ pdf:'OsOpen'
    \ }

function! FindFile() abort
  let dir = &filetype == 'myfiler' ? expand('%') : getcwd()
  call fzf#vim#files(dir, fzf#vim#with_preview())
endfunction


function! RipGrep() abort
  let str = input('grep: ')
  if !empty(str)
    let rg_cmd = 'rg --hidden --line-number --no-heading --color=always --smart-case -- ' . str
    let dir = &filetype == 'myfiler' ? expand('%') : getcwd()
    let fzf_param = fzf#vim#with_preview({ 'dir': dir, 'options': '--reverse --nth 3..' })
    call fzf#vim#grep(rg_cmd, fzf_param)
  endif
endfunction


function! LaunchExplorer() abort
  if &filetype ==# 'myfiler'
    if has('win32')
      execute "!start" shellescape(expand('%'))
    endif
  else
    let name = expand('%:t')
    call myfiler#open(expand('%:p:h'))
    call myfiler#search_name(name)
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


let g:myfiler_bookmark_directory = fnamemodify($HOME, ':p') . 'bookmarks'
function! OpenBookmarkDir(tabedit = v:false)
  if a:tabedit
    execute 'tabedit' g:myfiler_bookmark_directory
  else
    execute    'edit' g:myfiler_bookmark_directory
  endif
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
" nnoremap <silent> ][q       :cclose<CR>
" nnoremap <silent> ][h       :helpclose<CR>
nnoremap <silent> <Leader>w :write<CR>
nnoremap <silent> <Leader>q :quit<CR>
nnoremap <silent> <C-n>     :call BuffersReverse()<CR>
nnoremap <silent> <C-p>     :call History()<CR>
nnoremap <silent> <Leader>: :History:<CR>
nnoremap <silent> <Leader>/ :History/<CR>
nnoremap <silent> <Leader>H :Helptag<CR>
nnoremap <silent> <Leader>e :call LaunchExplorer()<CR>
nnoremap <silent> <Leader>f :call FindFile()<CR>
nnoremap <silent> <Leader>g :call RipGrep()<CR>
nnoremap <silent> <Leader>t :call LaunchTerminal()<CR>
nnoremap <silent> <C-w>o    :call SafeWinOnly()<CR>
" TODO
" tnoremap <silent> <C-w>o    <Nop>

function! History() abort
  let files = fzf#vim#_recent_files()
  call filter(files, { _, file ->
      \    file !~ '\.jax$'
      \ && file !~ 'Cellar/.*/vim/.*/doc/.*\.txt$'
      \ && file !~ 'plugged/.*/doc/.*\.txt$' })
  let param = fzf#vim#with_preview(#{ source: files })
  call fzf#vim#history(param)
endfunction

function! SafeWinOnly() abort
  if len(tabpagebuflist()) <= 1
    return 
  endif
  let confirm = input('Really want close other windows? (y/N): ')
  if confirm ==# 'y'
    only
  endif
  redraw
endfunction

if PluginEnabled("vim-submode")
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

" command! AddBookmark

let g:myfiler_default_config = {}
let g:myfiler_default_config[g:myfiler_bookmark_directory] = 'DlAh'

if filereadable($MYVIMRC . '_local')
  execute 'source' ($MYVIMRC . '_local')
endif

syntax enable
