# ConEmu

## Settings Changes via GuiMacro `SetOption`

by CheckBox/RadioButton ID. Of course you must know that number-ID. Look up the control by its label in the [ConEmu.rc][conemurc] (don’t forget about possible ‘&’), and then look up the exact number-ID by its string-ID in the [resource.h][resourceh].

[conemurc]: https://github.com/Maximus5/ConEmu/blob/master/src/ConEmu/ConEmu.rc
[resourceh]: https://github.com/Maximus5/ConEmu/blob/master/src/ConEmu/resource.h


For example, turn scrollbar on:
```
ConEmuC -GuiMacro SetOption Check 2488 1
```

Turn Quake style activation off:
```
ConEmuC -GuiMacro SetOption Check 2333 0
```

Have Console display in taskbar
`SetOption Check 2472 1`

and turn off auto-minimize to tsa
`SetOption Check 1507 0`