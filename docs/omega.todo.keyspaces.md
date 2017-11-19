
# Create _KeySpaces_


1. Go through all options of PSReadLine
2. Go through interesting functions/additions contained in my notes.
3. Create 'keyspace' ; what's for (applications) PowerShell, vim, etc; what's for the terminal (ConEmu)
    - try to align applications with vim
    - and terminal with bash
    !!!! But not at the expense of usability !
apps key or right alt? ;;; or left alt for ConEmu overrides the normal alt which will work for right alt.


https://github.com/lzybkr/PSReadLine/blob/8e851bfadbbe7cd5d898b2f01eb6cf010f684a71/PSReadLine/en-US/about_PSReadline.help.txt

https://github.com/lzybkr/PSReadLine/blob/master/PSReadLine/SamplePSReadlineProfile.ps1

====

## Options in ConEmu

(1) of **any non-modifier**
(up to 3) modifiers:
 - Win
 - Apps
 - CTRL
    - LCtrl
    - RCtrl
 - ALT
    - LAlt
    - RAlt
 - Shift
    - LShift
    - RShift


Ensure
Ctrl+A => select all, which is the line
Remap:
   ---> Ctrl+End => SelectLine => select from cursor to end of line
   ---> ctrl->start => SelectBackwardsLine // reverse above
/// Add alt+ to above to do just next/last word
// SelectNextWord , SelectBackwardWord
// Or if not start & end, use arrow keys
!! Check interference with ConEmu
!! # I need "key spaces"; x is for apps; y is for ConEmu
    ---- apps: PowerShell, vim, SSH
          Ctrl, Alt, Shift
    ---- ConEmu
           Apps Key?
           // But reserve apps Key+specials to numpad conversions



## `Ctrl+C`
Is Ctrl+C interfered with by ConEmu?
///Because this seems more useful
CopyOrCancelLine (Cmd: <Ctrl+C> Emacs: <Ctrl+C>)
Either copy selected text to the clipboard, or if no text is selected, cancel editing
the line with CancelLine.
## `Ctrl+Space`
// Same for Ctrl+Space
Map Ctrl+Space => MenuComplete
Map TAB => TabCompleteNext
                  // Or TabComplete

## `KeyUp`
// See function for //
KeyUp => HistorySearchBackward

## `Alt+Backspace`
///Map this; like bash
BackwardKillWord (Cmd: unbound Emacs: <Alt+Backspace>)
Clear the input from the start of the current word to the cursor. If the cursor
is between words, the input is cleared from the start of the previous word to the
cursor. The cleared text is placed in the kill ring.
// Or ShellBackwardKillWord
// Or UnixWordRubout
// Bash => http://www.skorks.com/2009/09/bash-shortcuts-for-maximum-productivity/
// `Ctrl+w` => delete backwards word

## Useful ideas
`Ctrl+u` => uppercase current word
`Ctrl+d` => delete line

Try setting `<ENTER>` to >> ValidateAndAcceptLine


//////////// START HELP //////////// 
// I really need a base/default help file
For now i could just have `man` execute a omega-Help.md file which displays it in vim or DOES VIM HAVE A LESS OR MORE COMMAND??!!

`WhatIsKey` (Cmd: <Alt+?>) Shows what a key chord does

YankLastArg (Cmd: <Alt+.> Emacs: <Alt+.>, <Alt+_>)
Insert the last argument from the previous command in history. Repeated operations
will replace the last inserted argument with the last argument from the previous
command (so Alt+. Alt+. will insert the last argument of the second to last history
line.)
With an argument, the first time YankLastArg behaves like YankNthArg. A negative
argument on subsequent YankLastArg calls will change the direction while going
through history. For example, if you hit Alt+. one too many times, you can type
Alt+- Alt+. to reverse the direction.
Arguments are based on PowerShell tokens.

GotoBrace (Cmd: <Ctrl+}> Emacs: unbound)
Go to the matching parenthesis, curly brace, or square bracket.



//////////// END HELP //////////// 


// Remap
Ctrl+L to Ctrl+Del => ClearScreen

//Crazy useful!
//Could use to PARENTHESIS a line!
CharacterSearch (Cmd: <F3> Emacs: <Ctrl+]>)
Read a key and search forwards for that character. With an argument, search
forwards for the nth occurrence of that argument. With a negative argument,
searches backwards.


/// Compare `undoAll()` vs `[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()` // revert line is like pressing escape.



Get-PSReadlineKeyHandler

;;;; The following functions are public in Microsoft.PowerShell.PSConsoleReadline, but cannot be directly
bound to a key. Most are useful in custom key bindings.
Example:
# AddToHistory saves the line in history, but does not execute the line.
[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
// See: "Custom Key Bindings" in about




void AddToHistory(string command)
Add a command line to history without executing it.

void Delete(int start, int length)
Delete length characters from start. This operation supports undo/redo.

void SetCursorPosition(int cursor)
Move the cursor to the given offset. Cursor movement is not tracked for undo

Void GetSelectionState([ref] int start, [ref] int length)
If there is no selection on the command line, -1 will be returned in both start and length.
If there is a selection on the command line, the start and length of the selection are returned.
// Is this used for ctrl+c?
…
