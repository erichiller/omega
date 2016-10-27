# PowerShell Permissions & Access

## Elevated Permissions

You can not change the permission level of a process that already exists.

with [Start-Process](https://technet.microsoft.com/en-us/library/hh849848.aspx) the flag `-NoNewWindow` does not appear to operate in tandem with `-verb RunAs`. And `-cur_console:a` from [ConEmu](http://conemu.github.io/en/NewConsole.html) does not open an admin instance, but rather a standard one. Thus `...powershell.exe` always opens a new window.

A scriptblock (that is a set of commands encapsulated with `{...}`) can be passed and executed with `Start-Process` in elevated permissions , which is shown in the *PowerShell CookBook* example, but any output or input is not shown until the command is completed, thus I can not respond to any prompts, severly limited this approach's functionality.

See [ConEmu Issue #926](https://github.com/Maximus5/ConEmu/issues/926)

## Testing for elevated permissions

```powershell
function isadmin
{
	# Returns true/false
	([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}
```

## Etc.

[Module to manage NTFS file permissions](https://gallery.technet.microsoft.com/1abd77a5-9c0b-4a2b-acef-90dbb2b84e85)

## Sources:

 [SS64](http://ss64.com/nt/syntax-elevate.html)

 [Sudo and Sudo!!](https://stapp.space/run-last-command-in-elevated-powershell/)

 [Elevate program](http://code.kliu.org/misc/elevate/)

 