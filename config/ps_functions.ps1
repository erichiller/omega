<#
.Synopsis
 Helper Functions
#>




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

	if (!$env:basedir) {
		Write-Warning "`$env:BaseDir is not set. Ensure that profile.ps1 is run properly first. Exiting immeditately, no action taken."
		return
	}

	# if no shortcut file is specified, create a default on in the start menu folder
	if ( -not $shortcutFile) {
		# MUST BE ADMIN to create in the default start menu location;
		# check, if not warn and exit
		if ( -not (Test-Admin -warn) ) { return }
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
	if ( -not (Test-Admin -warn) ) { return }
	
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
			"SystemPath" {
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
