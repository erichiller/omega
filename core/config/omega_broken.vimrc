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
set backspace=indent,eol,start  " make the backspace key work the way it should
set showmode                    " show the current mode
set wrapmargin=1                " space around frame for wrapping
set textwidth=0                 " wrap based on the window, not a static value
set scrolloff=5                 " number of screen lines to keep above and below the cursor
set backup                      " backups are nice ...
set ttyfast                     " force faster redraw

" Path to Python 3.5 -- python35.dll is sought
let $PYTHONPATH=$VIM."\\..\\system\\python36"
" Path needs to be edited so that ViM can reach lua
let $PATH.=";".$VIM."\\..\\..\\bin"

"""""""""""""""""""""""""""""""""""""""""""""""""""""
" the following is for preserving files and settings
" see :help swap
"""""""""""""""""""""""""""""""""""""""""""""""""""""
if !isdirectory($TEMP . "/vimfiles")
	execute mkdir($TEMP . "\\vimfiles")
endif
if !isdirectory($TEMP . "/vimfiles/swap")
	execute mkdir($TEMP . "\\vimfiles\\swap")
endif
if !isdirectory($TEMP . "/vimfiles/backup")
	execute mkdir($TEMP . "\\vimfiles\\backup")
endif
set directory=$TEMP/vimfiles/swap
set backupdir=$TEMP/vimfiles/backup
" make windows function much as *nix
if has('win32') || has('win64')
    set runtimepath=$VIM/../vimfiles
    set runtimepath+=$VIM/vimfiles
    set runtimepath+=$VIMRUNTIME
    set runtimepath+=$VIM/vimfiles/after
    set runtimepath+=$VIM/../vimfiles/after
    set packpath=$VIM/../vimfiles
    " http://vimdoc.sourceforge.net/htmldoc/options.html#'viminfo'
    set viminfo+=n$TEMP/vimfiles/viminfo
    set undodir=$TEMP/vimfiles/undo
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
set cursorline                  " Highlight the current line
set history=50					" keep 50 lines of command line history
set wildmode=list:longest       " show suggestions in the command line for vim <Tab> triggered
set showcmd					    " don't display commands
set hlsearch					" highlight search terms
set showmatch                   " automatically show matching brackets. works like it does in bbedit.
set incsearch					" do incremental searching
set smartcase                   " don't ignorecase if searched word starts with a capital letter, must be combined with ignorecase
set ignorecase					" ignore case / no case sensitivity when searching
set autoread                    " read in filechanges when they are made by an external program

set encoding=utf-8
""""""" spell settings """"""""
" set spelllang=en              " defaulted to english anyways
""""""" For REGEX """"""""
" these two lines fix vim's regex implrementation so that it uses the standard pcre
" this clears out the search results
nnoremap <leader><space> :noh<cr>
" set TAB key to execute parenthesis/bracket matching
nnoremap <tab> %
vnoremap <tab> %

set listchars=tab:>.,trail:.,extends:#,nbsp:. " Highlight problematic whitespace

" browsedir // http://vimhelp.appspot.com/options.txt.html#%27browsedir%27
set browsedir=buffer            " when opening a new file using the file browse dialog, what should the open folder be?
                                " last , buffer , current , or {path}
set nohidden                    " I've set this explicitly even though it is default;
                                " Buffer isunloaded when it is abandoned.


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

" Show EOL type and last modified timestamp, right after the filename
" see statusline " http://vimdoc.sourceforge.net/htmldoc/options.html#'statusline'
" %c is the byte line number
" %V is the 'virtual line number' meaning multi-byte characters could only be +1 V but >1 c /or/ a tab would be >1 v but c=1
set statusline=%{fugitive#statusline()}%<%F%h%m%r\ %y\ (%{strftime(\"%H:%M\ %d/%m/%Y\",getftime(expand(\"%:p\")))})%=[0x%B(%b)]\ C%v\ L%l\|%L\ %p%%



" leader key ---- http://learnvimscriptthehardway.stevelosh.com/chapters/06.html
" :let mapleader = "-"

set confirm						" raise a dialog asking if you wish to save the current file(s).

" set win32 defaults
source $VIMRUNTIME/mswin.vim
" modify guioptions // win32 default is ----| egmrLtT |----

" <---- GUI ( gvim ) Settings ----
if has('gui_running')
    set lines=42                " 40 lines of text instead of 24,
    " FONT == SEE ==> http://vimhelp.appspot.com/options.txt.html#%27guifont%27 
    set guifont=Consolas:h9:cANSI:qDEFAULT,Courier\ New:h10:cANSI:qPROOF
    
    " GUI configurations, see guioptions
    " http://vimdoc.sourceforge.net/htmldoc/options.html#'guioptions'
    set guioptions-=T           " remove the toolbar
    set guioptions-=t           " remove the tearoff

    " only show a brief filename for the tab title
    set guitablabel=%F

    " menu
    an 10.310.100 &File.Open\ File.New\ Tab	:browse tabnew<CR>
    an 10.310.120 &File.Open\ File.&OverWrite\ Window  :browse confirm e<CR>
    an 10.310.140 &File.Open\ File.Sp&lit\ Window	:browse sp<CR>

    an 10.325 &File.&New\ Tab<Tab>			:tabnew<CR>
    an 10.325 &File.New\ &Split<Tab>			:vnew<CR>

    aunmenu File.Open\.\.\.
    " remove Open Tab, rename
    aunmenu File.Open\ Tab\.\.\.
    " rename split
    aunmenu File.Split-Open\.\.\.
    " rename new, it should also do a new TAB
    aunmenu File.New
    aunmenu File.Close

    " add SPLIT HORIZONTAL add SPLIT VERTICAL
    aunmenu Window
    menu 10.327 &File.---Window---	:
    an 10.328 &File.S&plit\ Horizontally		<C-W>s
    an 10.329 &File.Split\ &Vertically	<C-W>v

    an 10.630 &File.Exit\ without\ Session  :let g:session_autosave='no'<CR>:qa<CR>

    amenu 20.312    &Edit.Toggle\ history   <Esc>:MundoToggle<CR>
    amenu 20.362   &Edit.Toggle\ Comment   <plug>NERDCommenterToggle

    :an <silent> 10.330 &File.&Close\ Window<Tab>Selected
	\ :if winheight(2) < 0 && tabpagewinnr(2) == 0 <Bar>
	\   confirm enew <Bar>
	\ else <Bar>
	\   confirm close <Bar>
	\ endif<CR>


    amenu 30.20 &Tools.Silver\ Search   :Fkb<space>
    amenu 30.40 &Tools.------	:

    " au BufUnload * call <SID>BMRemove()

endif
" ---- end gui settings ---->



"------------------------------------------------------------------------------
" Only do this part when compiled with support for autocommands.
if has("autocmd")

    autocmd BufWinEnter * if empty(expand("%:e")) && !did_filetype() | setfiletype markdown | endif

    augroup markdown
        autocmd!

        " set .txt and .md as markdown 
        autocmd BufNewFile,BufFilePre,BufRead *.md,*.txt set filetype=markdown

        
        autocmd FileType markdown setlocal wrap linebreak nolist
        " these are local-only modifications to markdown type buffers
        autocmd FileType markdown setlocal linespace=2 " DOES LINESPACE APPLY TO CTERM????? UNKNOWN????

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
        autocmd FileType markdown nmap ff :TableFormat<CR>
        autocmd FileType markdown nmap tt :Toc<CR>
    augroup END

    "Set UTF-8 as the default encoding for commit messages
    autocmd BufReadPre COMMIT_EDITMSG,git-rebase-todo setlocal fileencodings=utf-8

    "Remember the positions in files with some git-specific exceptions"
    " autocmd BufReadPost *
    "   \ if line("'\"") > 0 && line("'\"") <= line("$")
    "   \           && expand("%") !~ "COMMIT_EDITMSG"
    "   \           && expand("%") !~ "ADD_EDIT.patch"
    "   \           && expand("%") !~ "addp-hunk-edit.diff"
    "   \           && expand("%") !~ "git-rebase-todo" |
    "   \   exe "normal g`\"" |
    "   \ endif

      autocmd BufNewFile,BufRead *.patch set filetype=diff
      autocmd BufNewFile,BufRead *.diff set filetype=diff

      autocmd Syntax diff
      \ highlight WhiteSpaceEOL ctermbg=red |
      \ match WhiteSpaceEOL /\(^+.*\)\@<=\s\+$/

      autocmd Syntax gitcommit setlocal textwidth=74
endif " has("autocmd")

" map CTRL+SPACE in _normal_ and _insert_ modes to bring the spell popup up
inoremap <C-SPACE> <C-X><C-S>
noremap <C-SPACE> <C-X><C-S>

inoremap <C-D> <ESC>dd
noremap <C-D> dd

" setup a new file with filetype specific values
fun! NewFileSetup()
    set background=dark             " Use colours that work well on a dark background (Console is usually black)
    " these are placeholders after markdown
    if &ft =~ 'markdown\|filetype2\|filetype3'
        setlocal nonumber
        setlocal laststatus=0
        " colorscheme edh
        colorscheme srcery
        setlocal spell
        let b:browsefilter = "Markdown Files\t*.md\nMarkdown Text\t*.txt\nAll Files\t*.*\n"
        
        amenu 30.30 &Tools.Format\ Table    :TableFormat<CR>
        amenu 30.31 &Tools.Table\ of\ Contents    :Toc<CR>
        return
    endif
    colorscheme srcery
    setlocal number                 " turn on line numbers
    " make the last line (status) always present
    " http://vimhelp.appspot.com/options.txt.html#%27laststatus%27
    set laststatus=2                
endfun

autocmd BufWinEnter * call NewFileSetup()

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
    
    " """"""""""""""""""""""""""""""""""""""
    " "" mouse wheel scroll file contents ""
    " """"""""""""""""""""""""""""""""""""""
    " " issue with scrolling
    " " https://github.com/Maximus5/ConEmu/issues/1007
    set mouse=a

    " " this fixes backspace when in xterm
    inoremap <Char-0x07F> <BS>
    nnoremap <Char-0x07F> <BS>
    " may need map instead to fix backspace in the : command mode
endif

" The window that the mouse pointer is on is automatically activated.
set mousefocus
" Hide mouse when typing
set mousehide
set showtabline=1


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
let g:neocomplete#data_directory='$TEMP\vimfiles\cache\neocomplete\'
" cache max filesize normally 500,000 ; but the dictionary file is ~1,300,000; times 10
let g:neocomplete#sources#buffer#cache_limit_size=5000000
if !exists('g:neocomplete#sources')
  let g:neocomplete#sources = {}
endif


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
let g:NERDMenuMode = 0
let g:NERDSpaceDelims = 1
let g:NERDCreateDefaultMappings = 0
" CTRL+/ now comments the current line
map <C-/> <plug>NERDCommenterToggle<CR>

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
"""""""""""" for sessions """"""""""""
" The directory to save/load sessions to/from.
let g:startify_session_dir=$TEMP.'\vimfiles\sessions'
" Automatically update sessions
" let g:startify_session_persistence = 1


" Auto-Save Session options (see vim-sessions-> https://github.com/xolox/vim-session )
let g:session_verbose_messages=1
" If it's gvim -> prompt to save at close, else (console) do not save session
if has("gui_running") | let g:session_autosave = "prompt" | else | let g:session_autosave = "no" | endif
let g:session_autoload = 'no' " no=ask the user if they want to load the session if no file is provided
let g:session_autosave_periodic=1
let g:session_directory=$TEMP.'\vimfiles\sessions'
let g:session_autosave_silent=1
" could :: below :: to save paths of session
" xolox#session#path_to_name()
" xolox#session#name_to_path()
"""""""""""" for sessions """"""""""""
" see: http://vimdoc.sourceforge.net/htmldoc/options.html#'sessionoptions'
set sessionoptions+=globals,localoptions,resize,tabpages,winpos,winsize
" no need to restore help windows!
set sessionoptions-=help
" set the default session name based on date
" timestamp options: http://vim.wikia.com/wiki/Insert_current_date_or_time
let g:session_default_name=strftime('%Y-%m-%d_%H%M-%S')




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
let $kb="$HOME\\Documents"

command -nargs=* Fkb :lcd $kb | :Ack <args>
function Fkb(term)
    lcd $kb
    Ack a:term
endfunction



" 
" Reference & Notes
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" ### UPDATE HELP TAGS ###
" Upon installing a new plugin, be sure to install it's help as well with
" :helptags ALL
" 
" ### Shortcut for GVIM in Start Menu ###
" `C:\Users\ehiller\AppData\Local\omega\system\vim\gvim.exe -u %LocalAppData%\omega\config\omega.vimrc`
" 
" * Locate into `$basedir\system\vimpack\`
"   - `pack`
"   - `spell` (removed)
" * Locate into `$env:temp\vimfiles\`
"   - `sessions`
"   - `cache`
"   - `swap`
" 
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" " Bug list " "
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" [*] colors in GVIM/startify
" [*] lua dll
" [*] undo directory?
" [*] VIMINIT ; removed need for `vim.cmd`. VIMINIT set in profile.ps1 <http://vimdoc.sourceforge.net/htmldoc/starting.html#VIMINIT>
" [*] lua dll // filepath // C:\Users\ehiller\AppData\Local\omega\bin
" [*] sessions NOT in ~/vimfiles/sessions
" [*] sessions prompt for save on close in gui; never in console
" [*] spell only on <CTRL+SPACE> in markdown, normal autocomplete otherwise
" [*] commenter setup to standard (for me) <CTRL+/>
" 
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" " Improvement list " "
"""""""""""""""""""""""""""""""""""""""""""""""""""""
" [*] undo in gui menu
" - vim-jsx
" - vim-fugitive

" ??? Considerations ???
" --> use spaces, not tabs (maybe)
"       http://vimdoc.sourceforge.net/htmldoc/options.html#'expandtab'
" # review GLOBAL (set) vs. LOCAL (setlocal) options
"       [setlocal](http://vimdoc.sourceforge.net/htmldoc/options.html#local-options)
"       [options/set](http://vimdoc.sourceforge.net/htmldoc/options.html#options)
" 
" 



" # Create packages
" 1. ViM
" 2. vimpack
" 3. vimdict? / vimspell?
