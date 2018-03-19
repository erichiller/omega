# dircolors


## A note on `/mnt` for Windows files

Windows directory files will **_always_** be marked as **EXECUTABLE**, see [issue #936](https://github.com/Microsoft/BashOnWindows/issues/936)

> EXEC IS UNAVOIDABLE ON WINDOWS DIRS

One last thing, because WSL makes all windows files executable and because ls colors executable files in a specific color regardless of filetype, the coloring is not perfect when looking at windows files. I have not figured out a way to solve this that doesn’t involve recompiling ls. So my solution was simply to change the row in dircolors.256dark that reads
---
`EXEC 00;38;5;64`  
into  
`EXEC 00;38;5;244`




## Setting up `dircolors` file

See info coreutils 'dircolors invocation' and <http://www.bigsoft.co.uk/blog/index.php/2008/04/11/configuring-ls_colors>

Start file with:

`COLOR tty`

[Read here on how to set 24-bit xterm color sequences](http://conemu.github.io/en/AnsiEscapeCodes.html#SGR_Select_Graphic_Rendition_parameters)
```
ESC [ 38 ; 2 ; r ; g ; b m    => Set xterm 24-bit text color, r, g, b are from 0 to 255
ESC [ 48 ; 2 ; r ; g ; b m    => Set xterm 24-bit background color, r, g, b are from 0 to 255
//// remember that ESC [ and m are already provided for in dircolors
//// Try -> resetting text color first of *.ext
ESC [ 39 m         => Reset text color to defaults
ESC [ 49 m         => Reset background color to defauls
//// bright colors are: (they might be 01;Xx too)
ESC [ 90…97 m      => Set bright ANSI text color
ESC [ 100…107 m => Set bright ANSI background color
```

[see raw output](https://github.com/Microsoft/BashOnWindows/issues/880#issuecomment-267361267): 

    TERM=xterm-old && powershell

_These options may also need to be included:_
```
alias dir="dir --color=auto"
alias grep="grep --color=auto"
alias dmesg='dmesg --color'
;;; check if bash autocomplete is installed (see file)
;;;
shopt -s histappend
;;;;
shopt -s checkwinsize
;;;;; THIS FOR DIR-COLORS
OPTIONS -F -T 0
```

## Some Useful Tricks


- [UTF-8 CHARACTERS IN PS1](http://ezprompt.net)
- `PS1=$'\\[\e[31m\\]\u2234` from [Stack Overflow](https://unix.stackexchange.com/questions/25903/awesome-symbols-and-characters-in-a-bash-prompt)

## References

- <https://www.hanselman.com/blog/SettingUpAShinyDevelopmentEnvironmentWithinLinuxOnWindows10.aspx>
- <https://medium.com/@Andreas_cmj/how-to-setup-a-nice-looking-terminal-with-wsl-in-windows-10-creators-update-2b468ed7c326>
- <http://geekslop.com/2016/windows-subsystem-for-linux-wsl-howto-install-hacking-toolkit-windows-10>
- <http://cnswww.cns.cwru.edu/~chet/bash/FAQ>
