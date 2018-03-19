
$PSScriptRoot = "$(pwd)\core"

$host.UI.RawUI.BackgroundColor = 'DarkGreen'
Clear-Host
set-psdebug -strict
$VerbosePreference="continue"
$DebugPreference="continue"
$InformationPreference="continue"
. $PSScriptRoot\core.ps1
. $PSScriptRoot\core.chk.ps1
. $PSScriptRoot\objects.ps1
. $PSScriptRoot\user.ps1
. $PSScriptRoot\user.omega.ps1
. $PSScriptRoot\package.install.ps1
Write-Debug "PSScriptRoot: $PSScriptRoot"
Write-Verbose "this is *verbose*"
# $host.PrivateData.DebugForegroundColor = [ConsoleColor]::Cyan
# $host.PrivateData.WarningForegroundColor = [ConsoleColor]::Magenta


<#
### DEBUG HERE ###
#>

# Install-PackageFromGitRelease "git"

# Write-Output ( [User]::new("eric","foo") | ConvertTo-Json)
# Write-Output ( [User] ( ( [User]::new("eric","foo") | ConvertTo-Json) | ConvertFrom-Json ) )
# return
[Package]::instance = $null
[User]::instance = $null
[OmegaConfig]::instance = $null

echo '----instance----- of OmegaConfig'
[OmegaConfig]::GetInstance()
echo '----ENDinstance----- of OmegaConfig'
[OmegaConfig]::GetInstance()
echo '----ENDinstance----- of OmegaConfig'

$c = [OmegaConfig]::GetInstance()
if ( $c.bindir -eq "\bin" ) {
    Write-Host -ForegroundColor "Black" -BackgroundColor "Green" "**** SUCCESS , OMEGACONFIG READ PROPERLY ****"
}
else {
    Write-Host -ForegroundColor "Black" -BackgroundColor "Red" "**** FAIL , OMEGACONFIG FAILURE ****"
}

Write-Information "*********************************************************************"

echo "one"
Write-Information [User]::UserStateFilePath


echo "two"
Write-Information ([User]::UserStateFilePath)
$u = [User]::GetInstance()

$u

if ( $u.GitUser -eq "a" ) {
    Write-Host -ForegroundColor "Black" -BackgroundColor "Green" "**** SUCCESS , USER STATE READ PROPERLY ****"
}
else {
    Write-Host -ForegroundColor "Black" -BackgroundColor "Red" "**** FAIL , USER STATE FAILURE ****"
}
# $u | Format-List
# $u.gettype()
# $u | get-member
# $u.Packages.git | get-member

# Write-Information "*********************************************************************"
 
$u.Packages.git | Format-List


([User]::GetInstance()).Verbosity




# [Package]$pkg = [Package]::new("git")





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


