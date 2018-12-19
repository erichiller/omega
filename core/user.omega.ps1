<# File for User Facing, Omega Specific Commands #>

<#
.SYNOPSIS
 Display the commands Omega provides
.LINK
Set-RegisterCommandAvailable
#>
function Get-OmegaCommands {
	# print the table
	$FunctionHelpList = @()
	(Get-Module Omega).PrivateData.RegisteredCommands | ForEach-Object {
		$FunctionHelpList +=( Get-Help $_ | Select-Object Name, Synopsis )
	}
	if ( $null -ne ([User]::GetInstance()).RegisteredCommands ){
		([User]::GetInstance()).RegisteredCommands | ForEach-Object {
			$FunctionHelpList +=( Get-Help $_ | Select-Object Name, Synopsis )
		}
	}
	$FunctionHelpList
}


<#
.SYNOPSIS
Output (*unique*) History from PSReadline, optionally matching a string (REGEX supported), rather than from the native PowerShell history system.
.DESCRIPTION
Get-History is an improved version of the native PowerShell Get-History command which only stores History for the given session.
.PARAMETER Find
REGEX capable string on which to filter results
#>
function Get-History {
	param (
        [Parameter(Mandatory = $False)]
        [Alias("f", "search", "s")]
        [string] $Find = "*",

        [Parameter(Mandatory = $False)]
        [Alias("tail", "n")]
        [string] $Count = 10000
    )
    Get-Content -Tail $Count "${env:APPDATA}\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" | Get-Unique | Select-String -Pattern $Find | Select-Object -Property LineNumber, Line
}

<#
.SYNOPSIS
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
	$conf = [OmegaConfig]::GetInstance()

	if ( $help ) {
		get-help $MyInvocation.MyCommand
		return;
	}

	if ($System -eq $true) {
		$PathToPrint = (Get-ItemProperty -Path "$($conf.system_environment_key)" -Name PATH).Path
	}
	if ($User -eq $true) {
		$PathToPrint = (Get-ItemProperty -Path "$($conf.user_environment_key)" -Name PATH).Path
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
.SYNOPSIS
Show environment variables.
#>
function Show-Env { Write-Output (Get-ChildItem Env:) }




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
Author:				 Eric D Hiller
Originally:			 15 January 2016
Updated for Powershell: 25 March 2017
#>
function Send-LinuxConfig {
	param(
		[Parameter(Mandatory = $False , Position = 1)]
		[string] $ConnectionString,
		[Alias("h", "?")]
		[switch] $help
	)
	$user = [User]::GetInstance()
	$conf = [OmegaConfig]::GetInstance()

	if ( $help -or -not $ConnectionString){
		get-help $MyInvocation.MyCommand
		return;
	}

	if ( -not ( Get-Command "ssh" -ErrorAction SilentlyContinue )) {
		Write-Warning "ssh is not present on the path, please install before proceeding`n Operation can not proceed, exiting."
	}

	## Send key(s) , and skip if already present
	# get keys from ssh-agent ; THAT MEANS THIS WORKS WITH keeagent (KeePass) !! _nice_
	$keys = & "$($config.basedir)\system\git\usr\bin\ssh-add.exe" -L
	if( -not $keys ){
		Write-Warning "No keys present in ssh-agent`n Operation can not proceed, exiting."
	}
	foreach ( $line in ( & "$($config.basedir)\system\git\usr\bin\ssh-add.exe" -L ) ) {
		$sh = "cd ; umask 077 ; mkdir -p .ssh; touch .ssh/authorized_keys; grep '" + $line + "' "
		$sh += `
@"
-F ~/.ssh/authorized_keys > /dev/null || sed $'s/\r//' >> .ssh/authorized_keys || exit 1 ; if type restorecon >/dev/null 2>&1 ; then restorecon -F .ssh .ssh/authorized_keys ; fi
"@
		Write-Output "Sending Key: $($($line.Split(" ")) | Select-Object -last 1)"
		# do your thing
		# $line | & "$($config.basedir)\system\git\usr\bin\ssh.exe" $ConnectionString $sh
		$env:SSHCallBasic = $True
		$line | & "$($config.basedir)\bin\ssh.cmd" $ConnectionString $sh
	}

	if ( [string]::IsNullOrEmpty($user.push.bashrc) ){
		$user.push = ([OmegaConfig]::GetInstance()).Push;
	}

	# push bashrc and vimrc
	$(Invoke-WebRequest -UseBasicParsing $user.push.bashrc).Content | & "$($config.basedir)\bin\ssh.cmd" $ConnectionString "sed $'s/\r//' > ~/.bashrc"
	Write-Output "Sent .bashrc"
	$(Invoke-WebRequest -UseBasicParsing $user.push.vimrc).Content | & "$($config.basedir)\bin\ssh.cmd" $ConnectionString "sed $'s/\r//' > ~/.vimrc"
	Write-Output "Sent .vimrc"
	Remove-Item env:SSHCallBasic
}



<#
.SYNOPSIS
Swap \ for / ; windows directories to linux style
#>
function Convert-DirectoryStringToUnix {
	param (
	[Parameter(Position=1,Mandatory=$True)]
	[String] $path
	)
	return $path.Replace("\", "/")
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


<#
.SYNOPSIS
Get md5 hash of input file(s)
#>
function Get-md5sum { Get-FileHash -Algorithm "md5" -Path $args };

<#
.SYNOPSIS
Get sha256sum hash of input file(s)
#>
function Get-sha256sum { Get-FileHash -Algorithm "sha256" -Path $args };


<#
.SYNOPSIS
Use the Silver Searcher to do Find Files by input name
.DESCRIPTION
`-i` and `-g` are already specified so that a case insensitive file name search is performed
Typical use would be:
ff <filename> [<filepathbase>]
#>
function ff { & "$($config.basedir)\bin\ag.exe" -i -g $args }

<#
.SYNOPSIS
Search-Executable is a replacement and expansion of *nix's where. It can locate a command in the file hierarchy, as well as return its containing directory.
.PARAMETER command
The name of the command to search for
.PARAMETER directory
A switch, its presence will return the containing directory rather than the path to the command itself.
.EXAMPLE
Search-Executable notepad.exe
.NOTES
Often aliased to `whereis`
#>
function Search-Executable {
	param (
		[Parameter(Mandatory = $true)]
			[string] $command,
		[Parameter(Mandatory = $false)]
			[switch] $directory,
		[Parameter(Mandatory = $false)]
			[Alias("cd","change")]
			[switch] $ChangeDirectory,
		[Alias("h", "?" )][switch] $help
	)
	if ( $help ) { Get-Help $MyInvocation.MyCommand; return; } # Call help on self and exit
	if ($directory -eq $true -or $ChangeDirectory -eq $True) {
		$path = Split-Path (Get-Command $command | Select-Object -ExpandProperty Definition) -parent
	} else {
		$path = $(Get-Command $command).source
	}
	if ( $changeDirectory ){
		set-location $path
	} else {
		echo $path
	}
}

<#
.SYNOPSIS
Tail follows file updates and prints to screen as they occur
#>
function Get-FileContentTail {
	param(
		[Parameter(Mandatory = $true, Position = 1)]
		[Alias("f")]
		[string] $file
	)
	Get-Content -Tail 10 -Wait -Path $file
}

<#
.SYNOPSIS
change Directory to a set user directory location
.NOTES
By default this uses a structure assuming
%USERPROFILE$\
	Dev\
		src\
			[repository sources]...
			github.com\
				$user.itUser
		bin\
		pkg\
		data\
#>
function Open-GitHubDevDirectory {
	$User = [User]::GetInstance()
	Set-Location "${env:Home}\Dev\src\github.com\$($user.GitUser)\$($args[0])"
}

<#
.SYNOPSIS
change Directory Omega Directory + Optional subdirectory
.PARAMETER subdir
Optional subdirectory within OmegaBaseDirectory to CD into
.PARAMETER var
If set command will return $destination directory rather than changing into the directory
#>
function Open-OmegaBaseDirectory {
	param (
		[Parameter(Mandatory = $false)]
		[string] $subdir = "",
		[Parameter(Mandatory = $false)]
		[switch] $var
	)
	$destination = Join-Path $config.Basedir $subdir
	if ($var -eq $True ) {
		return $destination
	}
	Set-Location $destination
}


<#
.Synopsis
 Search Knowledge Base files for text using Silver Surfer
#>
function Search-KnowledgeBase {
	param (
		[Parameter(Mandatory = $false, Position = 1)]
		[string] $Term,

		[Parameter(Mandatory = $false, HelpMessage = "The Path can not have a trailing slash.")]
		[string] $Path = (Join-Path ${env:Home} "\Google Drive\Documents\Knowledge Base"),

		[Parameter(Mandatory = $false, HelpMessage = "Opens a new vscode window into your kb folder.")]
		[switch] $Create,

		[Parameter(Mandatory = $false, HelpMessage = "Open file, Read-only.")]
		[Alias("o")][switch] $Open,

		[Parameter(Mandatory = $false, HelpMessage = "Search in filenames only, not contents.")]
		[Alias("f")][switch] $SearchFilenames,

		[Parameter(Mandatory = $false, HelpMessage = "Display filenames only, not contents.")]
		[Alias("l")][switch] $DisplayFilenames,

		[Parameter(Mandatory = $false, HelpMessage = "Ignore Filename/Path pattern. Can take *.ext or Filename.ext as item,comma,list")]
		[Alias("i")][string[]] $IgnorePath = "*.ipynb",

		[Parameter(Mandatory = $false, HelpMessage = "Disable Filename/Path pattern.")]
		[Alias("n")][switch] $NoIgnorePath,

		[Parameter(Mandatory = $False)][string] $Editor = "code",

		[Alias("h", "?" )][switch] $help
	)
	# NOTE: THE PATH CAN _NOT_ HAVE A TRAILING SLASH , but we will make it safe just in case nobody listens
	# replace the last character ONLY IF IT IS / or \
	$path = $path -replace "[\\/]$"
	if ($Create) {
		# https://code.visualstudio.com/docs/editor/command-line
		. $Editor $path
		#### -$Edit HERE
		# code file:line[:character]

	} elseif ( $Term ) {
		if ( $Term -eq "--help" ) {
			$help = $True
		} else {
			# if ( $File ){
			#	 & "$($config.basedir)bin\ag.exe" -g --stats --ignore-case $Term $Path
			# }
			$Modifiers = @(	"--stats",
	"--smart-case",
	"--color-win-ansi",
	"--pager", "more" )
			If ($DisplayFilenames) {
	$Modifiers += "--count"
			}
			$IgnorePathSplat = @()
			if ( $NoIgnorePath -eq $False ) {
	$IgnorePath | ForEach-Object { $IgnorePathSplat += "--ignore"; $IgnorePathSplat += "$_" }
			}
			$Params = $Term , $Path
			if ( $SearchFilenames -eq $True ) {
	$Params = "--filename-pattern" , $Params
			}
			If ($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent) { $exe = "EchoArgs.exe" } else { $exe = "ag.exe" }
			# "--ignore","*.ipynb","--ignore","ConEmu.md"
			# & "$($config.basedir)\bin\ag.exe" --stats --smart-case @IgnorePathSplat --color-win-ansi --pager more (&{If($DisplayFilenames) {"--count"}}) $Term $Path
			# & "$($config.basedir)\bin\ag.exe" @modifiers @IgnorePathSplat @Params
			$output = & "$($config.basedir)\bin\$exe" @Modifiers @IgnorePathSplat @Params
			$output	# in the future, this could be prettied-up
			if ( $Open -eq $True ) {
	# .  ( $output | Select-String -Pattern "\w:\\[\w\\\s\/.]*" )
	Write-Host -ForegroundColor Magenta ( $output | select-string -Pattern "\w:\\[\w\\\/. /]*" ).Matches


	( $output | select-string -Pattern "\w:\\[\w\\\/. /]*" ).Matches | ForEach-Object {
		if ( Enter-UserConfirm -dialog "Open $_ in editor?"  ) {
			. $Editor $_
		}
	}
			}
		}
	} else {
		Write-Warning "Please enter search text"

		Write-Output "---kb---help---start---"
		Get-Help $MyInvocation.MyCommand
		Write-Output "---kb---help---end---"
	}
	if ( $help ) { Get-Help $MyInvocation.MyCommand; return; } # Call help on self and exit
}





function Save-UserConfig {
	# see git submodules
	# save /local
}

function Set-UserRepo {
	param(
		[string] $GitUser
	)
}


function New-UserConfigRepo {
	param(
		[string] $GitUser,
		[string] $GitRepo = "maxpowershell_config"
	)
}