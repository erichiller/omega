


## save modules to psmodules
## clone github dirs

## update native psmodules

<#
Set-ExecutionPolicy Bypass

#>

<# PSColor
Github		https://github.com/Davlind/PSColor
PS Gallery	https://www.powershellgallery.com/packages/PSColor/1.0.0.0
PS Get		http://psget.net/directory/PSColor/
Install-Module PSColor
Import-Module PSColor



check for 7zip in program files (ConEmu requires it)


# Create Shortcut / Launcher
```powershell
$TargetFile = "$env:HomePath\AppData\Local\omega\system\ConEmu\ConEmu64.exe"
$ShortcutFile = "$env:HomePath\AppData\Local\omega\omega.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)

$Shortcut.TargetPath = $TargetFile

$Shortcut.Arguments = '/LoadCfgFile "%HomePath%\AppData\Local\omega\config\ConEmu.xml" /FontDir "%HomePath%\AppData\Local\omega\system\nerd_hack_font" /Icon "%HomePath%\AppData\Local\omega\icons\omega_256.ico" /run "@%HomePath%\AppData\Local\omega\config\powershell.cmd"'

$Shortcut.WorkingDirectory = "$env:HomePath"

$Shortcut.IconLocation = "$env:HomePath\AppData\Local\omega\icons\omega_256.ico"

$Shortcut.Save()
```
Add hotkey? ->
 ```
 oLink.HotKey = "ALT+CTRL+F"
 ```
[MS-SHLLINK- Shell Link Binary File Format - Spec from Microsoft](https://msdn.microsoft.com/en-us/library/dd871305.aspx)



# git for windows repo
https://github.com/git-for-windows/git/releases
# portablegit seems best

Grab the fresh release from the [npm github repo](https://github.com/npm/npm)

#>