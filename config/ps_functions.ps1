

<#
 Helper Functions
#>

# display the Path, one directory per line
# takes one input parameters, defaults to the env:Path
function Show-Path { 
	param([string]$PathToPrint = $env:Path)
	echo ($PathToPrint).Replace(';',"`n")
}

function Show-Env { echo (Get-ChildItem Env:) }

<#
.SYNOPSIS
get-pass is a helper function for PoSh-KeePass
.DESCRIPTION
Allows for quick searching through results and displays. 
The default behavior is to list out the entries, but not display the password.
Use the `-showPass` flag in order to display the Password
.PARAMETER showPass
Flag which will 
#>
function get-pass {
	param(
		[string]$searchString,
		[switch]$showPass,
		[switch]$copyPass
		)
 
	if ($showPass) { 
		Get-KeePassEntry -DatabaseProfileName $OMEGA_KEEPASS_PROFILE -AsPlainText | Select-Object -Property Title,UserName,Password,FullPath,Notes | Where { $_.Title , $_.Username , $_.Notes -like "*${searchString}*"} | Tee-Object -Variable KeePassEntry | Format-Table
	} else {
		#Get-KeePassEntry -DatabaseProfileName $OMEGA_KEEPASS_PROFILE -AsPlainText | Select-Object -Property Title,UserName,FullPath,Notes | Where {$_ -like "*${searchString}*"} | Format-Table | $KeePassEntry = 
		Get-KeePassEntry -DatabaseProfileName $OMEGA_KEEPASS_PROFILE -AsPlainText | Select-Object -Property Title,UserName,FullPath,Notes | Where { $_.Title , $_.Username , $_.Notes -like "*${searchString}*"} | Tee-Object -Variable KeePassEntry | Format-Table

	}
	if($copyPass){
		Get-KeePassEntry -DatabaseProfileName $OMEGA_KEEPASS_PROFILE -AsPlainText | Select-Object -Property Title,UserName,Password,FullPath,Notes | Where { $_.Title , $_.Username , $_.Notes -like "*${searchString}*"} | Tee-Object -Variable KeePassEntry | Select -ExpandProperty "Password"
		if ( $KeePassEntry.pass.count -eq 1 ){
			$KeePassEntry.pass | Set-Clipboard
		} else {
			echo "Clipboard not set as there was more than one result."
		}
	}
	#return $KeePassEntry
	return $KeePassEntry[0].Title
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

function Add-DirToPath($dir){
	# ensure the directory exists
	if (Test-Path -Path $dir ) {
		# if it isn't already in the PATH, add it
		if( -not $env:Path.Contains($dir) ){
			$env:Path += ";" + $dir
		}
	}
}

<##################################
 ######### package logic ##########
 ##################################>

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
	[switch] $Help=[switch]::Present
	)

	$CallingDirectory = (Convert-Path . )
	if ( $Status ) {
		if ( $PackageName ){
			Get-Module $PackageName
		} else {
			Get-Module
		}
	}
	if ( $Install ) {
		$Packages = ( Get-Content (Join-Path $PSScriptRoot "\manifest.json" ) | ConvertFrom-Json )
		echo "================================================>PACKAGES========================>"
		$Packages
		echo "================================================>END========================>"
		$Package = ($Packages | Where { $_.name -EQ $PackageName } )
		echo "================================================>PACKAGE========================>"
		$Package
		echo "================================================>END========================>"
		switch ( $Package.type ) {
			"psmodule" {
				switch ( $Package.installMethod ){
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
		Set-Location ( Join-Path $ModulePath $Package.name )
		ForEach( $command in $Package.postInstall ) {
			$command
		}
		# mark as installed in the manifest
		$Package.state.updateDate = (Get-Date -format "yyyy-MMM-dd HH:mm" )
		$Package.state.installed = $true
		$Packages | ConvertTo-Json | Set-Content ( Join-Path $PSScriptRoot "\manifest.json" )
		# import our newly installed module
		try {
			Import-Module -name $Package.name -ErrorAction Stop >$null
		} catch {
			Write-Warning "${Package.name} module failed to load. Either not installed or there was an error. This module, who's functions follow, will now be disabled:"
			Write-Warning $Package.brief
		}
		
	}
	if ( $Help -and !$Status -and !$Install -and !$List -and !$Update ){
		$Script:MyInvocation.invocationname
	}
	Set-Location $CallingDirectory
}

