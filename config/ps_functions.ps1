<#
.Synopsis
 Helper Functions
#>

# Compatibility with PS major versions <= 2
if(!$PSScriptRoot) {
	$PSScriptRoot = $script:MyInvocation.MyCommand.Path
}

# load the core first
. $PSScriptRoot\func.core.ps1



function Omega-Help {
	### change this to user help system!!!
	### md -> manpages /// xml help?


	Write-Host -ForegroundColor Cyan "PowerShell Version" $PSVersionTable.PSVerson
	Write-Host -ForegroundColor Cyan "Windows Version" $PSVersionTable.BuildVersion
	Write-Host -ForegroundColor Magenta "See More with `$PSVersionTable"

	Write-Host -ForegroundColor DarkGray ( Get-Content ( ( Join-Path $env:BaseDir $OMEGA_CONF.helpdir | Join-Path -ChildPath "user" | Join-Path -ChildPath "omega.install.md" ) ) )

	Get-Content ( ( Join-Path $env:BaseDir $OMEGA_CONF.helpdir | Join-Path -ChildPath "user" | Join-Path -ChildPath "ps.cmdline_tips.md" ) )
	Get-Content -encoding UTF8 ( ( Join-Path $env:BaseDir $OMEGA_CONF.helpdir | Join-Path -ChildPath "user" | Join-Path -ChildPath "keys.conemu.md" ) )
}

<#
.Synopsis
 Display the commands Omega provides
#>
function Omega-CommandsAvailable {
	# print the table
	if ( $OMEGA_CONF.RegisteredCommands -ne $null ){
		$OMEGA_CONF.RegisteredCommands
	}
}
function Set-RegisterCommandAvailable ($command) {
	if ( $command -eq $null ){
		# if no command was sent, use the caller
		# powershell stack - get caller function
		$command = $((Get-PSCallStack)[1].Command)
	}
	# put the name and synopsis into the table
	$OMEGA_CONF.RegisteredCommands += (Get-Help $command | Select-Object Name, Synopsis)
}


<#
.Synopsis
 display the Path, one directory per line
 takes one input parameters, defaults to the env:Path
.LINK
Add-DirToPath
.LINK
Remove-DirFromPath
#>
function Show-Path { 
	param (
		[string] $PathToPrint = $ENV:Path,
		[switch] $Debug,
		[switch] $System,
		[switch] $User,
        [switch] $Objects,

        [Alias("h", "?")]
        [switch] $help
    )

    if ( $help ) {
        get-help $MyInvocation.MyCommand
        return;
    }

	if ($System -eq $true) {
		$PathToPrint = (Get-ItemProperty -Path "$($OMEGA_CONF.system_environment_key)" -Name PATH).Path
	}
	if ($User -eq $true) {
		$PathToPrint = (Get-ItemProperty -Path "$($OMEGA_CONF.user_environment_key)" -Name PATH).Path
	}
	if ( $Objects ) {
		$obj = @()
		foreach ( $dirAsStr in $PathToPrint.Split(";") ) {
			if ( $dirAsStr -and ( Test-Path $dirAsStr) ) {
				$obj += Get-Item -Path $dirAsStr
			} else { Write-Warning "$dirAsStr DOES NOT EXIST! Not adding to new path." }
		}
		return $obj
	} elseif($Debug -eq $false){
		Write-Output ($PathToPrint).Replace(';',"`n")
	} else {
		Debug-Variable ($PathToPrint).Replace(';',"`n") "Show-Path"
	}
}

<#
.Description
Read y/n from user to confirm _something_
Returns $true / $false
.Parameter dialog
Optional dialog text before [y|n] to propmt user for input
Else default will be displayed.
#>
function Enter-UserConfirm {
	param (
		[string] $dialog = "Do you want to continue?"
	)
	while ($choice -notmatch "[y|n]") {
		Write-Host -NoNewline -ForegroundColor Cyan "$dialog (Y/N)"
		$choice = Read-Host " "
	}
	if ( $choice.ToLower() -eq "y") {
		return $true
	}
	return $false
}
<#
.Synopsis
Select matching directories from $env:Path and remove them from _THIS SESSION ONLY_
.Parameter dir
Accepts partials %like
.LINK
Add-DirToPath
.LINK
Show-Path
#>
function Remove-DirFromPath($dir) {
	$newPath = ""
	ForEach ( $testDir in $(Show-Path -Objects) ) {

		if ( $testdir -match $dir -and $(Enter-UserConfirm("Remove $testdir ?") === $false)) {
			Write-Warning "removing $testdir"
		}
		else {
			Write-Output "Re-adding $testdir"
			$newPath += "$testdir;"
		}
	}

	# remove trailing semi-colon
	$newPath = $newPath.TrimEnd(";")
	Write-Output "`n`nPath is now:`n$(Show-Path $newPath)"
	Write-Debug "RAW Path String --->`n$newPath"
	$env:Path = $newPath
}

<#
.Synopsis
Add given directories into $env:Path ( _THIS SESSION ONLY_ )
.Parameter dir
Must be the full VALID path. Do not add the ';' as that is done for you.
.LINK
Add-DirToPath
.LINK
Remove-Path
#>
function Add-DirToPath($dir) {
	# ensure the directory exists
	if (Test-Path -Path $dir ) {
		# if it isn't already in the PATH, add it
		if ( -not $env:Path.Contains($dir) ) {
			$env:Path += ";" + $dir
		}
	}
}

function Show-Env { Write-Output (Get-ChildItem Env:) }


function Update-Config {
	$global:OMEGA_CONF = ( Get-Content (Join-Path $PSScriptRoot "\config.json" ) | ConvertFrom-Json )
}

function Update-Environment {
	Update-Config
	. ${env:basedir}\$($OMEGA_CONF.confdir)\ps_functions.ps1
}

<#
.DESCRIPTION
New Shortcut is a core function to create a shortcut with arguments to a target
.PARAMETER targetRelPath
targetRelPath is the file that will be called when the shortcut is called. Typically an exe.
.PARAMETER shortcutFile
shortcutFile is where the resulting shortcut will be placed
Defaults to C:\Users\ehiller\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\ + <baseName>
#>
function New-Shortcut {
	param(
		[Parameter(Mandatory = $true)]
		[string] $targetRelPath,
		[Parameter(Mandatory = $false)]
		[string] $shortcutFile,
		[Parameter(Mandatory = $false)]
		[string] $iconRelPath,
		[Parameter(Mandatory = $false)]
		[string]$arguments
	)

	Update-Config
	if (!$env:basedir) {
		Write-Warning "`$env:BaseDir is not set. Ensure that profile.ps1 is run properly first. Exiting immeditately, no action taken."
		return
	}

	# if no shortcut file is specified, create a default on in the start menu folder
	if ( -not $shortcutFile) {
		# MUST BE ADMIN to create in the default start menu location;
		# check, if not warn and exit
		if ( Test-Admin -warn -not ) { return }
		Write-Debug $targetRelPath
		# get targetName without extension (or Parent directory/ path)
		$baseName = Split-Path -Path (Join-Path $env:basedir $targetRelPath) -Leaf -Resolve
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

	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut( $shortcutFile )

	$Shortcut.TargetPath = Join-Path $env:basedir $targetRelPath

	$Shortcut.Arguments = $arguments
		
	$Shortcut.WorkingDirectory = "$env:Home"

	$Shortcut.IconLocation = Join-Path $env:basedir $iconRelPath

	$Shortcut.Save()
	Write-Output "Shortcut Created at $shortcutFile"
}

function New-OmegaShortcut {

	#$Shortcut.Arguments = '/LoadCfgFile "%HomePath%\AppData\Local\omega\config\ConEmu.xml" /FontDir "%HomePath%\AppData\Local\omega\system\nerd_hack_font" /Icon "%HomePath%\AppData\Local\omega\icons\omega_256.ico" /run "@%HomePath%\AppData\Local\omega\config\powershell.cmd"'
	$arguments = `
	'/LoadCfgFile "' + ( Join-Path ( Join-Path $Env:Basedir $OMEGA_CONF.confdir ) "ConEmu.xml" ) + '" ' + 
	'/FontDir "' + ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir) "fonts" ) + '" ' + 
	'/Icon "' + ( Join-Path ( Join-Path $Env:Basedir "icons" ) "omega_256.ico" ) + '" /run "@..\..\config\powershell.cmd"'

	$shortcutFile = Join-Path $env:basedir "omega.lnk"

	$iconRelPath = "icons\omega_256.ico"

	$targetRelPath = ( Join-Path $OMEGA_CONF.sysdir "ConEmu\ConEmu64.exe" )

	New-Shortcut -targetRelPath $targetRelPath -iconRelPath $iconRelPath -shortcutFile $shortcutFile -arguments $arguments
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
this is the path RELATIVE TO BASEDIR where the shortcut or exe to be linked to / executed is located
#>
function Register-App {

	param(
		# 
		[string]$appName = "omega",
		[string]$targetPath = "${env:basedir}\omega.lnk"
	)
	
	# add .exe suffix if not present asa the appPath requires it.
	# .exe will not show up in the index
	if (-not $appName.EndsWith(".exe")) {
		$appName += ".exe"
	}

	# extract target of shortcut from the shortcut itself
	# https://social.technet.microsoft.com/Forums/office/en-US/f0e20c30-834a-47f1-9a8c-8c719813f900/powershell-script-to-find-target-from-shortcuts-and-then-moverename-target-files?forum=winserverpowershell
	#$targetRelPath = Get-Item (New-Object -ComObject Wscript.Shell).CreateShortcut($shortcutPath).TargetPath
	
	# MUST BE ADMIN; check, if not warn and exit
	if ( Test-Admin -warn -not ) { return }
	
	#$shortcutPath = Join-Path $env:basedir $targetRelPath
	# if targetRelPath is a shortcut use that . set $shortcut=
	#     and set targetRelPath= the shortcut's target
	# else set $create shortcut = from a new shortcut
	# 
	if (Test-Path $targetPath ) {
		New-Item -Path $($OMEGA_CONF.app_paths_key + "\$appName") -Value $targetPath
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

<#
.SYNOPSIS
PROFILE SETTINGS AND PUPLIC KEYS PUSH SCRIPT
Script to push reusable user configuration to quickly setup new Linux machines.
.DESCRIPTION
The purpose of this script is to quickly provision a remote Linux host for personal use.
Your settings (.bashrc and .vimrc) will be created from the locations specified in config.json
Your public key(s) will be discovered from ssh-agent and uploaded to the remote hostname.
Should any of the keys be already present on the remote host, that key will NOT be redundantly added.
And operation will continue to process subsequent keys.

If you encounter issues connecting to the remote host:
A) Connection denied: (this means sshd is running, but that your access is restricted)
	most likely your user is not allowed, if connecting as root ensure it is enabled.
	In `/etc/ssh/sshd_config`:
	1. comment out `PermitRootLogin without-password`
	2. add in `PermitRootLogin yes`
	And restart sshd with `service ssh restart` -or- `/etc/init.d/ssh restart`
.PARAMETER ConnectionString
Please enter username@hostname that you would like your settings pushed to
.LINK
http://stackoverflow.com/questions/12522539/github-gist-editing-without-changing-url/14529686#14529686
.NOTES
Note: When saving configs in a gist:
1) Ensure you link to the RAW file
2) Edit the link, which normally hardlinks to a specific REVISION and thus won't reflect changes.
	Normal/default, REVISION-specific format:
	  https://gist.github.com/[gist_user]/[gist_id]/raw/[revision_id]/[file_name]
	But we want the latest version always, so edit it to the format:
	  https://gist.github.com/[gist_user]/[gist_id]/raw/[file_name]
	that is, you simply remove the `[revision_id]` block
********************************************************************************
Author:                 Eric D Hiller
Originally:             15 January 2016
Updated for Powershell: 25 March 2017
#>
function Send-LinuxConfig {
	param(
		[Parameter(Mandatory = $False , Position = 1)]
		[string] $ConnectionString,
		[Alias("h", "?")]
		[switch] $help
	)

	if ( $help -or -not $ConnectionString){
		get-help $MyInvocation.MyCommand
		return;
	}

	if ( -not ( Get-Command "ssh" -ErrorAction SilentlyContinue )) {
		Write-Warning "ssh is not present on the path, please install before proceeding`n Operation can not proceed, exiting."
	}

	## Send key(s) , and skip if already present
	# get keys from ssh-agent ; THAT MEANS THIS WORKS WITH keeagent (KeePass) !! _nice_
	$keys = & ${env:basedir}\system\git\usr\bin\ssh-add.exe -L 
	if( -not $keys ){
		Write-Warning "No keys present in ssh-agent`n Operation can not proceed, exiting."
	}
	foreach ( $line in ( & ${env:basedir}\system\git\usr\bin\ssh-add.exe -L ) ) {
		$sh = "cd ; umask 077 ; mkdir -p .ssh; touch .ssh/authorized_keys; grep '" + $line + "' "
		$sh += `
@"
-F ~/.ssh/authorized_keys > /dev/null || sed $'s/\r//' >> .ssh/authorized_keys || exit 1 ; if type restorecon >/dev/null 2>&1 ; then restorecon -F .ssh .ssh/authorized_keys ; fi
"@
		Write-Output "Sending Key: $($($line.Split(" ")) | Select-Object -last 1)"
		# do your thing
		$line | & ${env:basedir}\system\git\usr\bin\ssh.exe $ConnectionString $sh
	}
	
	# push bashrc and vimrc
	$(Invoke-WebRequest -UseBasicParsing $OMEGA_CONF.push_bashrc).Content | & ${env:basedir}\system\git\usr\bin\ssh.exe $ConnectionString "sed $'s/\r//' > ~/.bashrc"
	Write-Output "Sent .bashrc"
	$(Invoke-WebRequest -UseBasicParsing $OMEGA_CONF.push_vimrc).Content | & ${env:basedir}\system\git\usr\bin\ssh.exe $ConnectionString "sed $'s/\r//' > ~/.vimrc"
	Write-Output "Sent .vimrc"
	
}


<#
 Utility Functions
#>


function checkGit($Path) {
	if (Test-Path -Path (Join-Path $Path '.git/') ) {
		Write-VcsStatus
		return
	}
	$SplitPath = split-path $path
	if ($SplitPath) {
		checkGit($SplitPath)
	}
}

<#
.DESCRIPTION
Print Variable value to debug
Adapted from (see link)
.Link
http://stackoverflow.com/questions/35624787/powershell-whats-the-best-way-to-display-variable-contents-via-write-debug
#>
function Debug-Variable { 
	param(
		[Parameter(Mandatory = $True)] $var,
		[string] $name,
		[string] $description
	)
	@(
		if ([string]::IsNullOrEmpty($name) -ne $true) { $name = "`nName: ``$name``" }
        "<<<<<<<<<<<<<<<<<<<< START-VARIABLE-DEBUG >>>>>>>>>>>>>>>>>>>>$name`nType:$($var.getType())`n(VALUES FOLLOW)`n$( $var | Format-Table -AutoSize -Wrap | Out-String )" 
	) | Write-Debug
    Write-Debug "<<<<<<<<<<<<<<<<<<<< END-VARIABLE-DEBUG >>>>>>>>>>>>>>>>>>>>"
}

function Debug-Title {
	param(
		[Parameter(Mandatory = $False)] [System.ConsoleColor] $ForegroundColor = $host.PrivateData.DebugBackgroundColor,
		[Parameter(Mandatory = $False)] [System.ConsoleColor] $BackgroundColor = $host.PrivateData.DebugForegroundColor,
		[Parameter(Mandatory = $True, Position=1)] $Print
	)
	if ( $DebugPreference -ne "SilentlyContinue" ){
		if ($Print.getType() -eq [String] ) {
			$Print = $Print.PadLeft($Print.length+20," ").PadRight($Print.length+40," ")
		}
		Write-Host $Print -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
	}
}

function mv {
	param(
	[Parameter(Mandatory=$True,Position=1,
					HelpMessage="Source/Origin - this is the file or folder/directory to copy")]
	[Alias("src","s")]
	[String] $Source,

	[Parameter(Mandatory=$True,Position=2,
					HelpMessage="Destination - this is the folder/directory which the source will be placed")]
	[Alias("dest","d")]
	[String] $Destination,

	[Parameter(Mandatory=$False,
					HelpMessage="Flag to set whether a directory should be created for the Destination, defaults to yes. This is RECURSIVE.")]
	[switch] $Create,
	[switch] $Force
	
	)
	Process
	{

	If ( -not ( Test-Path -Path $Source) ) {
		Write-Warning "Source '$Source' does not exist"
		return 1
	}

	
	If ( $Destination.EndsWith("\") `
	-and ( -not ( Test-Path -Path $Destination) ) ){
		If ( $Create -eq $false ){
			New-Item $Destination -Type directory -Confirm
		}
		If ( $Create -eq $true ){
			New-Item $Destination -Type directory
		}
	}

	# http://go.microsoft.com/fwlink/?LinkID=113350
	# -Confirm 		Prompts you for confirmation before running the cmdlet.
	# -Credential	Specifies a user account that has permission to perform this action. The default is the current user.
	# -Destination	Specifies the path to the location where the items are being moved. 
	#				The default is the current directory. 
	#				Wildcards are permitted, but the result must specify a single location.
	# 				To rename the item being moved, specify a new name in the value of the Destination parameter.
	# -Exclude		Specifies, as a string array, an item or items that this cmdlet excludes from the operation. 
	#				The value of this parameter qualifies the Path parameter. 
	#				Enter a path element or pattern, such as *.txt. 
	#				Wildcards are permitted.
	# -Filter		Specifies a filter in the provider's format or language. 
	#				The value of this parameter qualifies the Path parameter.
	# 				The syntax of the filter, including the use of wildcards, depends on the provider. 
	#				Filters are more efficient than other parameters, because the provider applies them when the cmdlet gets the objects, rather than having Windows PowerShell filter the objects after they are retrieved.
	# -Force		Forces the command to run without asking for user confirmation.
	# -Include		Specifies, as a string array, an item or items that this cmdlet moves in the operation. The value of this parameter qualifies the Path parameter. Enter a path element or pattern, such as *.txt. Wildcards are permitted.
	# -LiteralPath	Specifies the path to the current location of the items. Unlike the Path parameter, the value of LiteralPath is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
	# -PassThru		Returns an object representing the item with which you are working. By default, this cmdlet does not generate any output.
	# -Path
	# -UseTransaction
	# -WhatIf
	#
		If ($Force) {
			Move-Item -Path "$Source" -Destination "$Destination" -Force
		} else {
			Move-Item -Path "$Source" -Destination "$Destination" -Force
		}
	}
}


<##################################
 ######### package logic ##########
 ##################################>

function SafeObjectArray {
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [PSCustomObject] $object,

        [Parameter(Mandatory = $True, Position = 2)]
        [string] $pN
    )

    # debug
    if ( $VerbosePreference ) {
        echo "object---"
        $object | Get-Member | Format-Table
        echo "propertyName---"
        $pN | Get-Member | Format-Table
        echo "end---"
    }
	
    if (!(Get-Member -InputObject $object -Name $pN -Membertype Properties)) {
        Add-Member -InputObject $object -MemberType NoteProperty -Name $pN -Value $ArrayList

        #debug
        if ( $VerbosePreference ) { 
            echo "$pN not present on $object"
            $object | Get-Member | Format-Table
        }
        $object.$pN = @()
    }
}

function ArrayAddUnique {
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [AllowEmptyCollection()]
        [Object[]] $AddTo,

        [Parameter(Mandatory = $True, Position = 2)]
        [String] $AdditionalItem
    )

    if ( $AddTo -notcontains $AdditionalItem) {
        $AddTo += $AdditionalItem
    }
    return $AddTo

	
}

 function opkg-install { opkg -install $args }

<#
.SYNOPSIS
opkg is the package management utility for omega
.DESCRIPTION
Can be used to install, update, list, and check the status of packages
.PARAMETER Install
.PARAMETER Update
.PARAMETER List
Lists the available Packages
.PARAMETER Status
Lists the statuses of the packages, if a PackageName is present, it only shows the status of that name
.PARAMETER PackageName
Package name to be worked with
.PARAMETER UpdateHardlinks
Reads `\config\config.json` and applies
.binlinks: [
	"\\msys64\\mingw64\\bin\\gcc.exe"
]
linking the executable path beneath \system\
To a hardlink within \bin\
.LINK
https://github.com/erichiller/omega
#>
function opkg {
	param(
	[string] $PackageName,
	[switch] $Status,
	[switch] $Install,
	[switch] $Update,
	[switch] $List,
	[switch] $Help=[switch]::Present,
	[switch] $UpdateHardlinks
	)

	# Make sure that the settings we are using are up to date
	Update-Config

	$CallingDirectory = (Convert-Path . )

	<##################################
	######### symlink logic ##########
	##################################>


	# cleanup the directory of items not specified
	# logic:
	# if it is a hardlink (not a local file // a file that only exists in `bin` holder)
	# it will have more than one hardlink to it in `fsutil hardlink query`
	# so check if it is in binlinks array
	# if not - delete it
	function test-bin-hardlinks {
		
		Get-ChildItem (Join-Path $Env:Basedir $OMEGA_CONF.bindir) |
		ForEach-Object {
			$bin = ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.bindir)  $_.name ) 

			$links = ( fsutil hardlink list $bin )
			
			# VERBOSITY see:
			#.LINK
			# https://blogs.technet.microsoft.com/heyscriptingguy/2014/07/30/use-powershell-to-write-verbose-output/
			##################################### VERBOSITY #####################################
			if ( $VerbosePreference ){
				# list number of hardlinks:
				echo " $bin = " + (fsutil hardlink list $bin | measure-object).Count
				if( ($links | measure-object).count -gt 1){ echo $links }

				Write-Host ($links | Format-Table -Force | Out-String)

				if(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent $links ( Get-Content (Join-Path $PSScriptRoot "\config.json" ) | ConvertFrom-Json ).binlinks ){
					echo "$bin ======================================================================> YES";
				}
			}
			######################################## END ########################################

			if( ($links | measure-object).count -gt 1){
				
				$OMEGA_EXT_BINARIES_fullpath = New-Object System.Collections.ArrayList
				foreach( $path in ( Get-Content (Join-Path $PSScriptRoot "\config.json" ) | ConvertFrom-Json ).binlinks ){
					$OMEGA_EXT_BINARIES_fullpath.Add( (  Split-Path -noQualifier $bin ) )
				}
				Write-Debug "BASEDIR=$($env:BaseDir)"
				echo "==== fullpaths ===="
				Show-Path $OMEGA_EXT_BINARIES_fullpath
				echo "=== link ===="
				Show-Path $links
				#Split-Path -noQualifier

				Write-Debug "$bin is a HARDLINK";
				# remove if not in the array
				# see this for array intersect comparisons
				# http://stackoverflow.com/questions/8609204/union-and-intersection-in-powershell
				if( -not (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent $links $OMEGA_EXT_BINARIES_fullpath)){
					Write-Information "$bin is a hardlink and is NOT in an array... removing...."
					Remove-Item -Force $bin
				}
			}

		}
	}

	function Update-Hardlinks {
		
		# verify existing hardlinks first
		test-bin-hardlinks

		foreach ($bin in ( Get-Content (Join-Path $PSScriptRoot "\config.json" ) | ConvertFrom-Json ).binlinks ) {
			$bin =  Join-Path ( Join-Path $env:BaseDir system ) $bin 
			if (Test-Path -Path $bin){
				$binPath = Split-Path -Path $bin -Leaf -Resolve
				$binPath = Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.bindir) $binPath
				if (-not (Test-Path -Path $binPath)){
					Write-Information "ADDING HARDLINK for $bin to $binPath"
					#See help file
					#.LINK
					# cmd.fsutil
					fsutil hardlink create $binPath $bin
				}
			} else {
				Write-Warning "!!ERROR!! the binary to be hardlinked does not exist, path:'$bin'"
			}
		}
	}

	if ( $Help ){
		Get-Help $MyInvocation.MyCommand
	}

	if ( $Status ) {
		if ( $PackageName ){
			Get-Module $PackageName
		} else {
			Get-Module
		}
	}
	if ( $Install ) {
		$Packages = ( Get-Content (Join-Path $PSScriptRoot "\manifest.json" ) | ConvertFrom-Json )
		Write-Host -ForegroundColor Black -BackgroundColor White "================================================>PACKAGES========================>"
		$Packages
		Write-Host -ForegroundColor Black -BackgroundColor White "================================================>END========================>"
		$Package = ($Packages | Where-Object { $_.name -EQ $PackageName -or $_.alias -contains $PackageName } )
		Write-Host -ForegroundColor Black -BackgroundColor White "================================================>PACKAGE========================>"
		$Package
		Write-Host -ForegroundColor Black -BackgroundColor White "================================================>END========================>"
		# Check for existance of $ModulePath , if it does not exist , create the directory
		if ( -not ( Test-Path $ModulePath ) ) { New-Item $ModulePath -type directory }
		switch ( $Package.type ) {
			"psmodule" {
				switch ( $Package.installMethod ) {
					"git" { 
						Set-Location $ModulePath
						& git clone $Package.cloneURL ( Join-Path $ModulePath $Package.name )
						break; 
					}
					"save-package" {
						Save-Package -Path $ModulePath $Package.name
						break;
					}
					default {
						Write-Error "The ${Package.name} requested for installation has an unknown Installation Type of ${Package.installMethod} and package type of ${$Package.type}"
						break;
					}
				}
				# move to the new location
				Set-Location ( Join-Path $ModulePath $Package.name )
				# postInstall is not required in the manifest, but it is here, so create the array if it isn't set
				SafeObjectArray $Package "postInstall"
				# import our newly installed module
				ArrayAddUnique $Package.postInstall $("Import-Module -name $Package.name -ErrorAction Stop >"+'$null')
				break;
			}
			"system-path" {
				switch ( $Package.installMethod ) {
					"http-directory-search" {
						#Set-PSDebug -Trace 2

						Write-Debug "Searching for package in $($Package.installParams.searchPath)"

						$filename = ((Invoke-WebRequest -UseBasicParsing -Uri $Package.installParams.searchPath).Links | Where { $_.href -like $Package.installParams.searchTerm }).href
						Write-Debug "Found Filename: $filename"

						$version = ( $filename | Select-String -Pattern $Package.installParams.versionPattern | % {"$($_.matches.groups[1])"} )
						Write-Debug "Version: $version"

						$inFile = ( $Package.installParams.searchPath + $filename )
						$outFile = ( Join-Path $env:TEMP $filename )
						Write-Debug "Source: $inFile"
						Write-Debug "Destination: $outFile"
						Write-Debug "Extension:'$([IO.Path]::GetExtension($filename))'"
						
						Start-BitsTransfer -Source ( $Package.installParams.searchPath + $filename ) -Destination $outFile -Description "omega opkg install version $version of $($Package.installParams.searchPath)($filename)"

						$deploy = ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir) $Package.name )
						Write-Debug "Deploy: $deploy"
						Debug-Variable $OMEGA_CONF.compression_extensions
						if( $OMEGA_CONF.compression_extensions -contains [IO.Path]::GetExtension($filename) ){
							Write-Debug "Decompression of $outFile required... Decompressing to the deployment directory:$deploy"
							# add ` -bb1` as an option to `7z` for more verbose output 
							& 7z x $outFile "-o$deploy"
						} else {
							Move-Item $outFile -Destination $deploy
						}
						# check if the deployed directory ONLY Contains directories, this most likely means the package was zipped in a way that the first level directory should be removed.
						Write-Debug $(( Get-ChildItem -Attributes directory $deploy).Count )
						Write-Debug $(( Get-ChildItem $deploy).Count )
						Write-Debug $((( Get-ChildItem -Attributes directory $deploy).Count ) -eq (  ( Get-ChildItem  $deploy).Count ))
						Debug-Variable (Get-ChildItem $deploy)
						Write-Debug $([IO.Path]::GetFileNameWithoutExtension($filename)) 
						Write-Debug $( ( Get-ChildItem  $deploy | Where { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } ))
						Write-Debug $(( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } )))
						if(( ( Get-ChildItem -Attributes directory $deploy).Count ) -eq (  ( Get-ChildItem  $deploy).Count ) -and
						# Check if there is a single child-item, and if that single child-item has the same name as the file we just downloaded
						( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } )) ) {
							$tempPath = ( Join-Path $env:TEMP $Package.name )
							Write-Debug "temporarily moving the package from:'$deploy' to:'$tempPath'"
							Move-Item $deploy -Destination $tempPath -Force
							Move-Item ( Join-Path $tempPath ([IO.Path]::GetFileNameWithoutExtension($filename)) ) -Destination $deploy
						}
						# add any binlinks required
						if( $Package.installParams.binlinks ){
							# postInstall is not required in the manifest, but it is here, so create the array if it isn't set
							SafeObjectArray $Package "postInstall"
							SafeObjectArray $OMEGA_CONF "binlinks"
							ForEach( $binlink in $Package.installParams.binlinks){
								$cmd = "`$OMEGA_CONF.binlinks = ArrayAddUnique `$OMEGA_CONF.binlinks $(Join-Path $Package.name $binlink )"
								$Package.postInstall = ArrayAddUnique $Package.postInstall $cmd
							}
							# save config
							$Package.postInstall = ArrayAddUnique $Package.postInstall "Write-OmegaConfig"
							# run hardlinks
							$Package.postInstall = ArrayAddUnique $Package.postInstall "Update-Hardlinks"

							Debug-Variable $Package.postInstall
						}
						if ( $Package.installParams.systemPath ){
							Write-Debug "Package $($Package.name) will be on the systemPath."
							if (Update-SystemPath $deploy){
								Write-Warning "Installation Failed."
								return
							}
							# save config
							# postInstall is not required in the manifest, but it is here, so create the array if it isn't set
							SafeObjectArray $Package "postInstall"
							$Package.postInstall = ArrayAddUnique $Package.postInstall "Write-OmegaConfig"
						}
						#Set-PSDebug -Trace 0
						break;
					}
				}

				break;
			}
			
			default {
				Write-Error "The ${Package.name} requested for installation has an unknown Package Type of ${Package.type} installed via ${$Package.installMethod}"
				break;
			}
		}
		<#
		no matter the package type
		we run the postInstall actions
		#>
		try {
			ForEach( $command in $Package.postInstall ) {
				Write-Debug "Now running the postInstall `$command:$command"
				. ( [scriptblock]::Create($command) )

			}
			# mark as installed in the manifest
			$Package.state.updateDate = (Get-Date -format "yyyy-MMM-dd HH:mm" )
			$Package.state.installed = $true
			$Packages | ConvertTo-Json -Depth 3 | Set-Content ( Join-Path $PSScriptRoot "\manifest.json" )
		} catch {
			Write-Warning "${Package.name} module failed to load. Either not installed or there was an error. This module, who's functions follow, will now be disabled:"
			Write-Warning $Package.brief
			Write-Warning $_.Exception.Message
		}
	}
	if ( $UpdateHardlinks ){ Update-Hardlinks }
	if ( $Help -and !$Status -and !$Install -and !$List -and !$Update ){
		$Script:MyInvocation.invocationname
	}
	Set-Location $CallingDirectory
}

function Write-OmegaConfig {
	$OMEGA_CONF | ConvertTo-Json -Depth 4 | Set-Content ( Join-Path $PSScriptRoot "\config.json" )
	Write-Debug "Omega-Config has been written."
}

<#
.DESCRIPTION
Adds the given directory to the system path
.PARAMETER directory
a string with the path to the directory to be added to the system path
#>
function Update-SystemPath {
	param(
		[Parameter(Mandatory=$True,Position=1)]
		[ValidateScript({Test-Path -Path $_ -PathType Container})]
		[String] $Directory
	)
	$OriginalPath = (Get-ItemProperty -Path "$($OMEGA_CONF.system_environment_key)" -Name PATH).Path
	Write-Debug "Checking Path at '$($OMEGA_CONF.system_environment_key)' - currently set to `n$OriginalPath"
	$Path = $OriginalPath
	# Check to ensure that the Directory is not already on the System Path
	if ($Path | Select-String -SimpleMatch $Directory)
		{ Write-Warning "$Directory already within System Path" }
	# Ensure the Directory is not already within the path
	if ($ENV:Path | Select-String -SimpleMatch $Directory)
		{ Write-Warning "$Directory already within `$ENV:Path" }
	# Check that the directory is not already on the configured path
	if ( $OMEGA_CONF.path_additions -Contains $Directory) 
		{ Debug-Variable $OMEGA_CONF.path_additions "path_additions"; Return "$Directory is already present in `$OMEGA_CONF.path_additions" }
	
    # MUST BE ADMIN to create in the default start menu location;
    # check, if not warn and exit
	if ( Test-Admin -warn -not ) { return }

	# Add the directory to $OMEGA_CONF.path_additions
	SafeObjectArray $OMEGA_CONF "path_additions"
	$OMEGA_CONF.path_additions = ArrayAddUnique $OMEGA_CONF.path_additions $Directory
	Debug-Variable $OMEGA_CONF.path_additions "OMEGA_CONF.path_additions"
	# Safe to proceed now, add the Directory to $Path
	$Path = "$Path;$(Resolve-Path $Directory)"
	
	# Cleanup the path
	# rebuild, directory by directory, deleting paths who are within omega's realm, and no longer exist or are permitted to be there (via OMEGA_CONF.path_additions)
	$Dirs = $Path.split(";") | where-object {$_ -ne " "}

	ForEach ($testDir in $Dirs){
		Write-Debug "Testing for validity within the system path:`t$testDir"
		# Test if $testDir is within $($env:BaseDir)
		# If yes continue to test its validity within the system path.
		# If No, it is not in our jurisdiction/concern, proceed.
		if ( ($testDir -Like "$($env:BaseDir)*") ) {
			Write-Debug "The $testDir is within ${env:BaseDir} - continuing to test its validity within the system path."
			# test that path exists on the filesystem / is a valid path (and that it is a Container type (directory))
			# not found = not valid = continue
			if ( ! (Test-Path -Path $testDir -PathType Container) )
				{ Write-Debug "$testDir is not a valid Path"; continue }
			# test if the path_additions parameter is even configured, if not, then NO PATHS FROM OMEGA ARE VALID = continue
			if ( ! (Get-Member -InputObject $OMEGA_CONF -Name "path_additions" -Membertype Properties))
				{ Write-Debug "path_additions is not a Property of `$OMEGA_CONF" ; continue }
			# test to see if $OMEGA_CONF.path_additions contains $testDir, if it does not, then continue
			if ( $OMEGA_CONF.path_additions -NotContains $testDir)
				{ Write-Debug "$testDir not in `$OMEGA_CONF"; continue } 
		}
	}
	$Path = $Path -join ";" 
	# All Tests Passed, the trials are complete, you, noble directory, can be added (or kept) on the system's path
	Write-Debug "All validity tests have passed, '$Directory' is now on '$Path'"
	# Set the path
	# if( -not (& setx PATH /m $Path) ){ return $false }
	try {
		Set-ItemProperty -Path "$($OMEGA_CONF.system_environment_key)" -Name PATH -Value $Path
	} catch {
		Write-Error "There was an issue updating the system registry."
		return $false
	}

	if( -not $ENV:Path.Contains($testDir) ){
		Write-Debug "$testDir is being added to the Environment Path as well as the System Path will only refresh for new windows"
		$ENV:Path += ";" + $testDir
	}

	Show-Path -Debug
	return $true
}

Set-Alias -Name "f" -Value Search-FrequentDirectory -ErrorAction Ignore
<#
.SYNOPSIS
Search-FrequentDirectory is a helper function navigating frequently accessed directories
.DESCRIPTION
The use simply enters the directory name, or part of it, and the history is searched
The most commonly cd 'd into directory containing the string is then cd'd into.
.PARAMETER dirSearch
directory string to search for
.NOTES
Additionall, a very similarly useful command in powershell is 
#<command><tab>
That is hash symbol, then type the command you would like to search your command history for, then press tab. A menucomplete of all your history containing that command will come up for your selection.
#>
function Search-FrequentDirectory {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false)]
		[Switch] $delete,
		[Parameter(Mandatory = $false)]
		[Switch] $outputDebug
	)
	DynamicParam {
	$dirSearch = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]

	# [parameter(mandatory=...,
	#     ...
	# )]
	$dirSearchParamAttribute = new-object System.Management.Automation.ParameterAttribute
	$dirSearchParamAttribute.Mandatory = $true
	$dirSearchParamAttribute.Position = 1
	$dirSearchParamAttribute.HelpMessage = "Enter one or more module names, separated by commas"
	$dirSearch.Add($dirSearchParamAttribute)    

	# [ValidateSet[(...)]
	$dirPossibles = @()
	
	$historyFile = (Get-PSReadlineOption).HistorySavePath
	# directory Seperating character for the os; \ (escaped to \\) for windows (as C:\Users\); / for linux (as in /var/www/);
	# a catch all would be \\\/  ; but this invalidates the whitespace escape character that may be used mid-drectory.
	$dirSep = "\\"
	# Group[1] = Directory , Group[length-1] = lowest folder
	$regex = "^[[:blank:]]*cd ([a-zA-Z\.\~:]+([$dirSep][^$dirSep]+)*[$dirSep]([^$dirSep]+)[$dirSep]?)$"
	# original: ^[[:blank:]]*cd [a-zA-Z\~:\\\/]+([^\\\/]+[\\\/]?)*[\\\/]([^\\\/]+)[\/\\]?$
	# test for historyFile existance
	if( -not (Test-Path $historyFile )){ 
		Write-Warning "File $historyFile not found, unable to load command history. Exiting."; 
		return 1; 
	}
	$historyLines = Get-Content $historyFile
	# create a hash table, format of ;;; [directory path] = [lowest directory]
	$searchHistory = @{}
	# create a hash table for the count (number of times the command has been run)
	$searchCount = @{}
	ForEach ( $line in $historyLines ) {
		if( $line -match $regex ){
			try {
				# since the matches index can change, and a hashtable.count is not a valid way to find the index...
				# I need this to figure out the highest integer index
				$lowestDirectory = $matches[($matches.keys | Sort-Object -Descending | Select-Object -First 1)]
				$fullPath = $matches[1]
				if($searchHistory.keys -notcontains $matches[1]){
					$searchHistory.Add($matches[1],$lowestDirectory)
				}
				$searchCount[$fullPath] = 1
			} catch {
				$searchCount[$fullPath]++
			}
		}
	}
	# this helps with hashtables
	# https://www.simple-talk.com/sysadmin/powershell/powershell-one-liners-collections-hashtables-arrays-and-strings/
	
	$dirPossibles = ( $searchHistory.values | Select -Unique )

	$modulesValidated_SetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($dirPossibles)
	$dirSearch.Add($modulesValidated_SetAttribute)

	# Remaining boilerplate
	$dirSearchDefinition = new-object -Type System.Management.Automation.RuntimeDefinedParameter("dirSearch", [String[]], $dirSearch)

	$paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
	$paramDictionary.Add("dirSearch", $dirSearchDefinition)

	return $paramDictionary
	}
	begin {
		function Set-LocationHelper {
			param(
				[Parameter(Mandatory=$True)]
				[string] $dir,
				[switch] $delete,
				[switch] $addToHistory
			)
			# Add to history so that in the future this directory will be found with `cd` scanning and brute force WILL NOT BE REQUIRED
			if ($addToHistory){
				[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory("cd $dir")
			}
			if ( $delete ){
				Clear-History -CommandLine $filteredDirs -Confirm
			} else {
				Set-Location $dir
			}
		}
	}
	process {
		# I only want to see Debug messages when I specify the DEBUG flag
		if ($PSCmdlet.MyInvocation.BoundParameters["debug"].IsPresent) {
			$LOCAL:DebugPreference = "Continue"
		} else {
			$LOCAL:DebugPreference = "SilentlyContinue"
		}


		# comes out as an array, but only one is possible, so grab that
		$dirSearch = $PsBoundParameters.dirSearch[0]
		
		Debug-Variable $searchHistory "f/searchHistory"
				
		Write-Debug "dirSearch=$dirSearch"
		
		#this is doing ___EQUAL___ /// or do I want to be doing a like dirSearch*
		$filteredDirs = $searchHistory.GetEnumerator() | ?{ $_.Value -eq $dirSearch } 

		# if there is a single match
		if ( $filteredDirs.count -eq 1 ){
			$testedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($filteredDirs.name)
			if( $testedPath | Test-Path ){
				Set-LocationHelper $testedPath
			}
		} else {
			# there are multiple matches
			# do a lookup for number of times it was cd'd into with the searchCount
			#### searchCount ####
			## NAME ===> VALUE ##
			## (DIR) ==> COUNT ##
			Debug-Variable $searchCount

			"More than one matching entry was found, now sorting and checking each historical cd"
			$searchCount.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
				$countedDir = $_
				$highestDir = ( $filteredDirs.GetEnumerator() | ?{$_.Name -contains $countedDir.Name} )
				if ( $highestDir.count -eq 1 ){
					Write-Debug "Check for $($highestDir.name)"
					$testedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($highestDir.name) 
					if( $testedPath | Test-Path ){
						Set-LocationHelper $testedPath
						break
					} else {
						Write-Warning "Tried to cd to $($highestDir.name) (resolved to $testedPath), but it does not exist"
					}
				} else {
					$highestDir.name
				}
			}
		}

		# if a match was found above; but it did not immeditately resolve
		if( ( $testedPath ) `
				-and ( -not ( $testedPath | Test-Path ) ) ){
			Write-Information "Could not find test string '$dirSearch', possibly not an absolute path, Attempting to Locate"
			# iterate history where the directory that was being searched for is PART of one of the historical items
			# for example; if searching for dirB. This would find it in /dirA/dirB/dirC/ and return /dirA/dirB/
			## <START LOOP>
			$searchCount.GetEnumerator() | Sort-Object -Property Value -Descending | Where-Object { $_.Name -like "*$dirSearch*" } | ForEach-Object -ErrorAction SilentlyContinue {
				$testedPath = $_.Name
					Write-Debug "Command like dirsearch:$testedPath" -ErrorAction SilentlyContinue
				$testedPath = Join-Path $testedPath.Substring( 0 , $testedPath.IndexOf($dirSearch) ) $dirSearch
				if ( Test-Path $testedPath ){
					Set-LocationHelper $testedPath
					break
				}
			}
			## <END LOOP>

			#### Brute force search directories ####
			# if we reached this point, none of the above worked, it is time to just brute force search,
			# Not found within the path of another match, so just scan every single directory. Maybe slow, but it should work
			Write-Debug "We are now going to brute force search, all other methods have failed"
			$dirsToScan = @(".", $env:HOME, $env:LOCALAPPDATA)
			foreach ($dir in $dirsToScan ) {
				Write-Debug "Scanning: $dir"
				Get-Childitem -path $dir -recurse -directory -filter "$dirSearch" -ErrorAction SilentlyContinue | ForEach-Object {
					$testedPath = $_.FullName
					if (Enter-UserConfirm -dialog "Confirm: Change Directory to $testedPath") {
						Set-LocationHelper $testedPath -addToHistory
						break
					}
				}
			}
		}
	} <# End process {} #>

}

<#
.SYNOPSIS
Returns true if the current session is an administrative priveleged one
#>
function Test-Admin {
	Param(
		[Switch] $warn=$false
	)
	If ( -not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
		if($warn){
			Write-Warning "You must be an administrator in order to continue.`nPlease try again as administrator."
		}
		return $true
	}
	return $false
}

<#
.SYNOPSIS
Written primarily for setting the tab title in ConEmu.
.EXAMPLE
See omega.psm1 for usage
#>
function Get-PrettyPath {
	param (
	[System.Management.Automation.PathInfo] $dir
	)
	#### IT IS GIVING ME A STRING!!!!!
	if( -not $dir ){ $dir = Get-Location }
	if( -not ( $dir | Get-Member -Name "Provider" ) ){
		throw
		return "?!?"
		# somehow this does not have a Provider?
	}
	$provider = $dir.Provider.Name
	if($provider -eq 'FileSystem'){
		$result = @()
		$currentDir = Get-Item $dir.path
		while( ($currentDir.Parent) -And ($currentDir.FullName -ne $HOME) -And ($result.Count -lt 2 ) ) {
			$result = ,$currentDir.Name + $result
			$currentDir = $currentDir.Parent
		}
		$shortPath =  $result -join $ThemeSettings.PromptSymbols.PathSeparator
		if ($shortPath) {
			return "$($sl.PromptSymbols.PathSeparator)$shortPath"
		} else {
			if ($dir.path -eq $HOME) {
				return '~'
			}
			return "$($dir.Drive.Name):"
		}
	} else {
		return $dir.path.Replace((Get-Drive -dir $dir), '')
	}
}


<#
.SYNOPSIS
View Checksums (SHA1 by default) and diff of all files in directories A and B
#>
function Get-DirectoryDiff {
	param (
	[Parameter(Position=1,Mandatory=$True)]
	[System.Management.Automation.PathInfo] $a,
	
	[Parameter(Position=2,Mandatory=$True)]	
	[System.Management.Automation.PathInfo] $b
	)
	Get-FileHash $a | ForEach-Object {
		$shortName = ($_.Path | Split-Path -Leaf)
		($_.Path | Split-Path -Leaf).PadRight(30, " ") + $_.Hash.Substring($_.Hash.Length - 8) + " ".PadRight(10, " ") + (Get-FileHash $b\$($_.Path | Split-Path -Leaf)).Hash | Write-Host 
		Compare-Object -ReferenceObject $(Get-Content .\$shortName) -DifferenceObject $(Get-Content $b\$shortName)
	}
}

<#
.SYNOPSIS
Wrapper for GNU grep which allows for setting default parameters. Defaults here are --color=auto and --ignore-case
It accepts pipeline input.
#>
function grep {
	[CmdletBinding()]
	Param(
		[Parameter(
			Mandatory=$False,
			ValueFromPipeline=$True)]
		$pipelineInput,
		[Parameter(Position=0)]
			[string]$needle="--help",
		[parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$Remaining
	)
	Begin {
		$op = $env:PATH
		$env:PATH += ";${env:basedir}\system\git\usr\bin\"
		Write-Verbose "in grep, searching ${pipelineInput} for ${needle}"
	}
	Process {
		if ( $pipelineInput -eq $Null ){
			grep.exe --ignore-case --color=auto @Remaining $needle
		}
		ForEach ($input in $pipelineInput) {
			Write-Verbose "input item=>${input}"
			$input| Out-String | grep.exe --ignore-case --color=auto @Remaining $needle
		}
	}
	End {
		$env:PATH = $op
	}
}

<#
.SYNOPSIS
Swap \ for / ; windows directories to linux style
#>
function Convert-DirectoryStringtoUnix {
	param (
	[Parameter(Position=1,Mandatory=$True)]
	[String] $path
	)
	return $path.Replace("\", "/")
}

<#
.SYNOPSIS
Write log entries to omega logfile
#>
function Write-Log {
	[CmdletBinding()]
	Param(
		[Parameter(
			Mandatory=$False,
			ValueFromPipeline=$True)]
		$pipelineInput,
		[Parameter(Mandatory=$False, Position=0)]
			[string]$Message,
		[Parameter(Mandatory=$False, HelpMessage='Activating Clear will erase the file BEFORE writing your new contents of this run, thus these new messages will start at the beginning of the log')]
			[switch]$Clear,
		[Parameter(Mandatory=$False, HelpMessage='Echo LogPath to the console')]
			[switch]$ShowFilePath,
		[Parameter(Mandatory=$False, HelpMessage='Show Chars and Values (only on Piped input)')]
			[switch]$DebugString,
		[Parameter(Mandatory=$False)]
		[Alias('h', '?')]
			[switch] $help
	)
	Begin {
		if ($OMEGA_CONF -ne $null) {
			$logpath = ( Join-Path $env:basedir $OMEGA_CONF.logpath )
		} else {
			$logpath = "C:\Users\ehiller\AppData\Local\omega\omega.log"
		}
		if ( $help ){
			get-help $MyInvocation.MyCommand
			return;
		}
		if ( $ShowFilePath -eq $True ) {
			Write-Information $logpath
			return
		}
		$Level = ""
		if ($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent) 
		{
			 $Level = "[DEBUG] "
		}
		if ( $message -ne '' ) {
			Write-Output "$(Get-Date -UFormat '%b-%d %R:%S') $Level>> $Message" | Add-Content -Path $logpath
		}
	}
	Process {
		if ( $Clear -eq $True ) {
			Clear-Content -Path $logpath
		}
		ForEach ($pipelineMessage in $pipelineInput) {
			Write-Verbose "processing pipeline message=>${pipelineMessage}"
			if ( $DebugString -eq $True ) {
				$char = $pipelineMessage.toCharArray()
				$pipelineMessage = ""
				$count = 0
				$char | foreach-object {
					if ($count % 10 -eq 0) {
						$pipelineMessage += "`n"
					}
					$count++
					$int = [int[]]$_
					$pipelineMessage += " $_ : $int ".PadRight(10, " ")
				}
			}
			Write-Output "$(Get-Date -UFormat "%b-%d %R:%S") $Level>> $pipelineMessage" | Add-Content -Path $logpath
		}
	}
}

<#
.SYNOPSIS
Retrieve Directory Sizes as per their contained items
.DESCRIPTION
Similar to linux's `du` utility
.LINK
https://technet.microsoft.com/en-us/library/ff730945.aspx
.LINK
https://technet.microsoft.com/en-us/library/ee692795.aspx
#>
function Get-DirectorySize {
	# Get-ChildItem |
	# Where-Object { $_.PSIsContainer } |
	# ForEach-Object {
	# 	$_.Name + ": " + (
	# 		Get-ChildItem $_ -Recurse |
	# 		Measure-Object Length -Sum -ErrorAction SilentlyContinue
	# 	).Sum
	# }
	Get-ChildItem | Where-Object { $_.PSIsContainer } | ForEach-Object { $_.Name + ": " + "{0:N2}" -f ((Get-ChildItem $_ -Recurse | Measure-Object Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB) + " MB" }
	
}
