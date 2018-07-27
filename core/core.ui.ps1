

<#
.SYNOPSIS
Display version and usage information
.Link
See also Get-OmegaCommands
#>
function Get-OmegaHelp {
	### change this to user help system!!!
	### md -> manpages /// xml help?


	Write-Host -ForegroundColor Cyan "PowerShell Version" $PSVersionTable.PSVersion
	Write-Host -ForegroundColor Cyan "Windows Version" $PSVersionTable.BuildVersion
	Write-Host -ForegroundColor Magenta "See More with `$PSVersionTable"
	$conf = [OmegaConfig]::GetInstance()

	Write-Host -ForegroundColor DarkGray ( Get-Content ( ( Join-Path $conf.BaseDir $conf.helpdir | Join-Path -ChildPath "user" | Join-Path -ChildPath "omega.install.md" ) ) )

	Get-Content ( ( Join-Path $conf.BaseDir $conf.helpdir | Join-Path -ChildPath "user" | Join-Path -ChildPath "ps.cmdline_tips.md" ) )
	Get-Content -encoding UTF8 ( ( Join-Path $conf.BaseDir $conf.helpdir | Join-Path -ChildPath "user" | Join-Path -ChildPath "keys.conemu.md" ) )
}


<#
.Description
Read y/n from user to confirm _something_
Returns $true / $false
.Parameter dialog
Optional dialog text before [y|n] to propmt user for input
Else default will be displayed.
#>
function Enter-UserConfirm {
	param (
		[string] $dialog = "Do you want to continue?"
	)
	$choice = $false
	while ($choice -notmatch "[y|n]") {
		Write-Host -NoNewline -ForegroundColor Cyan "$dialog (Y/N)"
		$choice = Read-Host " "
	}
	if ( $choice.ToLower() -eq "y") {
		return $true
	}
	return $false
}


<#
.SYNOPSIS
Written primarily for setting the tab title in ConEmu.
.EXAMPLE
See omega.psm1 for usage
#>
function Get-PrettyPath {
	param (
    [System.Management.Automation.PathInfo] $dir,
	[switch] $prependBase = $False
	)
	#### IT IS GIVING ME A STRING!!!!!
	if( -not $dir ){ $dir = Get-Location }
	if( -not ( $dir | Get-Member -Name "Provider" ) ){
		throw
		return "?!?"
		# somehow this does not have a Provider?
	}
	$provider = $dir.Provider.Name
	if($provider -eq 'FileSystem'){
        # if it is home, stop all further processing, don't waste time
        if ($dir.path -eq $HOME) {
            return '~'
        }
		$result = @()
        $currentDir = Get-Item $dir.path
        if ( $prependBase -eq $True ){
            # the first is a blank `/` root ; so subtract 1
            $pathSegmentsLength = (new-object System.Uri(Convert-Path .)).Segments.Length - 1
            if( $dir.Drive ) {
                $base = $dir.Drive.Name + ":"
                # Display the UNC (smb) host if it is one
            } else {
                $base = (new-object System.Uri(Convert-Path .))
                if( $base.IsUnc ){
                    $base = "\\" + $base.Host
                } else {
                    $base = $base.Host
                }
            }
        }
		while( ($currentDir.Parent) -And ($result.Count -lt 2 ) -And ($currentDir -ne $base ) ){
			$result = ,$currentDir.Name + $result
			$currentDir = $currentDir.Parent
        }
        if ( $prependBase -ne $True ){
            return $result -join $ThemeSettings.PromptSymbols.PathSeparator
        }
        if ( $pathSegmentsLength -gt $result.Length ){
            # create an indicator for the number of path segments skipped
            $base = $base + "(" + ($pathSegmentsLength - $result.Length) + ")"
        }
		return (,$base + $result) -join $ThemeSettings.PromptSymbols.PathSeparator
    # for NETWORK SHARES, could also use:
    # new-object System.Uri(Convert-Path .).Host
    #
	} else {
		return $dir.path.Replace((Get-Drive -dir $dir), '')
	}
}

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
		[Switch] $delete,
		[Parameter(Mandatory = $false)]
		[Switch] $outputDebug
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
	$regex = "^[[:blank:]]*cd ([a-zA-Z\.\~:]+([$dirSep][^$dirSep]+)*[$dirSep]([^$dirSep]+)[$dirSep]?)$"
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
				$lowestDirectory = $matches[($matches.keys | Sort-Object -Descending | Select-Object -First 1)]
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
		function Set-LocationHelper {
			param(
				[Parameter(Mandatory=$True)]
				[string] $dir,
				[switch] $delete,
				[switch] $addToHistory
			)
			# Add to history so that in the future this directory will be found with `cd` scanning and brute force WILL NOT BE REQUIRED
			if ($addToHistory){
				[Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory("cd $dir")
			}
			if ( $delete ){
				Clear-History -CommandLine $filteredDirs -Confirm
			} else {
				Set-Location $dir
			}
		}
	}
	process {
		# I only want to see Debug messages when I specify the DEBUG flag
		if ($PSCmdlet.MyInvocation.BoundParameters["debug"].IsPresent) {
			$LOCAL:DebugPreference = "Continue"
		} else {
			$LOCAL:DebugPreference = "SilentlyContinue"
		}


		# comes out as an array, but only one is possible, so grab that
		$dirSearch = $PsBoundParameters.dirSearch[0]

		Debug-Variable $searchHistory "f/searchHistory"

		Write-Debug "dirSearch=$dirSearch"

		#this is doing ___EQUAL___ /// or do I want to be doing a like dirSearch*
		$filteredDirs = $searchHistory.GetEnumerator() | ?{ $_.Value -eq $dirSearch }

		# if there is a single match
		if ( $filteredDirs.count -eq 1 ){
			$testedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($filteredDirs.name)
			if( $testedPath | Test-Path ){
				Set-LocationHelper $testedPath
			}
		} else {
			# there are multiple matches
			# do a lookup for number of times it was cd'd into with the searchCount
			#### searchCount ####
			## NAME ===> VALUE ##
			## (DIR) ==> COUNT ##
			Debug-Variable $searchCount

			"More than one matching entry was found, now sorting and checking each historical cd"
			$searchCount.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
				$countedDir = $_
				$highestDir = ( $filteredDirs.GetEnumerator() | ?{$_.Name -contains $countedDir.Name} )
				if ( $highestDir.count -eq 1 ){
					Write-Debug "Check for $($highestDir.name)"
					$testedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($highestDir.name)
					if( $testedPath | Test-Path ){
						Set-LocationHelper $testedPath
						break
					} else {
						Write-Warning "Tried to cd to $($highestDir.name) (resolved to $testedPath), but it does not exist"
					}
				} else {
					$highestDir.name
				}
			}
		}

		# if a match was found above; but it did not immeditately resolve
		if( ( $testedPath ) `
				-and ( -not ( $testedPath | Test-Path ) ) ){
			Write-Information "Could not find test string '$dirSearch', possibly not an absolute path, Attempting to Locate"
			# iterate history where the directory that was being searched for is PART of one of the historical items
			# for example; if searching for dirB. This would find it in /dirA/dirB/dirC/ and return /dirA/dirB/
			## <START LOOP>
			$searchCount.GetEnumerator() | Sort-Object -Property Value -Descending | Where-Object { $_.Name -like "*$dirSearch*" } | ForEach-Object -ErrorAction SilentlyContinue {
				$testedPath = $_.Name
					Write-Debug "Command like dirsearch:$testedPath" -ErrorAction SilentlyContinue
				$testedPath = Join-Path $testedPath.Substring( 0 , $testedPath.IndexOf($dirSearch) ) $dirSearch
				if ( Test-Path $testedPath ){
					Set-LocationHelper $testedPath
					break
				}
			}
			## <END LOOP>

			#### Brute force search directories ####
			# if we reached this point, none of the above worked, it is time to just brute force search,
			# Not found within the path of another match, so just scan every single directory. Maybe slow, but it should work
			Write-Debug "We are now going to brute force search, all other methods have failed"
			$dirsToScan = @(".", $env:HOME, $env:APPDATA)
			foreach ($dir in $dirsToScan ) {
				Write-Debug "Scanning: $dir"
				Get-Childitem -path $dir -recurse -directory -filter "$dirSearch" -ErrorAction SilentlyContinue | ForEach-Object {
					$testedPath = $_.FullName
					if (Enter-UserConfirm -dialog "Confirm: Change Directory to $testedPath") {
						Set-LocationHelper $testedPath -addToHistory
						break
					}
				}
			}
		}
	} <# End process {} #>

}


