

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
 ######### symlink logic ##########
 ##################################>


# cleanup the directory of items not specified
# logic:
# if it is a hardlink (not a local file // a file that only exists in `bin` holder)
# it will have more than one hardlink to it in `fsutil hardlink query`
# so check if it is in OMEGA_EXT_BINARIES array
# if not - delete it
function test-bin-hardlinks {
	
	Get-ChildItem $OMEGA_BIN_PATH |
	ForEach-Object {
		$bin = ( Join-Path $OMEGA_BIN_PATH $_.name ) 

		$links = ( fsutil hardlink list $bin )
		# list number of hardlinks:
		# echo " $bin = " + (fsutil hardlink list $bin | measure-object).Count
	#	if( ($links | measure-object).count -gt 1){ echo $links }

		#Write-Host ($links | Format-Table -Force | Out-String)

	#	if(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent $links $OMEGA_EXT_BINARIES){
	#		echo "$bin ======================================================================> YES";
	#	}

		if( ($links | measure-object).count -gt 1){
			
			$OMEGA_EXT_BINARIES_fullpath = New-Object System.Collections.ArrayList
			foreach( $path in $OMEGA_EXT_BINARIES ){
				$OMEGA_EXT_BINARIES_fullpath.Add( (  Split-Path -noQualifier $bin ) )
			}
			echo "BASEDIR=$($env:BaseDir)"
			echo "==== fullpaths ===="
			Show-Path $OMEGA_EXT_BINARIES_fullpath
			echo "=== link ===="
			Show-Path $links
			#Split-Path -noQualifier

			echo "$bin is a HARDLINK";
			# remove if not in the array
			# see this for array intersect comparisons
			# http://stackoverflow.com/questions/8609204/union-and-intersection-in-powershell
			if( -not (Compare-Object -PassThru -IncludeEqual -ExcludeDifferent $links $OMEGA_EXT_BINARIES_fullpath)){
				echo "$bin is a hardlink and is NOT in an array... removing...."
				rm -Force $bin
			}
		}

	}
}

function install-bin-hardlinks {
	foreach ($bin in $OMEGA_EXT_BINARIES) {
		$bin =  Join-Path ( Join-Path $env:BaseDir system ) $bin 
		if (Test-Path -Path $bin){
			$binPath = Split-Path -Path $bin -Leaf -Resolve
			$binPath = Join-Path $OMEGA_BIN_PATH $binPath
			if (-not (Test-Path -Path $binPath)){
				echo "ADDING HARDLINK for $bin to $binPath"
				fsutil hardlink create $binPath $bin
			}
		} else {
			echo "!!ERROR!! the binary to be hardlinked ... $bin ... does not exist"
		}

	}
}


# For fsutil information
# see technet article
# https://technet.microsoft.com/en-ca/library/cc753059.aspx
# http://stackoverflow.com/questions/894430/powershell-hard-and-soft-links


#fsutil hardlink create NEW EXISTING
#fsutil hardlink create C:\cmder\bin\ssh.exe C:\cmder\system\openssh\ssh.exe

#fsutil hardlink list MyFileName.txt
#fsutil hardlink list C:\cmder\system\openssh\ssh.exe

# source - execute another script and maintain the variables within this environment
# http://ss64.com/ps/source.html
