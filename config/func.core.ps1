# core functions here
# functions which have no dependencies
# these should get the module setup
# also provides core services for installation

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
		return $true
	}
	return $false
}