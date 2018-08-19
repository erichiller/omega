
function New-OmegaShortcut {
    $conf = [OmegaConfig]::GetInstance()
	#$Shortcut.Arguments = '/LoadCfgFile "%HomePath%\AppData\Local\omega\config\ConEmu.xml" /FontDir "%HomePath%\AppData\Local\omega\system\nerd_hack_font" /Icon "%HomePath%\AppData\Local\omega\icons\omega_256.ico" /run "@%HomePath%\AppData\Local\omega\config\powershell.cmd"'
	$arguments = `
	'/LoadCfgFile "' + ( Join-Path ( Join-Path $conf.Basedir $conf.confdir ) "ConEmu.xml" ) + '" ' + 
    '/FontDir "' + ( Join-Path (Join-Path $conf.Basedir $conf.sysdir) "fonts" ) + '" ' + 
    '/NoSingle ' +
    '/Icon "' + ( Join-Path ( Join-Path $conf.Basedir "icons" ) "omega_256.ico" ) + '" /run "@..\..\core\config\powershell.cmd"'

	$shortcutFile = Join-Path $conf.basedir "omega.lnk"

	$iconRelPath = "icons\omega_256.ico"

	$targetRelPath = ( Join-Path $conf.sysdir "ConEmu\ConEmu64.exe" )

	New-Shortcut -targetRelPath $targetRelPath -iconRelPath $iconRelPath -shortcutFile $shortcutFile -arguments $arguments
}

<#
.DESCRIPTION
Create directory junction from module base to psmodule path in program files if not already present
#>
function Register-Module {
    $conf = [OmegaConfig]::GetInstance()
    $parent = (split-path $conf.basedir -parent)
    if ( ( [System.Environment]::GetEnvironmentVariable("PSModulePath") -split ";" ) -Contains (split-path $conf.basedir -parent) ) {
        Write-Information "$($conf.name)'s parent directory <$parent> is already on the PSModulePath, no need to add"
    } else {
        New-Item -ItemType Junction -Path "C:\Program Files\WindowsPowerShell\Modules\$($conf.name)" -Value ( Join-Path $conf.basedir $conf.name )
        New-Item -ItemType Junction -Path "C:\Program Files\PowerShell\Modules\$($conf.name)" -Value ( Join-Path $conf.basedir $conf.name )
    }
}



<#
.DESCRIPTION
New Shortcut is a core function to create a shortcut with arguments to a target
.PARAMETER targetRelPath
targetRelPath is the file that will be called when the shortcut is called. Typically an exe.
.PARAMETER shortcutFile
shortcutFile is where the resulting shortcut will be placed
Defaults to C:\Users\ehiller\APPDATA\Microsoft\Windows\Start Menu\Programs\ + <baseName>
#>
function New-Shortcut {
	param(
		[Parameter(Mandatory = $true)]
			[string] $targetRelPath,
		[Parameter(Mandatory = $false)]
			[AllowEmptyString()]
			[AllowNull()]
			[string] $shortcutFile,
		[Parameter(Mandatory = $false)]
			[string] $iconRelPath,
		[Parameter(Mandatory = $false)]
			[string] $arguments,
		[Parameter(Mandatory = $false)]
			[bool] $RegisterApp = $False
	)
    $conf = [OmegaConfig]::GetInstance()

	# if no shortcut file is specified, create a default one in the start menu folder
	if ( -not $shortcutFile ) {
		# MUST BE ADMIN to create in the default start menu location;
		# check, if not warn and exit
		if ( -not (Test-Admin -warn) ) { return }
		Write-Debug $targetRelPath
		# get targetName without extension (or Parent directory/ path)
		$baseName = Split-Path -Path (Join-Path $conf.basedir $targetRelPath) -Leaf -Resolve
		Write-Debug $baseName
		$positionDot = $baseName.LastIndexOf(".")
		Write-Debug $positionDot
		if ($positionDot -gt 0) {
			$baseName = $baseName.substring(0, $positionDot)
			Write-Debug $baseName

		}
		Write-Debug $baseName
		$shortcutFile = Join-Path "${env:ALLUSERSPROFILE}\Microsoft\Windows\Start Menu\Programs\" $baseName
	}
	
	if (-not $shortcutFile.EndsWith(".lnk")) {
		$shortcutFile += ".lnk"
	}
	
	if ( -not ( Test-Path (Join-Path $conf.basedir $targetRelPath) ) ){
		Write-Warning "No item exists at target path: $targetRelPath, skipping shortcut creation"
		return $False
	}
	if ( -not ( Test-Path $iconRelPath ) ){
		Write-Warning "No item exists at icon path: $iconRelPath, skipping shortcut creation"
		return $False
	}

	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut( $shortcutFile )

	$Shortcut.TargetPath = Join-Path $conf.basedir $targetRelPath

	$Shortcut.Arguments = $arguments
		
	$Shortcut.WorkingDirectory = "$env:Home"

	$Shortcut.IconLocation = Join-Path $conf.basedir $iconRelPath

	$Shortcut.Save()
	Write-Output "Shortcut Created at $shortcutFile"

	if ( $RegisterApp ){
		$baseName = Split-Path -Path $shortcutFile -Leaf -Resolve
		$positionDot = $baseName.LastIndexOf(".")
		if ($positionDot -gt 0) {
			$baseName = $baseName.substring(0, $positionDot)
			Write-Debug "Registering $baseName"
			Register-App -appName $baseName -targetPath $Shortcut.TargetPath
		} else {
			Write-Warning "App had no name to register"
		}
	}
	return $True
}


<#
.SYNOPSIS
Register-App creates an entry for Omega in the App Paths registry folder to index omega in windows start search
New-Shortcut must have been run prior.
.PARAMETER appName 
appName is the name of the application that will be indexed
In the registry entry, .exe will be appended
If no value is provided, it defaults to omega
.PARAMETER targetPath
this is the path where the shortcut or exe to be linked to / executed is located
#>
function Register-App {

	param(
		# 
		[string]$appName = "omega",
		[string]$targetPath = "${env:basedir}\omega.lnk"
	)
    $conf = [OmegaConfig]::GetInstance()
	
	# add .exe suffix if not present asa the appPath requires it.
	# .exe will not show up in the index
	if (-not $appName.EndsWith(".exe")) {
		$appName += ".exe"
	}

	# extract target of shortcut from the shortcut itself
	# https://social.technet.microsoft.com/Forums/office/en-US/f0e20c30-834a-47f1-9a8c-8c719813f900/powershell-script-to-find-target-from-shortcuts-and-then-moverename-target-files?forum=winserverpowershell
	#$targetRelPath = Get-Item (New-Object -ComObject Wscript.Shell).CreateShortcut($shortcutPath).TargetPath
	
	# MUST BE ADMIN; check, if not warn and exit
	if ( -not (Test-Admin -warn) ) { return }
	
	#$shortcutPath = Join-Path $env:basedir $targetRelPath
	# if targetRelPath is a shortcut use that . set $shortcut=
	#     and set targetRelPath= the shortcut's target
	# else set $create shortcut = from a new shortcut
	# 
	if (Test-Path $targetPath ) {
		New-Item -Path $($conf.app_paths_key + "\$appName") -Value $targetPath
	}
	else {
		Write-Warning "The target to launch $appName does not yet exist"
		if ($appName -eq "omega") { Write-Warning "Create it first with 'New-Shortcut'" }
		Write-Warning "Checked in $targetPath"
	}
	
	# C:\Users\ehiller\AppData\Local\omega\system\vim\gvim.exe -u %LocalAppData%\omega\config\omega.vimrc
	
	# shortcuts in:
	# 	C:\Users\ehiller\AppData\Roaming\Microsoft\Windows\Start Menu\Programs
	
}