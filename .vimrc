"" source ~/.vimrc
set autoindent
set backspace=2
"" https://stackoverflow.com/questions/1636297/how-to-change-the-folder-path-for-swp-files-in-vim
set directory=$HOME/.vim/swapfiles//
set expandtab
"" set ff=unix
set ffs=unix,dos
set hidden
set hlsearch
set ignorecase
set incsearch
set laststatus=2
set nobackup
set nocompatible
set noerrorbells
set noswapfile
set pastetoggle=<f2>
set scrolloff=2
set shiftwidth=2
set showmatch
set smartcase
set softtabstop=2
"" https://vimhelp.org/options.txt.html#%27statusline%27
set statusline=%F%m%r%h%w\ %y\ %l:%c\ %L\ 0x%B
set tabstop=4
"" tell it to use an undo file
set undofile
"" set a directory to store the undo history
set undodir=$HOME/.vimundo/

augroup My
    autocmd!
    "" autochdir
    autocmd BufEnter * silent! lcd %:p:h
    "" syntax=c
    autocmd BufNewFile,BufRead *.h
        \ setlocal filetype=c
    "" syntax=javascript
    autocmd BufNewFile,BufRead *.cjs,*.js,*.json,*.mjs
        \ setlocal filetype=javascript
    "" syntax highlighting
    autocmd BufRead,BufWrite * syntax sync fromstart
    "" autocmd BufRead,BufWrite * syntax sync minlines=200
    "" auto remove trailing whitespace
    autocmd BufRead,BufWrite * if ! &bin | silent! %s/\s\+$//e | endif
augroup END
filetype on
filetype plugin on
syntax on

if !exists(":Vimrc")
    command! -nargs=* Vimrc call MyVimrc(<f-args>)
    function! MyVimrc(...)
        source ~/.vimrc
    endfunction
endif

function! MyCommentRegion(...)
"" this function will comment selected-region
    "" un-comment
    if a:1 == 'u'
        '<,'>s/^\(\s*\)\(""\|#\|%%\|--\|\/\/\|::\)!! /\1/e
        '<,'>s/^\(\s*\)<!--!! \(.*\) -->/\1\2/e
        '<,'>s/^\(\s*\)\/\*!! \(.*\) \*\//\1\2/e
    "" comment \"\"
    elseif a:1 == '"'
        '<,'>s/^\(\s*\)\(\S\)/\1""!! \2/e
    "" comment #
    elseif a:1 == '#'
        '<,'>s/^\(\s*\)\(\S\)/\1#!! \2/e
    "" comment %%
    elseif a:1 == '%'
        '<,'>s/^\(\s*\)\(\S\)/\1%%!! \2/e
    "" comment --
    elseif a:1 == '-'
        '<,'>s/^\(\s*\)\(\S\)/\1--!! \2/e
    "" comment /*...*/
    elseif a:1 == '*'
        '<,'>s/^\(\s*\)\(\S.*\)/\1\/*!! \2 *\//e
    "" comment //
    elseif a:1 == '/'
        '<,'>s/^\(\s*\)\(\S\)/\1\/\/!! \2/e
    "" comment ::
    elseif a:1 == ':'
        '<,'>s/^\(\s*\)\(\S\)/\1::!! \2/e
    "" comment <!--...-->
    elseif a:1 == '<'
        '<,'>s/^\(\s*\)\(\S.*\)/\1<!--!! \2 -->/e
    endif
    "" restore position
    call setpos('.', getpos("'<"))
endfunction

function! MyStringifyRegion(...)
"" this function will js-stringify-add selected-region
    "" un-stringify
    if a:1 == 'u'
        ""!! '<,'>s/^\s*\(+ "\|"\)\(.*\)\(" +\|"\)$/\2/e
        '<,'>s/^\s*\(+ \|\w\w* += \)\?"\(.*\)"\( +\|;\)\?$/\2/e
        '<,'>s/\\n\\*$//e
        '<,'>s/\\\(["'\\]\)/\1/eg
    "" stringify + "..."
    elseif a:1 == '+'
        '<,'>s/["\\]/\\&/eg
        '<,'>s/.*/    + "&\\n"/e
    "" stringify ...\n\
    elseif a:1 == '\'
        '<,'>s/['\\]/\\&/eg
        '<,'>s/$/\\n\\/e
    endif
    "" restore position
    call setpos('.', getpos("'<"))
endfunction

function! MyRename(name, bang)
"" this function will rename file <name> -> <bang>
"" https://github.com/vim-scripts/Rename/blob/0.3/plugin/Rename.vim
    let l:name = a:name
    let l:oldfile = expand('%:p')
    if bufexists(fnamemodify(l:name, ':p'))
        if (a:bang ==# '!')
            silent exe bufnr(fnamemodify(l:name, ':p')) . 'bwipe!'
        else
            echohl ErrorMsg
            echomsg 'A buffer with that name already exists (use ! to override).'
            echohl None
            return 0
        endif
    endif
    let l:status = 1
    let v:errmsg = ''
    silent! exe 'saveas' . a:bang . ' ' . l:name
    if v:errmsg =~# '^$\|^E329'
        let l:lastbufnr = bufnr('$')
        if expand('%:p') !=# l:oldfile && filewritable(expand('%:p'))
            if fnamemodify(bufname(l:lastbufnr), ':p') ==# l:oldfile
                silent exe l:lastbufnr . 'bwipe!'
            else
                echohl ErrorMsg
                echomsg 'Could not wipe out the old buffer for some reason.'
                echohl None
                let l:status = 0
            endif
            if delete(l:oldfile) != 0
                echohl ErrorMsg
                echomsg 'Could not delete the old file: ' . l:oldfile
                echohl None
                let l:status = 0
            endif
        else
            echohl ErrorMsg
            echomsg 'Rename failed for some reason.'
            echohl None
            let l:status = 0
        endif
    else
        echoerr v:errmsg
        let l:status = 0
    endif
    return l:status
endfunction
command! -nargs=* -complete=file -bang MyRename call MyRename(<q-args>, '<bang>')

"" insert-mode remap
inoremap <c-a> <c-o>^
inoremap <c-d> <c-o>x
inoremap <c-e> <c-o>$
inoremap <c-k> <c-o>D
"" non-recursive remap
nnoremap <f12> <esc> :syntax sync fromstart<cr>
nnoremap <silent> !bc :bprevious<bar>split<bar>bnext<bar>bwipeout!<cr>
nnoremap <silent> "+ :call MyStringifyRegion("+")<cr>
nnoremap <silent> "\ :call MyStringifyRegion("\\")<cr>
nnoremap <silent> "u :call MyStringifyRegion("u")<cr>
nnoremap <silent> #" :call MyCommentRegion("\"")<cr>
nnoremap <silent> #% :call MyCommentRegion("%")<cr>
nnoremap <silent> #* :call MyCommentRegion("*")<cr>
nnoremap <silent> #- :call MyCommentRegion("-")<cr>
nnoremap <silent> #/ :call MyCommentRegion("/")<cr>
nnoremap <silent> #: :call MyCommentRegion(":")<cr>
nnoremap <silent> #<char-0x23> :call MyCommentRegion("#")<cr>
nnoremap <silent> #u :call MyCommentRegion("u")<cr>
"" visual-mode remap
vnoremap <silent> "+ <esc> :call MyStringifyRegion("+")<cr>
vnoremap <silent> "\ <esc> :call MyStringifyRegion("\\")<cr>
vnoremap <silent> "u <esc> :call MyStringifyRegion("u")<cr>
vnoremap <silent> #" <esc> :call MyCommentRegion("\"")<cr>
vnoremap <silent> #% <esc> :call MyCommentRegion("%")<cr>
vnoremap <silent> #* <esc> :call MyCommentRegion("*")<cr>
vnoremap <silent> #- <esc> :call MyCommentRegion("-")<cr>
vnoremap <silent> #/ <esc> :call MyCommentRegion("/")<cr>
vnoremap <silent> #: <esc> :call MyCommentRegion(":")<cr>
vnoremap <silent> #< <esc> :call MyCommentRegion("<")<cr>
vnoremap <silent> #<char-0x23> <esc> :call MyCommentRegion("#")<cr>
vnoremap <silent> #u <esc> :call MyCommentRegion("u")<cr>

"" init gvim
if has("gui_running")
    if exists("+columns")
        set columns=161
    endif
    if exists("+lines")
        set lines=80
    endif
    "" https://www.bulafish.com/centos/2018/05/05/change-vim-color-scheme/
    "" colorscheme blue
    "" colorscheme darkblue
    "" colorscheme default
    "" colorscheme delek
    "" colorscheme desert
    "" colorscheme elflord
    "" colorscheme evening
    "" colorscheme koehler
    "" colorscheme morning
    "" colorscheme murphy
    "" colorscheme pablo
    "" colorscheme peachpuff
    "" colorscheme ron
    "" colorscheme shine
    "" colorscheme slate
    colorscheme torte
    "" colorscheme zellner
endif
if has("gui_gtk2")
    set guifont=Monospace:h8
elseif has("gui_macvim")
    set guifont=Menlo:h8
    set transparency=10
elseif has("gui_win32")
    set guifont=Consolas:h8
endif

"" source ~/.vimrc2
if filereadable(expand('~/.vimrc2'))
    source ~/.vimrc2
endif

"" source ~/.vim/jslint_wrapper_vim.vim
if filereadable(expand('~/.vim/jslint_wrapper_vim.vim'))
    source ~/.vim/jslint_wrapper_vim.vim
endif


"" this function will cpplint file of current buffer
"" before using, please save cpplint.py to ~/.vim/cpplint.py, e.g.:
"" curl -L https://raw.githubusercontent.com/cpplint/cpplint/1.5.5/cpplint.py > ~/.vim/cpplint.py
function! SaveAndCpplint(bang)
    "" save file
    if a:bang == "!" | write! | else | write | endif
    let l:file = " \"" . fnamemodify(bufname("%"), ":p") . "\" "
    "" indent file
    if &filetype == "c" && (
        \ filereadable(expand("~/.vim/indent"))
        \ || filereadable(expand("~/.vim/indent.exe"))
    \)
        let l:tmp = ""
            \ . " \"" . $HOME . "/.vim/indent\""
            \ . " --blank-lines-after-commas"
            \ . " --braces-on-func-def-line"
            \ . " --break-function-decl-args"
            \ . " --break-function-decl-args-end"
            \ . " --dont-line-up-parentheses"
            \ . " --k-and-r-style"
            \ . " --line-length78"
            \ . " --no-tabs"
            \ . " -bfde"
            \ . l:file
        "" debug tmp
        "" echo l:tmp
        let l:tmp = system(l:tmp)
        "" reload file, remove carriage-return, resave
        edit
        set ff=unix
        "" save file
        if a:bang == "!"
            write!
        else
            write
        endif
    endif
    "" cpplint file
    let &l:errorformat = '%f:%l:  %m [%t]'
    "" let &l:errorformat = "%a%f:%l:  %m [%t],%-g%.%#"
    let &l:makeprg = "python \"" . $HOME . "/.vim/cpplint.py\""
        \ . " --filter=-whitespace/comments"
        \ . l:file
    silent make!
    cwindow
    redraw!
endfunction

"" create vim-command ":SaveAndCpplint"
command! -nargs=* -bang SaveAndCpplint call SaveAndCpplint("<bang>")

"" this function will jslint the file of current buffer after saving it.
"" before using, please save jslint.mjs to ~/.vim/jslint.mjs, e.g.:
"" curl -L https://www.jslint.com/jslint.mjs > ~/.vim/jslint.mjs
function! MySaveAndLint(bang)
    "" cpplint file
    if &filetype == "c" || &filetype == "cpp"
        SaveAndCpplint
        return
    endif
    "" jslint file
    if &filetype == "javascript" && filereadable(expand("~/.vim/jslint_wrapper_vim.vim"))
        SaveAndJslint
        return
    endif
    "" save file
    if a:bang == "!"
        write!
    else
        write
    endif
endfunction

"" init command :MySaveAndLint
command! -nargs=* -bang MySaveAndLint call MySaveAndLint("<bang>")

"" map vim-key-combo "<ctrl-s> <ctrl-j>" to ":MySaveAndLint"
inoremap <c-s><c-l> <esc> :MySaveAndLint <cr>
nnoremap <c-s><c-l> :MySaveAndLint <cr>
