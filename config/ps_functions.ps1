

<#
 Helper Functions
#>

# display the Path, one directory per line
# takes one input parameters, defaults to the env:Path
function Show-Path { 
	param (
	[string] $PathToPrint = $ENV:Path,
	[switch] $Debug,
	[switch] $System
	)
	if ($System -eq $true) {
		$PathToPrint = (Get-ItemProperty -Path "$($OMEGA_CONF.system_path_key)" -Name PATH).Path
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
	if(!$string){ $path = $env:basedir }
	echo "Shortcut Created"


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
}

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
		Get-KeePassEntry -DatabaseProfileName $OMEGA_CONF.packages.keepass.profile -AsPlainText | Select-Object -Property Title,UserName,Password,FullPath,Notes | Where { $_.Title , $_.Username , $_.Notes -like "*${searchString}*"} | Tee-Object -Variable KeePassEntry | Format-Table
	} else {
		#Get-KeePassEntry -DatabaseProfileName $$OMEGA_CONF.packages.keepass.profile -AsPlainText | Select-Object -Property Title,UserName,FullPath,Notes | Where {$_ -like "*${searchString}*"} | Format-Table | $KeePassEntry = 
		Get-KeePassEntry -DatabaseProfileName $$OMEGA_CONF.packages.keepass.profile -AsPlainText | Select-Object -Property Title,UserName,FullPath,Notes | Where { $_.Title , $_.Username , $_.Notes -like "*${searchString}*"} | Tee-Object -Variable KeePassEntry | Format-Table

	}
	if($copyPass){
		Get-KeePassEntry -DatabaseProfileName $$OMEGA_CONF.packages.keepass.profile -AsPlainText | Select-Object -Property Title,UserName,Password,FullPath,Notes | Where { $_.Title , $_.Username , $_.Notes -like "*${searchString}*"} | Tee-Object -Variable KeePassEntry | Select -ExpandProperty "Password"
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
		$Package = ($Packages | Where { $_.name -EQ $PackageName } )
		echo "================================================>PACKAGE========================>"
		$Package
		echo "================================================>END========================>"
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
###				SafeObjectArray("postInstall",$Package)
				# import our newly installed module
				ArrayAddUnique $Package.postInstall { Import-Module -name $Package.name -ErrorAction Stop >$null }
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
						
						#Start-BitsTransfer -Source ( $Package.installParams.searchPath + $filename ) -Destination $outFile -Description "omega opkg install version $version of $($Package.installParams.searchPath)($filename)"

						$deploy = (Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir)  $Package.name )
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
							Update-SystemPath $deploy
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
	$OriginalPath = (Get-ItemProperty -Path "$($OMEGA_CONF.system_path_key)" -Name PATH).Path
	Write-Debug "Checking Path at '$($OMEGA_CONF.system_path_key)' - currently set to `n$OriginalPath"
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
	& setx PATH /m $Path

	if( -not $ENV:Path.Contains($testDir) ){
		Write-Debug "$testDir is being added to the Environment Path as well as the System Path will only refresh for new windows"
		$ENV:Path += ";" + $testDir
	}

	Show-Path -Debug
}

