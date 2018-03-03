
$local:final_status_message = @{}

# load the core
. .\func.core.ps1

# must be admin
if ( Test-Admin -warn -not ) { return }

# set mxpBase
$env:mxpBase="${env:LOCALAPPDATA}\omega"
setx mxpBase /m "${env:mxpBase}"

# set SSH_AUTH_SOCK, primarily for Git
$env:SSH_AUTH_SOCK="${env:TEMP}\KeeAgent.sock"
setx SSH_AUTH_SOCK /m "${env:SSH_AUTH_SOCK}"
$local:final_status_message += "Be sure to set KeePass's KeeAgent AuthSock path to '${env:SSH_AUTH_SOCK}'"

# set GIT_CONFIG
$env:XDG_CONFIG_HOME=( Join-Path "${env:basedir}" "config" )
$env:GIT_CONFIG_NOSYSTEM=1
setx GIT_CONFIG_NOSYSTEM /m "1"
setx XDG_CONFIG_HOME /m "${env:XDG_CONFIG_HOME}"


# Install the newest PowerShellGet
Install-Module -Name PowerShellGet -Force
# Import the new version
Import-Module PowerShellGet -Force
# Install posh-git we require >= v1
Uninstall-Module posh-git
Install-Module -Name posh-git -AllowPrerelease -Force
Install-Module oh-my-posh
Install-Module PSColor


New-OmegaShortcut
Register-App

# End of program, display final_status_message (s)

Write-Output $local:final_status_message


####
# UPDATE PATHS FOR BINARIES AS NECESSARY:
# >>>> git
#       Update-SystemPath $env:basedir\system\git\cmd\
###


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
.



## init script must reset manifest.json file, 
or have a separate file with package statuses that is .gitignore'd


# GoLang package

https://storage.googleapis.com/golang/


#>