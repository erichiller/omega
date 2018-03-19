function Install-PackageFromURL ($Package) {
	[String] $concat = $Package.Install.SearchPath[0]
	$matchPath = @($Package.Install.SearchPath[0])
	$matchFilter = @{}
	for ( $i = 1; $i -lt $Package.Install.SearchPath.Length; $i++) {
		Write-Debug "i=$i of $($Package.Install.SearchPath.Length)"
		Write-Debug "requesting $concat"
		$filename = ( ((Invoke-WebRequest -UseBasicParsing -Uri $concat).Links | Where-Object { $_.href -match $Package.Install.SearchPath[$i] } | Where-Object { $_.href -notin $matchFilter[$i] }).href | Sort-Object )
		if ( -not $filename ) {
			Debug-Variable $matchPath "matchPath"
			Write-Warning "Filename not found, dropping i to recurse at the lower hierarchy"
			$i-=2;

			$matchPath = $matchPath[0..($matchPath.length - 2)]

			Debug-Variable $matchPath "matchPath"

			$concat = $matchPath -join ""
			Debug-Title -BackgroundColor White "Concat reverted to: $concat"
		} else {
			if ( $filename.getType().BaseType.toString() -eq "System.Array" ) {
				Write-Host -BackgroundColor Yellow "Is Array"
				$filename = $filename | Select-Object -Last 1
			}
			$concat += $filename
			$matchPath += $filename
			if( $matchFilter.Count -eq 0 ){
				$matchFilter[$i] = @()
			}
			$matchFilter[$i] += $filename
			Debug-Variable $matchFilter "matchFilter"

			Write-Debug "Append Filename: $filename"
			Write-Debug "New Search Path(concat): $concat"
		}
	}
	Write-Debug "Found Filename: $filename"
	Write-Debug "Final Path(concat): $concat"
	
	$version = ( $filename | Select-String -Pattern $Package.Install.VersionPattern | ForEach-Object {"$($_.matches.groups[1])"} )
	Write-Debug "Found Version: $version"

	# deploy
	Write-Debug "(concat): $concat"
	Install-DeployToOmegaSystem $Package $concat $filename $version
	
	return $version
}



function Install-PackageFromGitRelease {
	param(
		[string] $PackageName
	)
	
	Test-InstallPrerequisite $PackageName
	$Package = [Package]::GetInstance($PackageName)
	Debug-Variable $Package "Packaged init in Install-PackageFromGitRelease"

	# $Package.getType() | Write-Host -ForegroundColor "Green"
	# $Package.Name | Write-Host -ForegroundColor "Magenta"
	# $Package.Install.AdminRequired | Write-Host -ForegroundColor "Magenta"
	# ( "`$Package members:`n" + ( $Package | get-member | out-string) ) | Write-Host -ForegroundColor "Cyan"


	$url="https://api.github.com/repos/$($Package.Install.Org)/$($Package.Install.Repo)/releases/latest"

	Write-Debug ( "download url is: $url" )
	[Net.ServicePointManager]::SecurityProtocol = 'Tls12';
	(Invoke-WebRequest -UseBasicParsing -Uri $url | ConvertFrom-Json).assets | ForEach-Object {
		Write-Debug "Found git release asset: $($_.name)"
		#  (Select-String -Pattern $Package.Install.VersionPattern -InputObject $_.name) | Format-List
		$version = ( Select-String -Pattern $Package.Install.VersionPattern -InputObject $_.Name | ForEach-Object {"$($_.matches.groups[1])"} )
		if ( $version ){
			Write-Debug "Found Version: $version - Installing $Package to system."
			if ( Install-DeployToOmegaSystem $Package $_.browser_download_url $_.Name $version ){
				Install-PostProcessPackage $Package $version
			}
			break;
		}
	}
}


<#
.SYNOPSIS
Install-PostProcessPackage runs $Package.postInstall lines and any finalizing code.
.PARAMETER Package
Package is the Object from pkg.json for the package being installed.
#>
function Install-PostProcessPackage {
	param(
		$Package,
		[string] $version
	)

	$user = [User]::GetInstance()
	Write-Verbose "Package Post Processing..."
	
	<#
	no matter the package type
	we run the postInstall actions
	#>
	try {
		Debug-Variable $Package.System "Raw `$Package.System"
		# Update system path
		Debug-Variable $Package.System.PathAdditions "Raw `$Package.System.PathAdditions"				
		$Package.System.PathAdditions | ForEach-Object {
			$expandedDirectory = $ExecutionContext.InvokeCommand.ExpandString($_)
			Write-Debug "System Path adding directory '$expandedDirectory'"
			if ( -not ( Update-SystemPath $expandedDirectory ) ){
				Write-Error "System Path update FAILED on directory $expandedDirectory"
			}
		}
		# Update system environment variables
		Debug-Variable $Package.System.SystemEnvironmentVariables "Raw `$Package.System.SystemEnvironmentVariables"
		$path_updates = $Package.System.SystemEnvironmentVariables_Iterable()
		Debug-Variable $path_updates "Updates that `$Package=$($Package.Name) is going to make to the System Environment variables"
		foreach ($p in $path_updates) {
			Write-Debug "Updating environment variables... Expanding value<$($p.value)> for $($p.name) "
			$expandedValue = $ExecutionContext.InvokeCommand.ExpandString($p.Value)
			Write-Debug "System Environment Variables adding '$($p.Name)' = '$expandedValue'"
			if ( -not ( Update-SystemEnvironmentVariables -Name $p.Name -Value $expandedValue ) ){
				Write-Error "System Environment Variables update FAILED on $key = $expandedValue"
			}
		}
		# mark as installed in the manifest
		[PackageState] $packageState = [PackageState]::new( $Package.name, $version )
		$user.setPackageState($packageState)
	} catch {
		
		Write-Warning "$($Package.name) module failed to load. Either not installed or there was an error. This module, who's function follow, will not be enabled:"
		Write-Warning $Package.brief
		$e = $_.Exception
		$line = $_.InvocationInfo.ScriptLineNumber
		$file = $_.InvocationInfo.ScriptName
		$position = $_.InvocationInfo.DisplayScriptPosition
		$msg = $e.Message 
		Write-Host -ForegroundColor Red "caught (msg) exception: $msg at $($file):$($line):$($position)"

		Write-Host -ForegroundColor Red "caught exception: $e at $line"

		Write-Debug "last seen expandedDirectory=$expandedDirectory"
		$e | format-list -force
		$e.Exception.InvocationInfo | format-list -force
	}


}


function Install-DeployToOmegaSystem {
	param(
		$Package,
		[string] $sourcefile,
		[string] $filename,
		[string] $version,
		[Parameter(Mandatory = $False)] [switch] $AllowCachedFiles=[switch]::Present
	)
	$conf = [OmegaConfig]::GetInstance()

	if ( (Test-InstallPrerequisite) -eq $False ) { return $False }	

	$outFile = ( Join-Path $env:TEMP $filename )
	Write-Verbose "Source: $sourcefile"
	Write-Verbose "Destination: $outFile"
	Write-Verbose "Filename: $filename"
	Write-Verbose "Extension:'$([IO.Path]::GetExtension($filename))'"

	Write-Information "installing version $version of $($Package.name) ($filename)"
	
	# deploy is where the Package will be _INSTALLED_
	if ( $Package.Install.Destination -eq "SystemPath" ){
		$deploy = ( Join-Path (Join-Path $conf.Basedir $conf.sysdir) $Package.Name )
	} else {
		Write-Warning "Installation Desitnation of $($Package.Install.Desination) is unsupported"
		return $False
	}
	Write-Verbose "Deploy (installation directory): $deploy"	
	# check if deploy path already exists
	if ( Test-Path $deploy ){
		if ( ( Read-Host "Deployment Path (installation directory) <$deploy> already exists, should it be removed? (y/n)" ).ToLower() -like "*y*" ){
			try {
				# Remove-Item has too many issues
				[IO.Directory]::Delete($deploy,1)
				Write-Information "$deploy removed"
			} catch {
				Write-Error "$deploy could not be removed, exiting"
				return $False
			}
		}
	}
	try {
		if ( Test-Path $deploy ){
			Write-Error "$deploy removal failed attempt, exiting"		
			return $False
		}
	} catch {
		Write-Warning ( "Received Exception '" + $_.Exception.Message + "' ; ignoring and continuing" )
	}
	Write-Verbose "Deploy (installation directory): $deploy"
	# download
	if ( $AllowCachedFiles -and ( Test-Path $outFile ) ){
		Write-Information "using cached file: $outFile"
	} else {
		Write-Information "Downloading $filename from $sourcefile"
		(new-object System.Net.WebClient).DownloadFile( $sourcefile, $outFile )
	}
	# recurse through levels of compression
	# supported compressed file extensions
	Debug-Variable $conf.compression_extensions "Supported Compression Extensions"
	while ( $True ){
		if( $conf.compression_extensions -contains [IO.Path]::GetExtension($outFile) ){
			Write-Verbose ( "Decompression of $outFile required. extension:" + [IO.Path]::GetExtension($outFile) + "; Decompressing to the deployment directory:$deploy" )
			# add ` -bb1` as an option to `7z` for more verbose output 
			& 7z x $outFile "-o$deploy"
			if ( (-not (Test-Path $deploy) ) -and ( $? -eq $False ) ) {
				Write-Error "7z failure in decompression. exiting"
				return $False
			}
		} else {
			Write-Verbose "Not a compressed file, moving file."
			Move-Item $outFile -Destination $deploy
			break
		}
		Write-Debug ( " There is a single item in `$deploy and it matches the parent without extension? " + $(( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } ))) )
		if ( $(( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } ))) ){
			$outFile = ( Join-Path $deploy ([IO.Path]::GetFileNameWithoutExtension($filename)) )
			Write-Debug "outFile set to child (extensionless parent): $outFile"
			# [IO.Path]  -- https://msdn.microsoft.com/en-us/library/system.io.path.getfilename(v=vs.110).aspx
			Write-Debug ("running --> Join-Path " + $env:TEMP + " " + [IO.Path]::GetFileName($outFile) )
			$tempPath = ( Join-Path $env:TEMP ([IO.Path]::GetFileName($outFile)) )
			if ( ! ( Test-Path $outFile ) ){
				Write-Error "$outFile does not exist. Can not move file. Exiting."
				return $False
			}
			Write-Verbose "temporarily moving the package from:'$deploy' to:'$tempPath'"
			Move-Item $outFile -Destination $tempPath -Force
			$outFile = $tempPath			
			continue
		} else {
			Write-Debug ("either there was more than a single child in $deploy or it had did not match " + [IO.Path]::GetFileNameWithoutExtension($filename))
			break
		}
		Write-Debug "Reached the end of the decompression loop"
		break
	}
	
	# check if the deployed directory ONLY Contains directories, this most likely means the package was zipped in a way that the first level directory should be removed.
	Write-Debug ( "Directories in the pre-installation directory: " + $(( Get-ChildItem -Attributes directory $deploy).Count ) )
	Write-Debug ( "Total Files in the pre-installation directory: " + $(( Get-ChildItem $deploy).Count ) )
	Write-Debug ( "If True, then ALL Files Contained in the directory are directories; and thus this should be elevated one level(boolean): " + $((( Get-ChildItem -Attributes directory $deploy).Count ) -eq (  ( Get-ChildItem  $deploy).Count )) )
	Debug-Variable (Get-ChildItem $deploy) "deploy path listing"
	Write-Debug $([IO.Path]::GetFileNameWithoutExtension($filename))
	Get-ChildItem $deploy | ForEach-Object { Write-Debug ( "deploy child name <" + $_.Name + ">equal extensionless parent<"+[IO.Path]::GetFileNameWithoutExtension($filename)+">? " + ( $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) ) ) }

	# Raise folder one level if the deploy folder contains only a single folder named the same as the parent
	Write-Debug ( "Are any files within the deploy (installation) path named the same as the parent? (possible the directory needs to be raised one level); True=Yes(boolean): " + ( $( ( Get-ChildItem $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } )) -eq "" ) )
	
	Write-Debug ( " There is a single item in `$deploy and it matches the parent without extension? " + $(( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } ))) )

	if (( ( Get-ChildItem -Attributes directory $deploy).Count ) -eq ( ( Get-ChildItem $deploy).Count ) -and 
		# Check if there is a single child-item, and if that single child-item has the same name as the file we just downloaded
		( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } )) ) {
		$tempPath = ( Join-Path $env:TEMP $Package.name )
		Write-Verbose "temporarily moving the package from:'$deploy' to:'$tempPath'"
		Move-Item $deploy -Destination $tempPath -Force
		Move-Item ( Join-Path $tempPath ([IO.Path]::GetFileNameWithoutExtension($filename)) ) -Destination $deploy
	}
	Write-Information "Package downloaded and unpacked successfully."
	return $True
}

function Test-InstallPrerequisite {
	[OutputType([bool])]
	param(
		[string] $PackageName
	)
	$Conf = [OmegaConfig]::GetInstance()
	
	Write-Verbose "Checking Prerequisites for the PACKAGE<$PackageName>"
	$local:e = "Missing Dependency! Installation is impossible; missing:"

	if ( ( [boolean] (Get-Command -Name "7z" -ErrorAction SilentlyContinue) ) -eq $False ){
		if (Test-Path "C:\Program Files\7-Zip\7z.exe"){
			. $PSScriptRoot\core.ps1
			Add-DirToPath "C:\Program Files\7-Zip\"
		} else {
			Write-Error "${local:e} 7zip"
			return $False
		}
	}

	Write-Verbose "Basic Dependencies met."	
	if ( -not $PackageName){
		# package name not set, only testing for basic dependencies which were successful, return true.
		Write-Verbose "continuing..."
		return $True
	}

	$pkg_config = "$($conf.basedir)\core\pkg\$PackageName\pkg.json"
	if ( !(Test-Path $pkg_config) ){
		Write-Error "Package config not found: $pkg_config"
		exit
	}
	$Package = [Package]::GetInstance($PackageName)

	Write-Debug "Package.Install.AdminRequired: $($Package.Install.AdminRequired)"
	Write-Debug "Test-Admin: $(Test-Admin)"	
	if ( ( Test-Path variable:Package.System.PathAdditions ) -or ( Test-Path variable:Package.System.SystemEnvironmentVariables ) ){
		if ( -not $Package.Install.AdminRequired ){
			Write-Warning "Package.adminRequired is `$False ; however if either `PathAdditions` or `SystemEnvironmentVariables` is specified `Install.AdminRequired` is equated to `$True`."
			# set to $True for operations.
			$Package.Install.AdminRequired = $True
		}
	}
	if ( $Package.Install.AdminRequired -and !(Test-Admin) ){
		Write-Warning "You must be in administrator shell to install this package. Opening Administrator prompt..."
		# powershell.exe "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -File c:\install.ps1' -Verb RunAs"
		powershell.exe "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoLogo' -Verb RunAs"
		Write-Verbose "Returning False in `$Package.Install.AdminRequired -and !(Test-Admin)"
		exit
	}
	( "{ in test-preq } `$Package members:`n" + ( $Package | get-member | out-string) ) | Write-Host -ForegroundColor "Magenta"
	Write-Verbose "Test-InstallPrerequisite reporting success, $True"
	return $True
}
