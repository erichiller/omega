


## save modules to psmodules
## clone github dirs

## update native psmodules



<# PSColor
Github		https://github.com/Davlind/PSColor
PS Gallery	https://www.powershellgallery.com/packages/PSColor/1.0.0.0
PS Get		http://psget.net/directory/PSColor/
Install-Module PSColor
Import-Module PSColor



# Create Shortcut / Launcher
```powershell
$TargetFile = "$env:HomePath\AppData\omega\system\ConEmu\ConEmu64.exe"
$ShortcutFile = "$env:HomePath\AppData\omega\omega.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)

$Shortcut.TargetPath = $TargetFile

$Shortcut.Arguments = '/LoadCfgFile "%HomePath%\AppData\omega\config\ConEmu.xml" /FontDir "%HomePath%\AppData\omega\system\nerd_hack_font" /Icon "%HomePath%\AppData\omega\icons\omega_256.ico" /run "@%HomePath%\AppData\omega\config\powershell.cmd"'

$Shortcut.WorkingDirectory = "$env:HomePath"

$Shortcut.IconLocation = "$env:HomePath\AppData\omega\icons\omega_256.ico"

$Shortcut.Save()
```
Add hotkey? ->
 ```
 oLink.HotKey = "ALT+CTRL+F"
 ```
[MS-SHLLINK- Shell Link Binary File Format - Spec from Microsoft](https://msdn.microsoft.com/en-us/library/dd871305.aspx)
#>