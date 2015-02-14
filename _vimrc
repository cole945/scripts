syntax on
set backspace=indent,eol,start
set hlsearch
set nu
set nowrap
set tabstop=8
set shiftwidth=4
set viminfo='100,s10,h
" set expandtab

" Tell vim to remember certain things when we exit
"  '10  :  marks will be remembered for up to 10 previously edited files
"  <100 :  will save up to 100 lines for each register
"  :20  :  up to 20 lines of command-line history will be remembered
"  %    :  saves and restores the buffer list
"  n... :  where to save the viminfo files
set viminfo='100,<1000,:20,%,h

set bg=dark

au BufNewFile,BufRead *.md,*.c.*,*.i.*  set filetype=md
au BufNewFile,BufRead *.em		set filetype=c
au BufNewFile,BufRead *.flex		set filetype=lex

"
" Highlight incorrent whitespace (GnuStyle)
"
highlight ExtraWhitespace ctermbg=red guibg=red
function! HlFormat()
  if !exists("w:HlWhitespace_on") || w:HlWhitespace_on == 0
    match ExtraWhitespace /\s\+$\| \+\ze\t\| \{8,\}\|\/\/\|,[^ \t]\|\s,/
    " Check language spelling
    setlocal spell spelllang=en_us

    " Don't show the message when startup and loading .vimrc.
    if exists("w:HlWhitespace_on")
      echo "HlFormat On"
    endif
    let w:HlWhitespace_on = 1
  else
    match none
    set nospell
    if exists("w:HlWhitespace_on")
      echo "HlFormat Off"
    endif
    let w:HlWhitespace_on = 0
  endif
endfunction
map <F8> <ESC>:call HlFormat()<CR>
" Enable HlFormat by defult.
" au FileType c,cpp,cc,h,hpp	call HlFormat()

map M I/* <ESC>A */<ESC>

"
" GNU-style indent
"
function! GnuIndent()
  setlocal cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1
  setlocal shiftwidth=2
  setlocal tabstop=8
endfunction
au FileType c,cpp,h	call GnuIndent()
" Use external "indent" for gnu coding style,
" and then apply vim-indent "=" to origin selection "V`]"
map <F9> :!indent<CR>V`]=

"
" Hight 80c
"
" hi ColorColumn ctermbg=lightgrey guibg=lightgrey
hi ColorColumn ctermbg=235 guibg=#2c2d27
" au FileType c,cpp,h	set colorcolumn=80
" au FileType c,cpp,h,cxx let &colorcolumn=join(range(73,80),",")
if version >= 703
  let &colorcolumn=join(range(73,80),",")
endif


"
" Highlight Text
" Colors (runtime syntax/colortest.vim)
highlight HlMatch1 ctermbg=DarkCyan ctermfg=white
highlight HlMatch2 ctermbg=DarkGreen ctermfg=white
highlight HlMatch3 ctermbg=DarkRed ctermfg=white
highlight HlMatch4 ctermbg=DarkMagenta ctermfg=white
highlight HlMatch5 ctermbg=White ctermfg=black
highlight HlMatch6 ctermbg=DarkBlue ctermfg=white
" Function for high-lighting text.
function! HlMatch(group, pat)
  if exists("w:{a:group}")
    silent! call matchdelete(w:{a:group})
  endif
  if a:pat != ''
    let w:{a:group}=matchadd(a:group, a:pat, 2)
  endif
endfunction
" Highlight selected text in visual mode.
vmap <silent> <C-h>1   y:call HlMatch ('HlMatch1', '<C-R>0')<CR>
vmap <silent> <C-h>2   y:call HlMatch ('HlMatch2', '<C-R>0')<CR>
vmap <silent> <C-h>3   y:call HlMatch ('HlMatch3', '<C-R>0')<CR>
vmap <silent> <C-h>4   y:call HlMatch ('HlMatch4', '<C-R>0')<CR>
vmap <silent> <C-h>5   y:call HlMatch ('HlMatch5', '<C-R>0')<CR>
vmap <silent> <C-h>6   y:call HlMatch ('HlMatch6', '<C-R>0')<CR>
" Highlight text under the cursor.
nmap <silent> <C-h>1   :call HlMatch ('HlMatch1', '\<<C-R>=expand("<cword>")<CR>\>')<CR>
nmap <silent> <C-h>2   :call HlMatch ('HlMatch2', '\<<C-R>=expand("<cword>")<CR>\>')<CR>
nmap <silent> <C-h>3   :call HlMatch ('HlMatch3', '\<<C-R>=expand("<cword>")<CR>\>')<CR>
nmap <silent> <C-h>4   :call HlMatch ('HlMatch4', '\<<C-R>=expand("<cword>")<CR>\>')<CR>
nmap <silent> <C-h>5   :call HlMatch ('HlMatch5', '\<<C-R>=expand("<cword>")<CR>\>')<CR>
nmap <silent> <C-h>6   :call HlMatch ('HlMatch6', '\<<C-R>=expand("<cword>")<CR>\>')<CR>
" Highlight text (not whole word) under the cursor.
nmap <silent> g<C-h>1  :call HlMatch ('HlMatch1', '<C-R>=expand("<cword>")<CR>')<CR>
nmap <silent> g<C-h>2  :call HlMatch ('HlMatch2', '<C-R>=expand("<cword>")<CR>')<CR>
nmap <silent> g<C-h>3  :call HlMatch ('HlMatch3', '<C-R>=expand("<cword>")<CR>')<CR>
nmap <silent> g<C-h>4  :call HlMatch ('HlMatch4', '<C-R>=expand("<cword>")<CR>')<CR>
nmap <silent> g<C-h>5  :call HlMatch ('HlMatch5', '<C-R>=expand("<cword>")<CR>')<CR>
nmap <silent> g<C-h>6  :call HlMatch ('HlMatch6', '<C-R>=expand("<cword>")<CR>')<CR>
" Highlight last search
"map <silent> <C-h>/   y:call HlMatch ('HlMatch1', '<C-R>/')<CR>
"map <silent> 2<C-h>/  y:call HlMatch ('HlMatch2', '<C-R>/')<CR>
"map <silent> 3<C-h>/  y:call HlMatch ('HlMatch3', '<C-R>/')<CR>
"map <silent> 4<C-h>/  y:call HlMatch ('HlMatch4', '<C-R>/')<CR>
"map <silent> 5<C-h>/  y:call HlMatch ('HlMatch5', '<C-R>/')<CR>
"map <silent> 6<C-h>/  y:call HlMatch ('HlMatch6', '<C-R>/')<CR>
" Clear highlight.
nmap <silent> <ESC><C-h>1 :call HlMatch ('HlMatch1', '')<CR>
nmap <silent> <ESC><C-h>2 :call HlMatch ('HlMatch2', '')<CR>
nmap <silent> <ESC><C-h>3 :call HlMatch ('HlMatch3', '')<CR>
nmap <silent> <ESC><C-h>4 :call HlMatch ('HlMatch4', '')<CR>
nmap <silent> <ESC><C-h>5 :call HlMatch ('HlMatch5', '')<CR>
nmap <silent> <ESC><C-h>6 :call HlMatch ('HlMatch6', '')<CR>
nmap <silent> <ESC><C-h>* :call clearmatches ()<CR>

"
" Tab
"
hi TabLineFill ctermfg=Black ctermbg=Black
hi TabLine ctermfg=White ctermbg=Black
hi TabLineSel ctermfg=Black ctermbg=Yellow
" Here <ESC>1 actually means <M-1>.
map <ESC>1 1gt
map <ESC>2 2gt
map <ESC>3 3gt
map <ESC>4 4gt
map <ESC>5 5gt
map <ESC>6 6gt
map <ESC>7 7gt
map <ESC>8 8gt
map <ESC>9 9gt

"
" Copy large buffer to temp file.
"
map ,y :w! ~/.vim.copy_buffer<CR>
map ,p :r ~/.vim.copy_buffer<CR>
map ,P :0r ~/.vim.copy_buffer<CR>

"
" Disable the crap increase/decrease bug.
"
map <C-A> <F20>
map <C-X> <F20>

"
" Show current function 
"
fun! ShowFuncNameEvent()

  if (!exists('b:sfn_prev_line'))
    let b:sfn_prev_line = -1
  endif

  " Fast rejct.
  if line (".") == b:sfn_prev_line
     return
  endif

  let lnum = line(".")
  " Search 'b'ackward, don't 'W'rap around the file,
  " and do 'n'ot move the cursor
  let cur_func = search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bWnc')

  " Prototype may be across multipe lines.
  " Pre-pend return-type.
  let func_name = ""
  if (cur_func > 1 && (strlen (getline (cur_func - 1)) > 1))
    let func_name = substitute (getline (cur_func - 1), '^\s\+\|\s\+$', "", "g") . ' '
  endif
  while 1
    let cur_line = substitute (getline (cur_func), '^\s\+\|\s\+$', "", "g")
    let func_name = func_name . matchstr (cur_line, '[^{}]\+') . ' '
    if (stridx (cur_line, "{") >= 0 || stridx (cur_line, ';') >= 0 || strlen (cur_line) <= 0)
      break
    endif
    let cur_func = cur_func + 1
  endwhile

  echohl ModeMsg
  echomsg expand('%:t') . ": " . func_name
  echohl none
  let b:sfn_prev_line = lnum
endfun

" Show function name when cursor changed.
" au CursorMoved *.c : call ShowFuncNameEvent()
au FileType c,cpp set updatetime=500
au CursorHold *.c,*.cpp,*.cc,*.C call ShowFuncNameEvent()

" autocmd BufWinEnter * normal! g`"
" http://vim.wikia.com/wiki/Restore_cursor_to_file_position_in_previous_editing_session
function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction
augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END


au BufRead,BufNewFile *.ll set filetype=llvm
