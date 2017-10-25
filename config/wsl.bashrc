[ -r /etc/profile ] && . /etc/profile
[ -r ~/.profile ] && . ~/.profile

# Basic requirements
ConEmuDir=$(pwd)
BaseDir=$(dirname $( dirname $ConEmuDir))
alias om='cd $BaseDir'
HOME=/mnt/c/Users/ehiller/
cd ~


#Golang
if [ -d "/c/Go" ] ; then
    export GOROOT=/c/go
    export GOPATH=~/dev
    export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
elif [ -d "$HOME/dev/lib/go" ] ; then
    export GOROOT=~/dev/lib/go
    export GOPATH=~/dev
    export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
fi

# for less / man coloring
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
            man "$@"
}


# for terminal line coloring
# test UTF-8 hex codes with `echo ∴ | hexdump -C`
export PS1=$'\\[\e[37;40m\\]\xef\x83\xa7 \\[\e[36m\\]\w \\[\e[32;40m\\]\xe2\x86\x92 '
none="$(tput sgr0)"
trap 'echo -ne "${none}"' DEBUG

# If this is an xterm set the title to dir
case "$TERM" in
xterm*|rxvt*|cygwin)
    export PS1="\[\e]0;\w\a\]$PS1"
    export SETTITLE="YES"
    ;;
*)
    ;;
esac

# search history by start of the current line
bind '"\eOA": history-search-backward'
bind '"\e[A": history-search-backward'
bind '"\eOB": history-search-forward'
bind '"\e[B": history-search-forward'

# ls dir coloring
export LS_OPTIONS='--color=auto'
eval "`dircolors -b $BaseDir/config/wsl_dir_colors`"
alias ls='ls $LS_OPTIONS -lA'
alias pathprint='echo $PATH | tr \: \\n'

# for grep coloring
alias grep='grep --color=always'
alias less='less -R'

# alias vim if we are on ConEmu
if [ -f $ConEmuDir/config/.vimrc ] ; then
    alias vi='vim -u $ConEmuDir/config/.vimrc'
    alias vim='vim -u $ConEmuDir/config/.vimrc'
fi

#### REMAINING TO-DO ####
# * colorize grep
# * use omega's vim

# may need to read input rc
# see startup sequence : https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html
# if this is global read user files, if it is local, I am done.