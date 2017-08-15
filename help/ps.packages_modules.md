# PowerShell Package Management

## Initialization

As **Administrator** run `Install-Module nuget`

From there normal `opkg` commands should work.

## Repositories

- [Technet/ScriptCenter](http://gallery.technet.microsoft.com/scriptcenter)

## Package-Management

[Main documentation](https://technet.microsoft.com/en-us/library/dn890706.aspx)

```powershell
Install-Package 1poshword
```
& `Uninstall-Package`

[Save-Package](https://technet.microsoft.com/en-us/library/dn890708.aspx)

_To install a package to a custom location you must use:_

```powershell
Save-Package -Path 'C:\Users\ehiller\AppData\omega\system\psmodules\' 1poshword
```

_And then import it with_
```powershell
Import-Module 1poshword
```

[Import-Module documentation](https://technet.microsoft.com/en-us/library/hh849725.aspx)

## Module Management

See: <https://technet.microsoft.com/en-us/library/hh847804.aspx>

`Import-Module` and [Remove-Module](https://technet.microsoft.com/en-us/library/hh849732.aspx)

Use:
- `Get-Module` to see active modules.
- `Get-Module -ListAvailable` to view all *installed* modules (but not imported) and their statuses.

`$env:psmodulepath` contains the locations of module search directories. The default is:
- `~\Documents\WindowsPowerShell\Modules`
- `C:\Program Files\WindowsPowerShell\Modules`
- `C:\Windows\system32\WindowsPowerShell\v1.0\Modules`

## Alias programs

[Set-Alias](https://technet.microsoft.com/en-us/library/ee176913.aspx)

