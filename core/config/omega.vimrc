"
" ViM - omega configuration
""""""""""""""""""""""""""""""""
" For additional docs, see the docs folder
" Some helpful commands:
" - read the current settings with 
"       :set <variable>?
" - start ViM in debug mode, logging to 'myVim.log'
"       vim -V9myVim.log
" - see all messages:
"       :messages
"       :echo errmsg

" Setting some decent VIM settings for programming
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
" set ttyfast                     " force faster redraw

" " Path to Python 3.5 -- python35.dll is sought
" let $PYTHONPATH=$VIM."\\..\\system\\python36"
" " Path needs to be edited so that ViM can reach lua
" let $PATH.=";".$VIM."\\..\\..\\bin"

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
" remap Home and End keys
nnoremap 0 $
nnoremap 9 0
inoremap <C-A> <Home>
inoremap <C-E> <End>
" make windows function much as *nix
if has('win32') || has('win64')
    source $VIMRUNTIME/mswin.vim
    set runtimepath=$VIM/../vimfiles
    set runtimepath+=$VIM/vimfiles
    set runtimepath+=$VIMRUNTIME
    set runtimepath+=$VIM/vimfiles/after
    set runtimepath+=$VIM/../vimfiles/after
    set packpath=$VIM/../vimfiles
    " http://vimdoc.sourceforge.net/htmldoc/options.html#'viminfo'
    " the prefixed `n` is for setting the name/path of the viminfo file.
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
" nnoremap <leader><space> :noh<cr>
" set TAB key to execute parenthesis/bracket matching
" nnoremap <tab> %
" vnoremap <tab> %

" set listchars=tab:>.,trail:.,extends:#,nbsp:. " Highlight problematic whitespace

" browsedir // http://vimhelp.appspot.com/options.txt.html#%27browsedir%27
set browsedir=buffer            " when opening a new file using the file browse dialog, what should the open folder be?
                                " last , buffer , current , or {path}
set nohidden                    " I've set this explicitly even though it is default;
                                " Buffer isunloaded when it is abandoned.


set laststatus=2
set statusline=%{fugitive#statusline()}%<%F%h%m%r\ %y\ (%{strftime(\"%H:%M\ %d/%m/%Y\",getftime(expand(\"%:p\")))})%=[0x%B(%b)]\ C%v\ L%l\|%L\ %p%%
" set statusline=Current:\ %4l\ Total:\ %4L



" leader key ---- http://learnvimscriptthehardway.stevelosh.com/chapters/06.html
" :let mapleader = "-"

set confirm						" raise a dialog asking if you wish to save the current file(s).

" set win32 defaults
" source $VIMRUNTIME/mswin.vim
" modify guioptions // win32 default is ----| egmrLtT |----


" map CTRL+SPACE in _normal_ and _insert_ modes to bring the spell popup up
" inoremap <C-SPACE> <C-X><C-S>
" noremap <C-SPACE> <C-X><C-S>

" inoremap <C-D> <ESC>dd
" noremap <C-D> dd



set noshowcmd
" Enable Colors
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
map <ScrollWheelUp> <C-Y>
map <ScrollWheelDown> <C-E>

" Fix arrow keys in xterm
inoremap <Esc>[A <Up>
inoremap <Esc>[B <Down>
inoremap <Esc>[C <Right>
inoremap <Esc>[D <Left>

" " this fixes backspace when in xterm
inoremap <Char-0x07F> <BS>
nnoremap <Char-0x07F> <BS>
