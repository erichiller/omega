# Terminal issues

Characters not being displayed corretly and characters being incorrect crop up in Windows -> Linux (or even Windows -> Windows) systems.


    read -n 1 a ; echo $a | hexdump -C

Some tools to help diagnose:


- inputrc & [bind manpage](https://ss64.com/bash/bind.html)
- [hexdump](https://www.freebsd.org/cgi/man.cgi?query=hexdump&sektion=1)
- [ASCII lookup tables](http://www.rapidtables.com/code/text/ascii-table.htm)
- [read manpage](https://ss64.com/bash/read.html)




# Bind commands

`bind -V`:

```bash
skip-completed-text is set to `off'
completion-display-width is set to `-1'
completion-prefix-display-length is set to `0'
keymap is set to `emacs'

mark-symlinked-directories is set to `off'
bind-tty-special-chars is set to `on'


expand-tilde is set to `off'
colored-stats is set to `off'
```

`bind -P` shows current mappings of commands to keysequences

```bash
C-h
C-?
```
set bell-style none
set show-all-if-ambiguous on



[old inputrc](https://github.com/erichiller/cmder/blob/master/config/inputrc)

conemu

https://github.com/Maximus5/ConEmu/issues/641

[ConEmu vim issues and solutions](http://conemu.github.io/en/VimXterm.html#vim-bs-issue)

[terminal codes](http://wiki.bash-hackers.org/scripting/terminalcodes)

[how Putty handles character encodings](https://www.ssh.com/ssh/putty/putty-manuals/0.68/Chapter4.html)

[a history of backspace and delete](http://www.ibb.net/~anne/keyboard.html)

Diagnosing the strange block looking backspace character that arises when using `backspace` in conemu -> `ssh` -> `apt upgrade`
using the above `read` to `hexdump` command yields `7f` for both conemu ssh and nas kvm


# SSH commands

[ssh config manpage](https://man.openbsd.org/ssh_config)
[ssh client](https://man.openbsd.org/ssh.1) - see the verbosity escape character commands.


# The Result

The actual problem is not one with ConEmu, nor Windows itself. But rather with Git for Windows - which [has problems supporting Unicode](https://github.com/msysgit/msysgit/wiki/Git-for-Windows-Unicode-Support)

**Solutions?**

1. Wait for git to gain support
2. SSH for Powershell --
    1. ensure that `$env:TERM` is empty or missing. Because it sets it to `xterm-256color`



## Stty 

https://unix.stackexchange.com/questions/13413/force-telnet-ssh-to-use-crtl-h-for-backspace

**the fix is** to set `stty erase ^h` and use windows ssh.exe


speed 9600 baud; rows 41; columns 169; line = 0;

intr = ^C; 
quit = ^\; 
erase = ^?; 
kill = ^U; 
eof = ^D; 
eol = <undef>; 
eol2 = <undef>; 
swtch = <undef>; start = ^Q; stop = ^S; susp = ^Z; rprnt = ^R; werase = ^W;
lnext = ^V; discard = ^O; min = 1; time = 0;
-parenb -parodd -cmspar cs8 -hupcl -cstopb cread -clocal -crtscts
-ignbrk -brkint -ignpar -parmrk -inpck -istrip -inlcr -igncr icrnl ixon -ixoff -iuclc -ixany -imaxbel -iutf8
opost -olcuc -ocrnl onlcr -onocr -onlret -ofill -ofdel nl0 cr0 tab0 bs0 vt0 ff0
isig icanon iexten echo echoe echok -echonl -noflsh -xcase -tostop -echoprt echoctl echoke -flusho -extproc




`chcp utf-8` windows <https://technet.microsoft.com/en-us/library/bb490874.aspx>


[x] cygwin
pcansi
ansi
[x] rxvt
rxvt-unicode
[x] vt100
[x] vt102  vt220  vt52
xterm
[x] xterm-256color  
xterm-debian
  xterm-mono  xterm-r5  xterm-r6  
[x] xterm-vt220
xterm-xfree86



[tset](http://invisible-island.net/ncurses/man/tset.1.html#h2-OPTIONS)
