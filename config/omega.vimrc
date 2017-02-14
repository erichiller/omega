"""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""" ERIC's ViM CONFIG """"""""""""""""" 
"""""""""""""""""" 31 JANUARY 2016 """"""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" http://vimdoc.sourceforge.net/htmldoc/options.html
"""""""""""""""""""""""""""""""""""""""""""""""""""""

" Setting some decent VIM settings for programming
" read the current settings with :set <variable>?
filetype plugin indent on
syntax on                       " turn syntax highlighting on by default
set nocompatible                " basic starting point for usability
set vb t_vb=                    " remove the flash and the beep
set ruler                       " show the cursor position all the time
set backspace=indent,eol,start  " make that backspace key work the way it should
set nocompatible                " vi compatible is LAME
set showmode                    " show the current mode
set wrapmargin=1                " space around frame for wrapping
set textwidth=0                 " wrap based on the window, not a static value
set scrolloff=5                 " number of screen lines to keep above and below the cursor
set ttyfast                     " force faster redraw
set hidden!                     " I've set this explicitly even though it is default;
                                " Buffer isunloaded when it is abandoned.

" Path to Python 3.5 -- python35.dll is sought
" set pythonthreedll=$BaseDir\system\python35\python35.dll
" let $PYTHONPATH = $BaseDir."\\system\\python35"
let $PYTHONPATH=$VIM."\\..\\system\\python35"
" Path needs to be edited so that ViM can reach lua
let $PATH.=";".$VIM."\\..\\..\\bin"

"""""""""""""""""""""""""""""""""""""""""""""""""""""
" the following is for preserving files and settings
" see :help swap
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set directory=~/.vim/swap/
" make windows function much as *nix
if has('win32') || has('win64')
    set runtimepath=$HOME/.vim
    set runtimepath+=$VIM/vimfiles
    set runtimepath+=$VIMRUNTIME
    set runtimepath+=$VIM/vimfiles/after
    set runtimepath+=$HOME/.vim/after
    set packpath=$HOME/.vim/
endif
set updatecount=20									" save every <updatecount> number of characters
set updatetime=2000									" save every 2000ms (2s)

"" EDH "" force tabs-not spaces "
set autoindent					" set auto-indenting on for programming; filetype plugin should
								" override this for smartindent / cindent depending on filetype
								" see: http://vim.wikia.com/wiki/Indenting_source_code
set noexpandtab                 " don't turn tabs into spaces
set tabstop=4					" EDH - standard 4 space=tab
set shiftwidth=4				" Number of spaces to use for each step of (auto)indent.
set number						" Show line numbers.
set cursorline                  " Highlight the current line
set history=50					" keep 50 lines of command line history
set wildmode=list:longest       " show suggestions in the command line for vim <Tab> triggered
set showcmd					    " don't display commands
set hlsearch					" highlight search terms
set showmatch                   " automatically show matching brackets. works like it does in bbedit.
set incsearch					" do incremental searching
set smartcase                   " don't ignorecase if searched word starts with a capital letter, must be combined with ignorecase
set ignorecase					" ignore case / no case sensitivity when searching
set nohidden                    " don't allow buffers to stay open when I close the tab

set encoding=utf-8
""""""" spell settings """"""""
" set spelllang=en              " defaulted to english anyways
""""""" For REGEX """"""""
set gdefault                    " global regex substitutions
" these two lines fix vim's regex implrementation so that it uses the standard pcre
" nnoremap / /\v                 
" vnoremap / /\v
" this clears out the search results
nnoremap <leader><space> :noh<cr>
" set TAB key to execute parenthesis/bracket matching
nnoremap <tab> %
vnoremap <tab> %


""""""""""""""""" THEMES """"""""""""""""""""
"set t_Co=256
" colorscheme delek " best I found, other considerations:
" darkblue
" slate
" murphy
" desert
" koehler
" colorscheme zellner
" from spf13:
" 	- peaksea
" 	- molokai
" 	- Solarized
colorscheme peaksea
set background=dark             " Use colours that work well on a dark background (Console is usually black)

set laststatus=2                " make the last line (status) always present - http://vimhelp.appspot.com/options.txt.html#%27laststatus%27
" Show EOL type and last modified timestamp, right after the filename
set statusline=%<%F%h%m%r\ %y\ (%{strftime(\"%H:%M\ %d/%m/%Y\",getftime(expand(\"%:p\")))})%=%l,%c%V\ %P


" leader key ---- http://learnvimscriptthehardway.stevelosh.com/chapters/06.html
" :let mapleader = "-"


set confirm						" raise a dialog asking if you wish to save the current file(s).

" set win32 defaults
source $VIMRUNTIME/mswin.vim
" modify guioptions // win32 default is ----| egmrLtT |----

" <---- GUI Settings ----
if has('gui_running')
    set lines=40                " 40 lines of text instead of 24,
    " FONT == SEE ==> http://vimhelp.appspot.com/options.txt.html#%27guifont%27 
    set guifont=Courier:h9:cANSI:qANTIALIASED
    
    " GUI configurations, menu
    set guioptions-=T           " remove the toolbar
    :aunmenu Window.New
    :amenu 70.301	Window.New\ Tab	:tabnew<CR>
endif
" ---- end gui settings ---->



"------------------------------------------------------------------------------
" Only do this part when compiled with support for autocommands.
if has("autocmd")

    " the initial startup / blank / empty file and 
    " any files without extensions and that are unable to have a filetype detected should be set as markdown
    " echomsg "has autocmd"
    " autocmd BufAdd * if empty(expand("%:e")) && !did_filetype() | set filetype=markdown | endif
    " autocmd BufAdd * if empty(expand("%:e")) && !did_filetype() | set filetype=markdown | endif
    " this handles filenames entered, but without an extension
    " autocmd BufNewFile * if empty(expand("%:e")) && !did_filetype() | set filetype=markdown | endif
    
    " autocmd filetypedetect BufRead,BufNewFile * echomsg "ftdetect test"
    " if @% == "" | echo "mark2-visible" | echomsg "mark2" | endif
    " autocmd BufAdd * echomsg "ftdetect BufAdd"
    " autocmd BufEnter * echomsg "ftdetect BufEnter"
    " autocmd BufWinEnter * echomsg "ftdetect BufWinEnter"

    autocmd BufWinEnter * if empty(expand("%:e")) && !did_filetype() | setfiletype markdown | endif

    augroup markdown
        autocmd!

        " set .txt and .md as markdown 
        autocmd BufNewFile,BufFilePre,BufRead *.md,*.txt set filetype=markdown

        
        autocmd FileType markdown setlocal wrap linebreak nolist
        " autocmd FileType markdown setlocal showbreak=…
        " autocmd FileType markdown setlocal showbreak=...

        autocmd FileType markdown setlocal nonumber

        autocmd FileType markdown colorscheme edh
        autocmd Filetype markdown setlocal spell

        """""""""""""""""""""""""""""""""""""""""""""""""""""
        " vim-markdown
        " https://github.com/plasticboy/vim-markdown
        """""""""""""""""""""""""""""""""""""""""""""""""""""
        " spaces that a sub-list item should be indented
        let g:vim_markdown_new_list_item_indent = 3
        " front matter , ie, for Hugo
        " json support via vim-json - https://github.com/elzr/vim-json
        let g:vim_markdown_json_frontmatter = 1
        let g:vim_markdown_toml_frontmatter = 1
        " folding is un-wanted I think
        let g:vim_markdown_folding_disabled = 1
        let g:vim_markdown_toc_autofit = 1
        let g:vim_markdown_fenced_languages = ['ps=ps1,powershell=ps1']
        " autocmd FileType markdown map <C-M> <Nop>
        " autocmd FileType markdown map! <C-M> <Nop>
        " autocmd FileType markdown map <Return> <CR>
        " autocmd FileType markdown map <C-O> <Nop>
        " autocmd FileType markdown map! <C-O> <Nop>
        autocmd FileType markdown nmap ff :TableFormat<CR>
        autocmd FileType markdown nmap tt :Toc<CR>
    augroup END

    "Set UTF-8 as the default encoding for commit messages
    autocmd BufReadPre COMMIT_EDITMSG,git-rebase-todo setlocal fileencodings=utf-8

    "Remember the positions in files with some git-specific exceptions"
    autocmd BufReadPost *
      \ if line("'\"") > 0 && line("'\"") <= line("$")
      \           && expand("%") !~ "COMMIT_EDITMSG"
      \           && expand("%") !~ "ADD_EDIT.patch"
      \           && expand("%") !~ "addp-hunk-edit.diff"
      \           && expand("%") !~ "git-rebase-todo" |
      \   exe "normal g`\"" |
      \ endif

      autocmd BufNewFile,BufRead *.patch set filetype=diff
      autocmd BufNewFile,BufRead *.diff set filetype=diff

      autocmd Syntax diff
      \ highlight WhiteSpaceEOL ctermbg=red |
      \ match WhiteSpaceEOL /\(^+.*\)\@<=\s\+$/

      autocmd Syntax gitcommit setlocal textwidth=74
endif " has("autocmd")

""""""""""""""""""""""""""""""""""""""""""
"""""""""""" For ConEmu """"""""""""""""""
" for more information see ConEmu docs
" http://conemu.github.io/en/VimXterm.html
""""""""""""""""""""""""""""""""""""""""""
if !has("gui_running")
    
    """"""""""""""""""""""""""""""""""""""
    """"""" For 256 colors in ConEmu """""
    """"""""""""""""""""""""""""""""""""""
    " more on 256 color themes:
    " http://vimdoc.sourceforge.net/htmldoc/syntax.html#highlight-ctermfg
    " See the all 256 colors in ConEmu 
    " cmd /c type "%ConEmuBaseDir%\Addons\AnsiColors256.ans"
    " http://conemu.github.io/en/AnsiEscapeCodes.html
    set term=xterm
    set t_Co=256
    let &t_AB="\e[48;5;%dm"
    let &t_AF="\e[38;5;%dm"
    """"""""""""""""""""""""""""""""""""""
    "" mouse wheel scroll file contents ""
    """"""""""""""""""""""""""""""""""""""
    " issue with scrolling
    " https://github.com/Maximus5/ConEmu/issues/1007
    set mouse=a
    set nocompatible
    inoremap <Esc>[62~ <C-X><C-E>
    inoremap <Esc>[63~ <C-X><C-Y>
    nnoremap <Esc>[62~ <C-E>
    nnoremap <Esc>[63~ <C-Y>

    " this fixes backspace when in xterm
    inoremap <Char-0x07F> <BS>
    nnoremap <Char-0x07F> <BS>
    " may need map instead to fix backspace in the : command mode
endif

set mousefocus " The window that the mouse pointer is on is automatically activated.
set mousehide " Hide mouse when typing
set showtabline=1


" Auto-Save Session options (see vim-sessions-> https://github.com/xolox/vim-session )
let g:session_verbose_messages = 0
let g:session_autosave = 'no'
let g:session_autoload = 'no' " no=ask the user if they want to load the session if no file is provided
let g:session_autosave_periodic = 1
set sessionoptions+=resize,tabpages,winpos,winsize
" no need to restore help windows!
set sessionoptions-=help


"""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""" neocomplete """""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" https://github.com/Shougo/neocomplete.vim
" for autocompletion / neocomplete
" options can be seen here:
" https://github.com/Shougo/neocomplete.vim/blob/master/doc/neocomplete.txt
set completeopt+=menu
" set completeopt=menu
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.typescript = '[^. *\t]\.\w*\|\h\w*::'
let g:neocomplete#data_directory='~\.vim\cache\neocomplete\'
" for spell autocomplete
" get spellfiles from here: http://app.aspell.net/create
if !exists('g:neocomplete#sources')
  let g:neocomplete#sources = {}
endif
" for more information see ::
" https://github.com/Shougo/neocomplete.vim/issues/548
" set the dictionaries that filetypes can use can use.
" comma separated ,"filetype" : "dictionary filepath"
" for information on the spell file format required see:
" Part#4 : Spell file format // *spell-file-format*
" http://vimdoc.sourceforge.net/htmldoc/spell.html
let g:neocomplete#sources#dictionary#dictionaries = {
        \ "markdown" : '~/.vim/spell/SCOWL_worldlist_novariant.txt'
        \ }
" g:neocomplete#min_keyword_length = 4 " default is 4


"""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""" typescript """"""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" https://github.com/Quramy/tsuquyomi.git
" using with neocomplete
" requires vimproc
" https://github.com/Shougo/vimproc.vim
" clone the repo as a normal plugin; 
" then get the binary windows x64 DLL from Releases and place in ./lib
" can test with :echo vimproc#cmd#system("dir") --> should print out directory
" requires typescript ; npm install -g typescript
" typescript syntax is from https://github.com/leafgarland/typescript-vim.git
let g:tsuquyomi_completion_detail = 1
let g:tsuquyomi_completion_preview = 1
let g:tsuquyomi_javascript_support = 1
if has("autocmd")
    augroup typescript
        " allow reading of embedded Javascript HTML templates and Markdown within typescript
        " https://github.com/Quramy/vim-js-pretty-template
        autocmd FileType typescript JsPreTmpl markdown
        autocmd FileType typescript setlocal completeopt+=menu,preview
    augroup END
    augroup javascript
        autocmd FileType javascript JsPreTmpl html
    augroup END
endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""" vim-go """"""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" git clone https://github.com/fatih/vim-go
" Once installed, within vim run
" :GoUpdateBinaries
if exists(':GoUpdateBinaries')
    let g:go_highlight_functions = 1
    let g:go_highlight_methods = 1
    let g:go_highlight_fields = 1
    let g:go_highlight_types = 1
    let g:go_highlight_operators = 1
    let g:go_highlight_build_constraints = 1
    let g:go_auto_type_info = 0
    " see possible mappings for vim-go with
    " :help go-command
    au FileType go nmap <leader>r <Plug>(go-run)
    au FileType go nmap <leader>b <Plug>(go-build)
    au FileType go nmap <leader>t <Plug>(go-test)

endif


"""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""" vim-ps1 """""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" powershell
" https://github.com/pprovost/vim-ps1
"""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ps1_nofold_blocks = 1


"""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""" nerd-comments """""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" https://github.com/scrooloose/nerdcommenter/blob/master/doc/NERD_commenter.txt
"""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:NERDCommentEmptyLines = 1
let g:NERDMenuMode = 1
let g:NERDSpaceDelims = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""
""""""""""""""""""""" vim-mundo """""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" ( undo tree visualization )
" https://github.com/simnalamburt/vim-mundo
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" allows for Ctrl-U in Insert Mode
imap <C-U> <Esc>:MundoToggle<CR>
" Allows for usage in normal mode (the mode in which you can do `:....`)
nmap <C-U> :MundoToggle<CR>
let g:mundo_preview_bottom = 1
" use python3
let g:mundo_prefer_python3 = 1
" let g:mundo_help = 1
let g:mundo_close_on_revert = 1
"""""""""""""""""""""""""""""""""""""""""""""""""""""
""" these settings are ViM standard Undo settings """
"""""""""""""""""""""""""""""""""""""""""""""""""""""
set backup 						                    " backups are nice ...
set undofile					                    " so it's persistent undo ...
set undolevels=1000                                 " maximum number of changes that can be undone
set undoreload=10000                                " maximum number lines to save for undo on a buffer reload


"""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""" START /// HIGHLIGHT CURRENT SEARCH RESULT """"
" http://vi.stackexchange.com/questions/2761/set-cursor-colour-different-when-on-a-highlighted-word
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" n to search forward
" N to search backwards
fun! SearchHighlight()
    silent! call matchdelete(b:ring)
    let b:ring = matchadd('ErrorMsg', '\c\%#' . @/, 101)
endfun
fun! SearchNext()
    try
        execute 'normal! ' . 'Nn'[v:searchforward]
    catch /E385:/
        echohl ErrorMsg | echo "E385: search hit BOTTOM without match for: " . @/ | echohl None
    endtry
    call SearchHighlight()
endfun
fun! SearchPrev()
    try
        execute 'normal! ' . 'nN'[v:searchforward]
    catch /E384:/
        echohl ErrorMsg | echo "E384: search hit TOP without match for: " . @/ | echohl None
    endtry
    call SearchHighlight()
endfun
" Highlight entry
nnoremap <silent> n :call SearchNext()<CR>
nnoremap <silent> N :call SearchPrev()<CR>
" Use <C-L> to clear some highlighting
nnoremap <silent> <C-L> :silent! call matchdelete(b:ring)<CR>:nohlsearch<CR>:set nolist nospell<CR><C-L>
"""""""""""""""""""""""" END /// HIGHLIGHT CURRENT SEARCH RESULT """"""""""""""""""""""""


"""""""""""""""""""""""""""""""""""""""""""""""""""""
" Startify
" ( a clean and useful ViM startup screen )
" https://github.com/mhinz/vim-startify/blob/master/doc/startify.txt
"""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:startify_commands = [
        \ ['Search Knowledge Base' , ':Fkb'],
        \ ['Vim Reference', 'h ref']
        \ ]
        " \ ':help reference',
        " \ {'h': 'h ref'},
        " \ {'m': ['My magical function', 'call Magic()']},
        " \ ]
let g:startify_fortune_use_unicode = 0
let g:startify_disable_at_vimenter = 0


" Ack
" grep / file search within ViM
" 
let g:ack_autofold_results=1
let g:ack_qhandler = "botright copen 30"
if executable('ag')
  let g:ackprg = 'ag --smart-case --silent --vimgrep'
endif
map <leader>f :AckWindow<space>
map <leader>ff :Ack<space>
map <leader>fff :Fkb<space>
let $kb="C:\\Users\\ehiller\\Documents"

command -nargs=* Fkb :lcd $kb | :Ack <args>
function Fkb(term)
    lcd $kb
    Ack a:term
endfunction



" 
" Reference & Notes
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" Upon installing a new plugin, be sure to install it's help as well with
" :helptags ALL
" 
" 
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" " Bug list " "
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" - colors in GVIM/startify
" [*] lua dll
" - undo directory?
" - VIMINIT
" - lua dll // filepath // C:\Users\ehiller\AppData\Local\omega\bin
" - sessions NOT in ~/vimfiles/sessions
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" " Improvement list " "
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" - undo in gui menu
