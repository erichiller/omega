# core functions here
# functions which have no dependencies
# these should get the module setup
# also provides core services for installation


<#
.Synopsis
Add given directories into $env:Path ( _THIS SESSION ONLY_ )
.Parameter dir
Must be the full VALID path. Do not add the ';' as that is done for you.
.Parameter SystemPath
Switch which triggers adding the path to the environment permanently. Requires admin permissions.
.LINK
Add-DirToPath
.LINK
Remove-Path
#>
function Add-DirToPath {
    param(
        [Parameter(Mandatory = $True)] [string] $dir,
        [switch] $SystemPath
    )
    # ensure the directory exists
    if (Test-Path -Path $dir ) {
        # if it isn't already in the PATH, add it
        if ( -not $env:Path.Contains($dir) ) {
            $env:Path += ";" + $dir
            return $True
        }
    }
    if ( $SystemPath) {
        Write-Debug "Updating SystemPath with 'Update-SystemPath $dir'"
        return Update-SystemPath $dir
    }
    return $False
}

<#
.Synopsis
Select matching directories from $env:Path and remove them from _THIS SESSION ONLY_
.PARAMETER DirectoryToRemove
Accepts partials %like
.LINK
Add-DirToPath
.LINK
Show-Path
#>
function Remove-DirFromPath {
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateScript( {Test-Path -Path $_ -PathType Container})]
        [String] $DirectoryToRemove
    )
    Write-Verbose "Found Directory to Remove $DirectoryToRemove"
    $savedPath = $env:Path
    Try {
        $newPath = ""
        ForEach ( $testDir in $(Show-Path -Objects) ) {

            if ( $testdir -like $DirectoryToRemove -and $(Enter-UserConfirm("Remove $testdir ?") === $false)) {
                Write-Warning "removing $testdir"
            }
            else {
                Write-Output "Re-adding $testdir"
                $newPath += "$testdir;"
            }
        }
            
        # remove trailing semi-colon
        $newPath = $newPath.TrimEnd(";")
        $env:Path = $newPath
    } Catch {
        Write-Error "Error During Path Parsing, Path will not be modified"
    } Finally {
        Write-Output "`n`nPath is now:`n$(Show-Path)"
        Write-Debug "RAW Path String --->`n$($env:Path)"
    }
}


<#
.DESCRIPTION
Adds the given directory to the system path
.PARAMETER directory
a string with the path to the directory to be added to the system path
#>
function Update-SystemPath {
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateScript( {Test-Path -Path $_ -PathType Container})]
        [String] $Directory
    )

    $conf = [OmegaConfig]::GetInstance()
    $user = [User]::GetInstance()

    $OriginalPath = (Get-ItemProperty -Path "$($conf.system_environment_key)" -Name PATH).Path
    Write-Debug "Checking Path at '$($conf.system_environment_key)' - currently set to `n$OriginalPath"
    $Path = $OriginalPath
    # Check to ensure that the Directory is not already on the System Path
    if ($Path | Select-String -SimpleMatch $Directory)
    { Write-Warning "$Directory already within System Path" }
    # Ensure the Directory is not already within the path
    if ($ENV:Path | Select-String -SimpleMatch $Directory)
    { Write-Warning "$Directory already within `$ENV:Path" }
    # Check that the directory is not already on the configured path
    if ( $user.SystemPathAdditions -Contains $Directory) {
        Debug-Variable $user.SystemPathAdditions "userState.SystemPathAdditions"; 
        Write-Warning "$Directory is already present in `$user.SystemPathAdditions"
        If ( -not (Enter-UserConfirm "force-add?") ){
            Return
        }
    }
	
    # MUST BE ADMIN to create in the default start menu location;
    # check, if not warn and exit
    if ( -not (Test-Admin -warn) ) { return }

    # Add the directory to $user.SystemPathAdditions
    SafeObjectArray $user "SystemPathAdditions" -Verbose
    Debug-Variable $user.SystemPathAdditions "`$user.SystemPathAdditions"
    Debug-Variable $Directory "`$Directory"
    $user.add_SystemPathAdditions($Directory)
    # Debug-Variable ArrayAddUnique -AddTo $user.SystemPathAdditions -AdditionalItem $Directory
    Write-Warning "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    Debug-Variable $user.SystemPathAdditions "userState.SystemPathAdditions"
    # Safe to proceed now, add the Directory to $Path
    $Path = "$Path;$(Resolve-Path $Directory)"
	
    # Cleanup the path
    # rebuild, directory by directory, deleting paths who are within omega's realm, and no longer exist or are permitted to be there (via user.SystemPathAdditions)
    $Dirs = $Path.split(";") | where-object {$_ -ne " "}

    ForEach ($testDir in $Dirs) {
        Write-Debug "Testing for validity within the system path:`t$testDir"
        # Test if $testDir is within BaseDir
        # If yes continue to test its validity within the system path.
        # If No, it is not in our jurisdiction/concern, proceed.
        if ( ($testDir -Like "$($conf.BaseDir)*") ) {
            Write-Debug "The $testDir is within $($conf.BaseDir) - continuing to test its validity within the system path."
            # test that path exists on the filesystem / is a valid path (and that it is a Container type (directory))
            # not found = not valid = continue
            if ( ! (Test-Path -Path $testDir -PathType Container) )
            { Write-Debug "$testDir is not a valid Path"; continue }
            # test if the SystemPathAdditions parameter is even configured, if not, then NO PATHS FROM OMEGA ARE VALID = continue
            if ( ! (Get-Member -InputObject $user -Name "SystemPathAdditions" -Membertype Properties))
            { Write-Debug "SystemPathAdditions is not a Property of `$userPath" ; continue }
            # test to see if $user.SystemPathAdditions contains $testDir, if it does not, then continue
            if ( $user.SystemPathAdditions -NotContains $testDir)
            { Write-Debug "$testDir not in `$user.SystemPathAdditions"; continue } 
        }
    }
    $Path = $Path -join ";" 
    # All Tests Passed, the trials are complete, you, noble directory, can be added (or kept) on the system's path
    Write-Debug "All validity tests have passed, '$Directory' is now on '$Path'"
    # Set the path
    # if( -not (& setx PATH /m $Path) ){ return $false }
    try {
        Set-ItemProperty -Path "$($conf.system_environment_key)" -Name PATH -Value $Path
    }
    catch {
        Write-Error "There was an issue updating the system registry."
        return $false
    }

    if ( -not $ENV:Path.Contains($testDir) ) {
        Write-Debug "$testDir is being added to the Environment Path as well as the System Path will only refresh for new windows"
        $ENV:Path += ";" + $testDir
    }

    Show-Path -Debug
    return $true
}

function Update-SystemEnvironmentVariables {
    param(
        [string] $Name,
        [string] $Value
    )
	
    $Path = ([OmegaConfig]::GetInstance()).system_environment_key

    Write-Debug "Updating key name '$Name' at '$Path' with value '$Value'"

    try {
        Set-ItemProperty -Path "$Path" -Name $Name -Value $Value
        return $true
    }
    catch {
        Write-Error "There was an issue updating the system registry."
        return $false
    }
}


function SafeObjectArray {
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [PSCustomObject] $object,

        [Parameter(Mandatory = $True, Position = 2)]
        [string] $pN
    )

    # debug
    if ( $VerbosePreference ) {
        Write-Verbose "object---"
        $object | Get-Member | Format-Table
        Write-Verbose "propertyName---"
        $pN | Get-Member | Format-Table
        Write-Verbose "property--"
        Write-Output "len is $($object.$pN.length)"
        if ( $object.$pN -eq $null ) { 
            Write-Output "is null"
            $object.$pN = @()
        }
        Write-Verbose "end---"
    }
	
    if (!(Get-Member -InputObject $object -Name $pN -Membertype Properties)) {
        Add-Member -InputObject $object -MemberType NoteProperty -Name $pN -Value $ArrayList

        #debug
        if ( $VerbosePreference ) { 
            Write-Verbose "$pN not present on $object"
            $object | Get-Member | Format-Table
        }
        $object.$pN = @()
    }
}

function ArrayAddUnique {
    param(
        [Parameter(Mandatory = $True, Position = 1)]
        [AllowEmptyCollection()]
        [Object[]] $AddTo,

        [Parameter(Mandatory = $True, Position = 2)]
        [String] $AdditionalItem
    )
    if ( $AddTo -notcontains $AdditionalItem) {
        $AddTo += $AdditionalItem
    }
    Write-Verbose "returning ArrayAddUnique"	
    Debug-Variable $AddTo "ArrayAddUnique()'s return value of `$AddTo"
    return $AddTo

	
}

<#
.SYNOPSIS
Register a command as available for user use. Also register it's help in an easy to access table.
.LINK
Omega-CommandsAvailable
#>

function Set-RegisterCommandAvailable ($command) {
    if ( $command -eq $null ) {
        # if no command was sent, use the caller
        # powershell stack - get caller function
        $command = $((Get-PSCallStack)[1].Command)
    }
    # put the name and synopsis into the table
    ([User]::GetInstance()).RegisteredCommands += (Get-Help $command | Select-Object Name, Synopsis)
}


function Join-Paths {
    param(
        [parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Paths
    )
    Debug-Variable $Paths "Join-Paths received `$Paths"
    if ($Paths.Length -le 0 ) {
        Write-Warning "$Paths had a length of $($Paths.Length)"
        return $False
    }
    for ( $i = 1; $i -lt $Paths.Length ; $i++) {
        Write-Verbose "Joining $($Paths[0]) to $($Paths[$i])"
        $Paths[0] = Join-Path $Paths[0] $Paths[$i]
    }
    Write-Verbose "Returning $($Paths[0])"	
    return $Paths[0]
}