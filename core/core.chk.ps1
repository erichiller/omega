<#
Keep internal checks and Debugs here
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

<#
.DESCRIPTION
Print Variable value to debug
Adapted from (see link)
.Parameter var
The variable to debug, values and type to display
.PARAMETER name
<optional> The name of the variable being displayed
.Link
http://stackoverflow.com/questions/35624787/powershell-whats-the-best-way-to-display-variable-contents-via-write-debug
#>
function Debug-Variable { 
	param(
		[Parameter(Mandatory = $True)] 
			[AllowEmptyString()]
			[AllowNull()] $var,
		[string] $name
	)
	if ( -not $var ){
		Write-Information "var cannot be displayed it is null"
		return
	}
    if (!(Get-Member -InputObject $var -Name "Length" -Membertype Properties)) { $length = "length: $($var.Length)`n" } else { $length = "" }
	@(
		if ([string]::IsNullOrEmpty($name) -ne $true) { $name = "`nName: ``$name``" }
        "<<<<<<<<<<<<<<<<<<<< START-VARIABLE-DEBUG >>>>>>>>>>>>>>>>>>>>$name`nType:$($var.getType())`n$length(VALUES FOLLOW)`n$( $var | Format-List | Format-Table -AutoSize -Wrap | Out-String )" 
	) | Write-Debug
    Write-Debug "<<<<<<<<<<<<<<<<<<<< END-VARIABLE-DEBUG >>>>>>>>>>>>>>>>>>>>"
}

function Debug-Title {
	param(
		[Parameter(Mandatory = $False)] [System.ConsoleColor] $ForegroundColor = $host.PrivateData.DebugBackgroundColor,
		[Parameter(Mandatory = $False)] [System.ConsoleColor] $BackgroundColor = $host.PrivateData.DebugForegroundColor,
		[Parameter(Mandatory = $True, Position=1)] $Print
	)
	if ( $DebugPreference -ne "SilentlyContinue" ){
		if ($Print.getType() -eq [String] ) {
			$Print = $Print.PadLeft($Print.length+20," ").PadRight($Print.length+40," ")
		}
		Write-Host $Print -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
	}
}


<#
.SYNOPSIS
Returns true if the current session is an administrative priveleged one
#>
function Test-Admin {
	Param(
		[Switch] $warn=$false
	)
	If ( -not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
		if($warn){
			Write-Warning "You must be an administrator in order to continue.`nPlease try again as administrator."
		}
		return $false
	}
	return $true
}