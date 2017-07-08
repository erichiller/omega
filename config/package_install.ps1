function Install-PackageFromURL ($Package) {
	[String] $concat = $Package.installParams.searchPath[0]
	$matchPath = @($Package.installParams.searchPath[0])
	$matchFilter = @{}
	for ( $i = 1; $i -lt $Package.installParams.searchPath.Length; $i++) {
		Write-Debug "i=$i of $($Package.installParams.searchPath.Length)"
		Write-Debug "requesting $concat"
		$filename = ( ((Invoke-WebRequest -UseBasicParsing -Uri $concat).Links | Where-Object { $_.href -match $Package.installParams.searchPath[$i] } | Where-Object { $_.href -notin $matchFilter[$i] }).href | Sort-Object )
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
	
	$version = ( $filename | Select-String -Pattern $Package.installParams.versionPattern | ForEach-Object {"$($_.matches.groups[1])"} )
	Write-Debug "Found Version: $version"

	# deploy
	Write-Debug "(concat): $concat"
	Install-DeployToOmegaSystem $Package $concat $filename
	
	return $version
}


function Install-DeployToOmegaSystem {
	param(
	$Package,
	[string] $sourcefile,
	[string] $filename
	)

	$outFile = ( Join-Path $env:TEMP $filename )
	Write-Debug "Source: $sourcefile"
	Write-Debug "Destination: $outFile"
	Write-Debug "Filename: $filename"
	Write-Debug "Extension:'$([IO.Path]::GetExtension($filename))'"

	Write-Information "omega opkg install version $version of $($Package.name) ($filename)"
	(new-object System.Net.WebClient).DownloadFile( $sourcefile, $outFile )
	# deploy is where the Package will be _INSTALLED_
	$deploy = ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir) $Package.name )
	Write-Debug "Deploy (installation directory): $deploy"
	Debug-Variable $OMEGA_CONF.compression_extensions
	if ( $OMEGA_CONF.compression_extensions -contains [IO.Path]::GetExtension($filename) ) {
		Write-Debug "Decompression of $outFile required... Decompressing to the deployment directory:$deploy"
		# add ` -bb1` as an option to `7z` for more verbose output 
		& 7z x $outFile "-o$deploy"
	}
	else {
		Move-Item $outFile -Destination $deploy
	}
	# check if the deployed directory ONLY Contains directories, this most likely means the package was zipped in a way that the first level directory should be removed.
	Write-Debug ( "Directories in the pre-installation directory: " + $(( Get-ChildItem -Attributes directory $deploy).Count ) )
	Write-Debug ( "Total Files in the pre-installation directory: " + $(( Get-ChildItem $deploy).Count ) )
	Write-Debug ( "True=All Files Contained in the directory are directories; and thus this should be elevated one level(boolean): " + $((( Get-ChildItem -Attributes directory $deploy).Count ) -eq (  ( Get-ChildItem  $deploy).Count )) )
	Debug-Variable (Get-ChildItem $deploy)
	Write-Debug $([IO.Path]::GetFileNameWithoutExtension($filename)) 

	Write-Debug "Filename: $filename"
	Write-Debug "Deploy (installation directory): $deploy"


	# Is there 
	Write-Debug ( "Are any files within the deploy (installation) path named the same as the parent? (possible the directory needs to be raised one level); True=Yes(boolean): " + ( $( ( Get-ChildItem $deploy | Where-Object { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } )) -eq "" ) )
	
	Write-Debug $(( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } )))
	if (( ( Get-ChildItem -Attributes directory $deploy).Count ) -eq ( ( Get-ChildItem  $deploy).Count ) -and 
		# Check if there is a single child-item, and if that single child-item has the same name as the file we just downloaded
		( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } )) ) {
		$tempPath = ( Join-Path $env:TEMP $Package.name )
		Write-Debug "temporarily moving the package from:'$deploy' to:'$tempPath'"
		Move-Item $deploy -Destination $tempPath -Force
		Move-Item ( Join-Path $tempPath ([IO.Path]::GetFileNameWithoutExtension($filename)) ) -Destination $deploy
	}
}

