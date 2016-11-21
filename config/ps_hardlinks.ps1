
<##################################
 ######### symlink logic ##########
 ##################################>


# cleanup the directory of items not specified
# logic:
# if it is a hardlink (not a local file // a file that only exists in `bin` holder)
# it will have more than one hardlink to it in `fsutil hardlink query`
# so check if it is in OMEGA_EXT_BINARIES array
# if not - delete it
function script:test-bin-hardlinks {
	
	Get-ChildItem $OMEGA_BIN_PATH |
	ForEach-Object {
		$bin = ( Join-Path $OMEGA_BIN_PATH $_.name ) 

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

			if(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent $links $OMEGA_EXT_BINARIES){
				echo "$bin ======================================================================> YES";
			}
		}
		######################################## END #######################################

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

function script:install-bin-hardlinks {
	foreach ($bin in $OMEGA_EXT_BINARIES) {
		$bin =  Join-Path ( Join-Path $env:BaseDir system ) $bin 
		if (Test-Path -Path $bin){
			$binPath = Split-Path -Path $bin -Leaf -Resolve
			$binPath = Join-Path $OMEGA_BIN_PATH $binPath
			if (-not (Test-Path -Path $binPath)){
				echo "ADDING HARDLINK for $bin to $binPath"
				#See help file
				#.LINK
				# cmd.fsutil
				fsutil hardlink create $binPath $bin
			}
		} else {
			echo "!!ERROR!! the binary to be hardlinked ... $bin ... does not exist"
		}
	}
}
