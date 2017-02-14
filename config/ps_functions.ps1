

<#
 Helper Functions
#>

function ohelp {
	### change this to user help system!!!
	### md -> manpages /// xml help?

	Get-Content ( Join-Path $OMEGA_CONF.help "omega.install.md" )
}

# display the Path, one directory per line
# takes one input parameters, defaults to the env:Path
function Show-Path { 
	param (
	[string] $PathToPrint = $ENV:Path,
	[switch] $Debug,
	[switch] $System,
	[switch] $User
	)
	if ($System -eq $true) {
		$PathToPrint = (Get-ItemProperty -Path "$($OMEGA_CONF.system_environment_key)" -Name PATH).Path
	}
	if ($User -eq $true) {
		$PathToPrint = (Get-ItemProperty -Path "$($OMEGA_CONF.user_environment_key)" -Name PATH).Path
	}
	if($Debug -eq $false){
		echo ($PathToPrint).Replace(';',"`n")
	} else {
		Debug-Variable ($PathToPrint).Replace(';',"`n") "Show-Path"
	}
}

function Show-Env { echo (Get-ChildItem Env:) }

function Update-Config {
	$global:OMEGA_CONF = ( Get-Content (Join-Path $PSScriptRoot "\config.json" ) | ConvertFrom-Json )
}

function Update-Environment {
	Update-Config
	. ${env:basedir}\$($OMEGA_CONF.confdir)\ps_functions.ps1
}

function New-Shortcut {
	param(
		[string]$path
	)
	Update-Config
	if(!$env:basedir){
		Write-Warning "`$env:BaseDir is not set. Ensure that profile.ps1 is run properly first. Exiting immeditately, no action taken."
		return
	}
	if(!$path){ $path = $env:basedir }


	$TargetFile = ( Join-Path ( Join-Path $env:basedir $OMEGA_CONF.sysdir ) "ConEmu\ConEmu64.exe" )
	$ShortcutFile = Join-Path $path "omega.lnk"
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut( $ShortcutFile )

	$Shortcut.TargetPath = $TargetFile

	$Shortcut.Arguments =
		'/LoadCfgFile "' + ( Join-Path ( Join-Path $Env:Basedir $OMEGA_CONF.confdir ) "ConEmu.xml" ) + '" ' + 
		'/FontDir "' + ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir) "fonts" ) + '" ' + 
		'/Icon "' + ( Join-Path ( Join-Path $Env:Basedir "icons" ) "omega_256.ico" ) + '" /run "@..\..\config\powershell.cmd"'

	#$Shortcut.Arguments = '/LoadCfgFile "%HomePath%\AppData\Local\omega\config\ConEmu.xml" /FontDir "%HomePath%\AppData\Local\omega\system\nerd_hack_font" /Icon "%HomePath%\AppData\Local\omega\icons\omega_256.ico" /run "@%HomePath%\AppData\Local\omega\config\powershell.cmd"'

	$Shortcut.WorkingDirectory = "$env:HomePath"

	$Shortcut.IconLocation = Join-Path $env:basedir "icons\omega_256.ico"

	$Shortcut.Save()
	echo "Shortcut Created"

}

<#
.SYNOPSIS
Register-Omega-Shortcut creates an entry for Omega in the App Paths registry folder to index omega in windows start search
New-Shortcut must have been run prior.
#>
function Register-Omega-Shortcut {
	$omegaShortcut = Join-Path $env:basedir "omega.lnk"
	if(Test-Path $omegaShortcut ){
		New-Item -Path $($OMEGA_CONF.app_paths_key + "\omega.exe") -Value $omegaShortcut
	} else {
		Write-Warning "The shortcut to launch omega does not yet exist, create it first with `New-Shortcut` `n checked in $omegaShortcut"
	}
	
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
#.DESCRIPTION
# Print Variable value to debug
# Adapted from
#.Link
# http://stackoverflow.com/questions/35624787/powershell-whats-the-best-way-to-display-variable-contents-via-write-debug
function Debug-Variable { 
	param(
	[Parameter(Mandatory=$True)] $var,
	[string] $name
	)
	@(
		if([string]::IsNullOrEmpty($name) -ne $true) { "Debug-Variable: ===|$name|===" }
		#"Variable: $(Get-Variable | Where-Object {$_.Value -eq $var } )",
		#"Debug-Variable-Type:$(get-member -inputobject $var | Format-Table -AutoSize -Wrap | Out-String )",
		"Debug-Variable-Type:$($var.getType())",
		"Debug-Variable`n----START-VALUE-PRINT----`n$( $var | Format-Table -AutoSize -Wrap | Out-String )----END-VALUE-PRINT----" 
	) | Write-Debug
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

	Move-Item -Path $Source -Destination $Destination (&{If($Force) {"-Force"}})
	}
}


<##################################
 ######### package logic ##########
 ##################################>

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


	function ArrayAddUnique {
		param(
		[Parameter(Mandatory=$True,Position=1)]
		[AllowEmptyCollection()]
		[Object[]] $AddTo,

		[Parameter(Mandatory=$True,Position=2)]
		[String] $AdditionalItem
		)

		if( $AddTo -notcontains $AdditionalItem){
			$AddTo += $AdditionalItem
		}
		return $AddTo

		
	}

	function SafeObjectArray {
		param(
		[Parameter(Mandatory=$True,Position=1)]
		[PSCustomObject] $object,

		[Parameter(Mandatory=$True,Position=2)]
		[string] $pN
		)

		# debug
		if ( $VerbosePreference ){
			echo "object---"
			$object | Get-Member | Format-Table
			echo "propertyName---"
			$pN | Get-Member | Format-Table
			echo "end---"
		}
		
		if(!(Get-Member -InputObject $object -Name $pN -Membertype Properties)) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name $pN -Value $ArrayList

			#debug
			if ( $VerbosePreference ){ 
				echo "$pN not present on $object"
				$object | Get-Member | Format-Table
			}
			$object.$pN = @()
		}
	}
	
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
					rm -Force $bin
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
				$binPath = Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.bindir)  $binPath
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
		$Package = ($Packages | Where-Object { $_.name -EQ $PackageName } )
		echo "================================================>PACKAGE========================>"
		$Package
		echo "================================================>END========================>"
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
	if( -not (& setx PATH /m $Path) ){ return $false }

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
		[Switch] $delete
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
	$regex = "^[[:blank:]]*cd ([a-zA-Z\~:]+([$dirSep][^$dirSep]+)*[$dirSep]([^$dirSep]+)[$dirSep]?)$"
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
				$lowestDirectory = $matches[($matches.keys | sort -Descending | Select-Object -First 1)]
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
		function Set-LocationHelper($dir) {
			if ( $delete ){
				Clear-History -CommandLine $filteredDirs -Confirm
			} else {
				Set-Location $dir
			}
		}
	}
	process {

		$dirSearch = $PsBoundParameters.dirSearch
		Debug-Variable $searchHistory "f/searchHistory"

		Write-Debug "dirSearch=$dirSearch"
		
		#this is doing ___EQUAL___ /// or do I want to be doing a like dirSearch*
		$filteredDirs = $searchHistory.GetEnumerator() | ?{ $_.Value -eq $dirSearch } 

		# if there is a single match
		if ( $filteredDirs.count -eq 1 ){
			$testedPath =$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($filteredDirs.name)
			if( $testedPath | Test-Path ){
				Set-LocationHelper $testedPath
			}
		} else {
			# there are multiple matches
			# do a lookup for number of times it was cd'd into with the searchCount
			Debug-Variable $searchCount

			$searchCount.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
				$countedDir = $_
				$highestDir = ( $filteredDirs.GetEnumerator() | ?{$_.Name -contains $countedDir.Name} )
				if ( $highestDir.count -eq 1 ){ 
					$testedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($highestDir.name) 
					if( $testedPath | Test-Path ){
						Set-LocationHelper $testedPath
					} else {
						Write-Warning "Tried to cd to $($highestDir.name) (resolved to $testedPath), but it does not exist"
					}
				} else {
					$highestDir.name
				}
			}
		}

		if( ( $testedPath ) `
				-and ( -not ( $testedPath | Test-Path ) ) ){
			Write-Information "Could not find test string, possibly not an absolute path, Attempting to Locate"
			

			# could look at prior cd to determine location?
			# if test path fails - scan all subdirectories of the current working directory, looking for a match
		}




	
		#cd $searchHistory.GetEnumerator() | ?{ $_.Value -eq $dirSearch } | Sort-Object -Property Value -Descending | Select-Object -First 1
		#$searchCount | Sort

	<#
$a | Select-Object -Unique
( $filename | Select-String -Pattern $Package.installParams.versionPattern | % {"$($_.matches.groups[1])"} )

	#>

	# directories under current working directory
	#$wd = Get-Location
	#$directories = Get-ChildItem -Path $wd -Recurse -Directory -Name

	

	} <# End process {} #>

}

function Get-PrettyPath {
    param (
    [System.Management.Automation.PathInfo] $dir
    )
	if ( -not $dir ){ $dir = Get-Location }
    $provider = (Get-Item $dir).PSProvider.Name
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

