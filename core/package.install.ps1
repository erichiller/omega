function Install-PackageFromURL {
	param(
		[Package] $Package
    )
    if ( $Package.Install.SearchPath.getType().BaseType.toString() -eq "System.Array" ){
	    [String] $concat = $Package.Install.SearchPath[0]
        $matchPath = @($Package.Install.SearchPath[0])
    } else {
        Write-Warning "Package's SearchPath *$($Package.Install.SearchPath) is of an invalid type: $($Package.Install.SearchPath.GetType())"
        return $false
    }
	$matchFilter = @{}
	for ( $i = 1; $i -lt $Package.Install.SearchPath.Length; $i++) {
		Write-Debug "i=$i of $($Package.Install.SearchPath.Length)"
		Write-Debug "requesting $concat"
		$filename = ( ((Invoke-WebRequest -UseBasicParsing -Uri $concat).Links | Where-Object { $_.href -match $Package.Install.SearchPath[$i] } | Where-Object { $_.href -notin $matchFilter[$i] }).href | Sort-Object )
		if ( -not $filename ) {
			Debug-Variable $matchPath "matchPath"
            Write-Warning "Filename not found, dropping i to recurse at the lower hierarchy"
			$i -= 2;
            if ( $i -le 0 ){
                Write-Warning "$i has decremented too many times, stopping processing"
                return $false
            }

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
			if ( $matchFilter.Count -eq 0 ) {
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
    Write-Verbose "Found Version: $version - Installing $Package to system."
    if ( $False -ne ( Install-DeployToOmegaSystem $Package $concat $filename $version ) ) {
        Install-PostProcessPackage $Package $version
    } else { return $False }
	return $version
}

function Install-PackageFromGitRelease {
	param(
		[Package] $Package
	)

	$url = "https://api.github.com/repos/$($Package.Install.Org)/$($Package.Install.Repo)/releases/latest"
	# The tag could also be used for the version, but I've found it generally less precise than parsing the download uri
	$json = (Invoke-WebRequest -UseBasicParsing -Uri $url | ConvertFrom-Json)
	if ( $json.name ) {
		Write-Verbose "Successfully navigated to latest release for $($json.name)"
	}
	if ( $json.tag_name ) {
		Write-Verbose "Latest release tagname: $($json.tagname)"
	}

	Write-Debug ( "download url is: $url" )
	[Net.ServicePointManager]::SecurityProtocol = 'Tls12';
	$json.assets | ForEach-Object {
		Write-Debug "Found git release asset: $($_.name)"
		$version = ( Select-String -Pattern $Package.Install.VersionPattern -InputObject $_.browser_download_url | ForEach-Object {"$($_.matches.groups[1])"} )
		if ( $version ) {
			Write-Verbose "Found Version: $version - Installing $Package to system."
			if ( Install-DeployToOmegaSystem $Package $_.browser_download_url $_.Name $version ) {
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
		[Package] $Package,
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
            if ( -not ( Update-SystemPath $expandedDirectory ) ) {
                Write-Error "System Path update FAILED on directory $expandedDirectory"
            }
        }
        SafeObjectArray $Package.System "SystemEnvironmentVariables" -Verbose
        # Update system environment variables
        if ( $Package.System.SystemEnvironmentVariables ) {
            Debug-Variable $Package.System.SystemEnvironmentVariables "Raw `$Package.System.SystemEnvironmentVariables"
            $path_updates = $Package.System.SystemEnvironmentVariables_Iterable()
            Debug-Variable $path_updates "Updates that `$Package=$($Package.Name) is going to make to the System Environment variables"
            foreach ($p in $path_updates) {
                Write-Debug "Updating environment variables... Expanding value<$($p.value)> for $($p.name) "
                $expandedValue = $ExecutionContext.InvokeCommand.ExpandString($p.Value)
                Write-Debug "System Environment Variables adding '$($p.Name)' = '$expandedValue'"
                if ( -not ( Update-SystemEnvironmentVariables -Name $p.Name -Value $expandedValue ) ) {
                    Write-Error "System Environment Variables update FAILED on $key = $expandedValue"
                }
            }
        }
		# mark as installed in the manifest
		[PackageState] $packageState = [PackageState]::new( $Package.name, $version )
		$user.setPackageState($packageState)
	} catch {

		Write-Warning "$($Package.name) module failed to load. Either not installed or there was an error. This module, who's function follow, will not be enabled:"
		Write-Warning "$($Package.brief)`n`n"
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
		[Package] $Package,
		[string] $sourcefile,
		[string] $filename,
		[string] $version,
		[Parameter(Mandatory = $False)] [switch] $AllowCachedFiles = [switch]::Present
	)
	$conf = [OmegaConfig]::GetInstance()

	$outFile = ( Join-Path $env:TEMP $filename )
	Write-Verbose "Source: $sourcefile"
	Write-Verbose "Destination: $outFile"
	Write-Verbose "Filename: $filename"
	Write-Verbose "Extension:'$([IO.Path]::GetExtension($filename))'"

	Write-Information "installing version $version of $($Package.name) ($filename)"

    $deployAllowRemoveDir = $True
	# deploy is where the Package will be _INSTALLED_ Can be a path or the special values listed here, see README too
	if ( $Package.Install.Destination -eq "SystemPath" ) {
		$deploy = ( Join-Path (Join-Path $conf.Basedir $conf.sysdir) $Package.Name )
	} elseif ($Package.Install.Desination -eq "BinPath" ) {
        $deploy = ( Join-Paths $conf.Basedir $conf.bindir )
        # if the package is going to the bindir it is almost certainly a single file
        if ( $conf.SingleFileExtensions -contains [IO.Path]::GetExtension($filename) ) {
            $flag_SingleFile = $True
            $outFile = Join-Paths $deploy $Package.Name [IO.Path]::GetExtension($filename)
        }
	} else {
		Write-Warning "Installation Destination of $($Package.Install.Desination) is unsupported"
		return $False
	}
	Write-Verbose "Deploy (installation directory): $deploy"
	# check if deploy path already exists
	if ( $deployAllowRemoveDir -eq $True -and
		( Test-Path $deploy ) -and
		$deploy -ne $conf.bindir -and
		$deploy -ne $conf.sysdir ) {
		if ( ( Read-Host "Deployment Path (installation directory) <$deploy> already exists, should it be removed? (y/n)" ).ToLower() -like "*y*" ) {
			try {
				# Remove-Item has too many issues
				[IO.Directory]::Delete($deploy, 1)
				Write-Information "$deploy removed"
			} catch {
				Write-Error "$deploy could not be removed, exiting"
				return $False
			}
		}
	}
	try {
		if ( Test-Path $deploy ) {
			Write-Error "$deploy removal failed attempt, exiting"
			return $False
		}
	} catch {
		Write-Warning ( "Received Exception '" + $_.Exception.Message + "' ; ignoring and continuing" )
	}
	Write-Verbose "Deploy (installation directory): $deploy"
	# download
	if ( $AllowCachedFiles -and ( Test-Path $outFile ) ) {
		Write-Information "using cached file: $outFile"
	} else {
		Write-Information "Downloading $filename from $sourcefile"
		(new-object System.Net.WebClient).DownloadFile( $sourcefile, $outFile )
	}
	# recurse through levels of compression
	# supported compressed file extensions
	Debug-Variable $conf.compression_extensions "Supported Compression Extensions"
	while ( $True ) {
		if ( $conf.compression_extensions -contains [IO.Path]::GetExtension($outFile) ) {
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
		if ( $(( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } ))) ) {
            $outFile = ( Join-Path $deploy ([IO.Path]::GetFileNameWithoutExtension($filename)) )

			Write-Debug "outFile set to child (extensionless parent): $outFile"
			# [IO.Path]  -- https://msdn.microsoft.com/en-us/library/system.io.path.getfilename(v=vs.110).aspx
			Write-Debug ("running --> Join-Path " + $env:TEMP + " " + [IO.Path]::GetFileName($outFile) )
            $tempPath = ( Join-Path $env:TEMP ([IO.Path]::GetFileName($outFile)) )

            Write-Verbose "test-path: $tempPath -> ( $True -eq $(Test-Path $tempPath ))"

            if ( $True -eq (Test-Path $tempPath )){
                # deploy already exists
                Write-Verbose "$tempPath already exists"
                if ( $True -eq $deployAllowRemoveDir ){
                    Write-Verbose "Permissions to remove dir are True"
                    try {
                        # Remove-Item has too many issues
                        [IO.Directory]::Delete($tempPath, 1)
                        Write-Information "$tempPath removed"
                    } catch {
                        Write-Error "$tempPath could not be removed, exiting"
                        return $False
                    }
                } else {
                    Write-Error "Deploy dir removal not allowed, could not remove $tempPath"
                }
            }

			if ( ! ( Test-Path $outFile ) ) {
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

    # only perform the following if the package consists of more than a single file
	if ( ( ( Test-Path variable:flag_SingleFile) -ne $True ) -or  $flag_SingleFile -ne $True ) {
		# check if the deployed directory ONLY Contains directories, this most likely means the package was zipped in a way that the first level directory should be removed.
		Write-Debug ( "Directories in the pre-installation directory: " + $(( Get-ChildItem -Attributes directory $deploy).Count ) )
		Write-Debug ( "Total Files in the pre-installation directory: " + $(( Get-ChildItem $deploy).Count ) )
		Write-Debug ( "If True, then ALL Files Contained in the directory are directories; and thus this should be elevated one level(boolean): " + $((( Get-ChildItem -Attributes directory $deploy).Count ) -eq (  ( Get-ChildItem  $deploy).Count )) )
		Debug-Variable (Get-ChildItem $deploy) "deploy path listing"
		Write-Debug $([IO.Path]::GetFileNameWithoutExtension($filename))
		Get-ChildItem $deploy | ForEach-Object { Write-Debug ( "deploy child name <" + $_.Name + ">equal extensionless parent<" + [IO.Path]::GetFileNameWithoutExtension($filename) + ">? " + ( $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) ) ) }

		# Raise folder one level if the deploy folder contains only a single folder named the same as the parent
		Write-Debug ( "Are any files within the deploy (installation) path named the same as the parent? (possible the directory needs to be raised one level); True=Yes(boolean): " + ( $( ( Get-ChildItem $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } )) -eq "" ) )

		Write-Debug ( " There is a single item in `$deploy and it matches the parent without extension? " + $(( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } ))) )

		if (( ( Get-ChildItem -Attributes directory $deploy).Count ) -eq ( ( Get-ChildItem $deploy).Count ) -and
			# Check if there is a single child-item, and if that single child-item has the same name as the file we just downloaded
			( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } )) ) {
			$tempPath = ( Join-Path $env:TEMP $Package.name )
            Write-Verbose "preparing to finalize destination... temporarily moving the package from:'$deploy' to:'$tempPath'"
            Write-Verbose "test-path: $tempPath -> ( $True -eq $(Test-Path $tempPath ))"
            if ( $True -eq (Test-Path $tempPath )){
                # deploy already exists
                Write-Verbose "$tempPath already exists"
                if ( $True -eq $deployAllowRemoveDir ){
                    Write-Verbose "Permissions to remove dir are True"
                    try {
                        # Remove-Item has too many issues
                        [IO.Directory]::Delete($tempPath, 1)
                        Write-Information "$tempPath removed"
                    } catch {
                        Write-Error "$tempPath could not be removed, exiting"
                        return $False
                    }
                } else {
                    Write-Error "Deploy dir removal not allowed, could not remove $tempPath"
                }
            }
            Move-Item $deploy -Destination $tempPath -Force
			Write-Verbose "final destination: moving the package from:'$( ( Join-Path $tempPath ([IO.Path]::GetFileNameWithoutExtension($filename))) )' to:'$deploy'"
			Move-Item ( Join-Path $tempPath ([IO.Path]::GetFileNameWithoutExtension($filename)) ) -Destination $deploy
		}
	}
	Write-Information "Package downloaded and unpacked successfully."
	return $True
}


<#
.SYNOPSIS
Install Omega Package to local computer
#>
function Install-OmegaPackage {
	param(
		# Package name to install
		[Parameter(Mandatory = $true)]
		[string]
		$PackageName
	)


	$Package = [Package]::GetInstance($PackageName)
	$Package.TestPrerequisites()
	Debug-Variable $Package "Packaged init in Install-OmegaPackage"

	switch ( $Package.Install.Source ) {
        "GitRelease" { Install-PackageFromGitRelease $Package }
        "WebDirSearch" { Install-PackageFromURL $Package }
		Default {
			Write-Warning "Package Installation Source of $($Package.Install.Source) is undefined in $([PackageInstallSource])"
		}
	}

}