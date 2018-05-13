
$PSScriptRoot = Join-Path $env:APPDATA "omega\core"

$host.UI.RawUI.BackgroundColor = 'Black'
Clear-Host
Set-PSReadlineOption -ResetTokenColors
set-psdebug -strict
$VerbosePreference="continue"
$DebugPreference="continue"
$InformationPreference="continue"
. $PSScriptRoot\core.ps1
. $PSScriptRoot\core.chk.ps1
. $PSScriptRoot\core.ui.ps1
. $PSScriptRoot\objects.ps1
. $PSScriptRoot\user.omega.ps1
. $PSScriptRoot\package.install.ps1
Write-Debug "PSScriptRoot: $PSScriptRoot"
Write-Verbose "this is *verbose*"
# $host.PrivateData.DebugForegroundColor = [ConsoleColor]::Cyan
# $host.PrivateData.WarningForegroundColor = [ConsoleColor]::Magenta


<#
### DEBUG HERE ###
#>


# [PackageState] $pst = [PackageState](
# @"
# {
#     "name": "git",
#     "version" : "2"
# }
# "@ | ConvertFrom-Json)

# [PackageState] $pst = [PackageState]::new("git",2)


# $pst | Get-Member

# $pst.System.PathAdditions | Format-List | Out-String | Write-Host -ForegroundColor "Magenta"

Install-PackageFromGitRelease "git"

# [Package]$pkg = [Package]::GetInstance("git")

# $pkg.System.SystemEnvironmentVariables | Out-String | Write-Host -ForegroundColor "Green"
# $pkg.System | Out-String | Write-Host -ForegroundColor "Green"
# $pkg | Out-String | Write-Host -ForegroundColor "Magenta"




Remove-Variable * -ErrorAction SilentlyContinue;
# Remove-Module *;
$error.Clear();
# Clear-Host



# $x = [UserState]::new("aStringValue") 
# $x.Name
# # $x.JumbleName() 
# $x.Packages = @( 1 , 2)

# $x | ConvertTo-Json

# $Package = Test-InstallPrerequisite "git"

# Debug-Variable $Package "Package"

# Write-Debug "Name: $($Package.Name) name:$($Package.name)"

# $user = [User]::GetInstance()

# $user | get-member -Force

# # mark as installed in the manifest
# $packageState = [PackageState]::new( $Package.Name, "a" )
# # $user.foo()
# $user.setPackageState($packageState)
# # $user.Packages[$Package.Name] 		= $packageState

# Add-DirToPath "C:\users\ehiller\AppData\Local\omega\system\git\cmd" -System

# # $user.Packages.Package.name			= $Package.name
# # $user.Packages.Package.updateDate	= 
# # $user.Packages.Package.version		= $version
# $user.SaveState()


