<# File for User Facing, Omega Specific Commands #>

<#
.Synopsis
 Display the commands Omega provides
.LINK
Set-RegisterCommandAvailable
#>
function Get-CommandsAvailable {
	# print the table
	if ( ([User]::GetInstance()).RegisteredCommands -ne $null ){
		([User]::GetInstance()).RegisteredCommands
	} else {
		Write-Warning "No commands available, this is most likely an error."
	}
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
	$keys = & $($config.basedir)\system\git\usr\bin\ssh-add.exe -L 
	if( -not $keys ){
		Write-Warning "No keys present in ssh-agent`n Operation can not proceed, exiting."
	}
	foreach ( $line in ( & $($config.basedir)\system\git\usr\bin\ssh-add.exe -L ) ) {
		$sh = "cd ; umask 077 ; mkdir -p .ssh; touch .ssh/authorized_keys; grep '" + $line + "' "
		$sh += `
@"
-F ~/.ssh/authorized_keys > /dev/null || sed $'s/\r//' >> .ssh/authorized_keys || exit 1 ; if type restorecon >/dev/null 2>&1 ; then restorecon -F .ssh .ssh/authorized_keys ; fi
"@
		Write-Output "Sending Key: $($($line.Split(" ")) | Select-Object -last 1)"
		# do your thing
		$line | & $($config.basedir)\system\git\usr\bin\ssh.exe $ConnectionString $sh
	}
	
	# push bashrc and vimrc
	$(Invoke-WebRequest -UseBasicParsing $user.push_bashrc).Content | & $($config.basedir)\system\git\usr\bin\ssh.exe $ConnectionString "sed $'s/\r//' > ~/.bashrc"
	Write-Output "Sent .bashrc"
	$(Invoke-WebRequest -UseBasicParsing $user.push_vimrc).Content | & $($config.basedir)\system\git\usr\bin\ssh.exe $ConnectionString "sed $'s/\r//' > ~/.vimrc"
	Write-Output "Sent .vimrc"
	
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