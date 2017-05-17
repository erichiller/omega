
# $json = @"
# {
#     "type":  "system-path",
#     "name":  "nodejs",
#     "brief":  "Javascript Desktop Engine",
#     "required":  false,
#     "installMethod":  "http-directory-search",
    # "installParams": {
	# 	"searchPath": [
	# 		"https://www.python.org/ftp/python/",
	# 		"[0-9]\\.[0-9]\\.[0-9]",
	# 		"^python-([0-9]\\.[0-9]\\.[0-9])-embed-amd64\\.zip$"
	# 	],
    #     "versionPattern":  "^python-([0-9]\\.[0-9]\\.[0-9])-embed-amd64.zip",
    #     "systempath":  true
    # },
#     "state": {
#         "updateDate":  "2017-Jan-30 10:45",
#         "installed":  true
# 				},
#     "postInstall":  "Write-OmegaConfig"
# }
# "@

# $Package = ($json | ConvertFrom-Json)

# $Package

function Install-PackageFromURL ($Package) {
    $concat = $Package.installParams.searchPath[0]
    for ( $i = 1; $i -lt $Package.installParams.searchPath.Length; $i++) {
        Write-Output "requesting $concat"
        $filename = ((Invoke-WebRequest -UseBasicParsing -Uri $concat).Links | Where { $_.href -match $Package.installParams.searchPath[$i] }).href | Sort-Object | Select-Object -Last 1
        $concat += $filename
        Write-Output "Found Filename: $filename"
		Write-Output "(concat): $concat"
    }
    Write-Output "Found Filename: $filename"
	Write-Output "(concat): $concat"

    $version = ( $filename | Select-String -Pattern $Package.installParams.versionPattern | % {"$($_.matches.groups[1])"} )
    Write-Output "Found Version: $version"

	# deploy
	Write-Output "(concat): $concat"
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
    Write-Debug "Extension:'$([IO.Path]::GetExtension($filename))'"
						
    Start-BitsTransfer -Source $sourcefile -Destination $outFile -Description "omega opkg install version $version of $($Package.installParams.searchPath)($filename)"

    $deploy = ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir) $Package.name )
    Write-Debug "Deploy: $deploy"
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
    Write-Debug $(( Get-ChildItem -Attributes directory $deploy).Count )
    Write-Debug $(( Get-ChildItem $deploy).Count )
    Write-Debug $((( Get-ChildItem -Attributes directory $deploy).Count ) -eq (  ( Get-ChildItem  $deploy).Count ))
    Debug-Variable (Get-ChildItem $deploy)
    Write-Debug $([IO.Path]::GetFileNameWithoutExtension($filename)) 

    Write-Debug "Filename: $filename"
    Write-Debug "Deploy: $deploy"

    Write-Debug $( ( Get-ChildItem  $deploy | Where { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } ))
    Write-Debug $(( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename)  } )))
    if (( ( Get-ChildItem -Attributes directory $deploy).Count ) -eq (  ( Get-ChildItem  $deploy).Count ) -and 
        # Check if there is a single child-item, and if that single child-item has the same name as the file we just downloaded
        ( ( Get-ChildItem $deploy).Count -eq 1 ) -and ( ( Get-ChildItem  $deploy | Where { $_.Name -eq [IO.Path]::GetFileNameWithoutExtension($filename) } )) ) {
        $tempPath = ( Join-Path $env:TEMP $Package.name )
        Write-Debug "temporarily moving the package from:'$deploy' to:'$tempPath'"
        Move-Item $deploy -Destination $tempPath -Force
        Move-Item ( Join-Path $tempPath ([IO.Path]::GetFileNameWithoutExtension($filename)) ) -Destination $deploy
    }
}

