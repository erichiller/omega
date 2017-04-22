<################################################
####### OMEGA - init script for PowerShell ######
#################################################
***** Setting up the PowerShell environment *****
################ Eric D Hiller ##################
############### October 18 2016 #################
#################################################>


# set THIS as the PROFILE for the user
$PROFILE = $script:MyInvocation.MyCommand.Path;

# Compatibility with PS major versions <= 2
if(!$PSScriptRoot) {
	$PSScriptRoot = Split-Path $Script:MyInvocation.MyCommand.Path
}

# Set basedir for omega
$env:BaseDir = Resolve-Path ( Join-Path ( Split-Path $Script:MyInvocation.MyCommand.Path ) ".." )

# load the functions first
. $PSScriptRoot\ps_functions.ps1

# load config from json into object
Update-Config

<#
# PowerShell defaults $VerbosePreference to "SilentlyContinue" which will not display verbose messages
# Set this to continue to display verbose messages where available
# See $OMEGA_CONF.verbosity for these configurations
#>
$VerbosePreference			= $OMEGA_CONF.verbosity.verbose
$InformationPreference		= $OMEGA_CONF.verbosity.information
$DebugPreference			= $OMEGA_CONF.verbosity.debug


#################################################
###### STEP #1: ADD DIRECTORIES TO THE PATH #####
#################################################

# location of singular binaries for Omega
$local:BinDir = (Join-Path $env:BaseDir "\bin")
# Add local bin dir (for single file executable or user-runnable scripts)
# ensure it isn't already added, as in the case of root tab copy
Add-DirToPath($local:BinDir)

$local:ModulePath = Join-Path $env:BaseDir "\system\psmodules"
# Add local modules directory to the autoload path.
if( -not $env:PSModulePath.Contains($local:ModulePath) ){
	$env:PSModulePath = $env:PSModulePath.Insert(0, $local:ModulePath + ";")
}
# load local psmodules
$global:UserModuleBasePath = $local:ModulePath


#################################################
######        STEP #2: IMPORT MODULES       #####
#################################################

try {
	# test for git
	Import-Module -Name "posh-git" -ErrorAction Stop >$null
	# set status as true
	$gitStatus = $true
	# if git is loaded, this means ssh is most likely available, lets check for KeeAgent's socket too and set if present
	if ( Test-Path ( Join-Path $env:TEMP "KeeAgent.sock" ) ) { $env:SSH_AUTH_SOCK = Join-Path $env:TEMP "KeeAgent.sock" }
	# For information on Git display variables, see:
	# $env:ConEmuDir\system\psmodules\posh-git\GitPrompt.ps1
	# posh-git change name of tab // remove annoying
	$GitPromptSettings.EnableWindowTitle = "git:"
} catch {
	Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart terminal (ConEmu,Omega)."
	$gitStatus = $false
}

# load GitStatusCachePoshClient
# see: https://github.com/cmarcusreid/git-status-cache-posh-client
try {
	Import-Module -Name "GitStatusCachePoshClient" -ErrorAction Stop >$null
} catch {
	Write-Warning "The GitStatusCachePoshClient module could not be found & imported, large directories may take significantly longer without it."
}

try {
	Import-Module oh-my-posh -ErrorAction Stop >$null
	$global:ThemeSettings.MyThemesLocation = "$env:BaseDir\config\"
	Set-Theme omega
} catch {
	Write-Warning "oh-my-posh module failed to load. Either not installed or there was an error. Modules styling will not be present."
}

try {
	Import-Module PSSudo -ErrorAction Stop >$null
} catch {
	Write-Warning "PSSudo module failed to load. Either not installed or there was an error."
}

try {
	Import-Module PSColor -ErrorAction Stop >$null
} catch {
	Write-Warning "PSColor module failed to load. Either not installed or there was an error. Directory and console coloring will be limited."
}

try {
	# https://github.com/samneirinck/posh-docker
	if(Get-Module posh-docker){ Import-Module posh-docker }
} catch {
	Write-Warning "Posh-Docker module failed to load. Either not installed or there was an error. Docker autocomplete commands will not function."
	Write-Warning "It can be installed in an admin console with:"
	Write-Warning "Install-Module -Scope CurrentUser posh-docker -Force"
}

# go is going to have to be a module too
try {
	$env:GOPATH = Resolve-Path $OMEGA_CONF.gopath
	if( ( Test-Path $env:GOPATH ) `
		-and ( Test-Path ( Join-Path $env:GOPATH "bin" ) ) `
		-and ( Test-Path ( Join-Path $env:GOPATH "pkg" ) ) `
		-and ( Test-Path ( Join-Path $env:GOPATH "src" ) ) `
	){
		Add-DirToPath ( Join-Path $env:GOPATH "bin" )
	} else {
		# if GOROOT wasn't found, remove the environment variable;
		# this keeps the environment clean of garbage
		Write-Warning "${$env:GOPATH} (GOPATH) is not present"
		Remove-Item Env:\GOPATH
	}
	$env:GOROOT = Join-Path $env:BaseDir "\system\go\"
	if( ( Test-Path $env:GOROOT ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "bin" ) ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "pkg" ) ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "src" ) ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "misc" ) ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "lib" ) ) `
	){
		Add-DirToPath ( Join-Path $env:GOROOT "bin" )
	} else {
		# if GOROOT wasn't found, remove the environment variable;
		# this keeps the environment clean of garbage
		Write-Warning "${$env:GOROOT} (GOROOT) is not present"
		Remove-Item Env:\GOROOT
	}

	# get msys2 , msys64 here: https://sourceforge.net/projects/msys2/files/Base/x86_64/
	$unixesq = Join-Path $env:BaseDir $OMEGA_CONF.unixesq
	if( ( Test-Path $unixesq ) `
		-and ( Test-Path ( Join-Path $unixesq "mingw64\bin" ) ) `
		-and ( Test-Path ( Join-Path $unixesq "mingw64\bin\gcc.exe" ) ) `
	){

	}
} catch {
	Write-Warning "GO not found. Either not installed or there was an error. Directory and console coloring will be limited."
}

# Set config for ViM
if ( Test-Path $env:BaseDir/system/vim/vim.exe ) {
	$env:VIMINIT='source $VIM/../../config/omega.vimrc'
	Set-Alias -Name "vim" -Value "${env:BaseDir}\system\vim\vim.exe"
}


##  PSGnuwin32 ??

## check for psreadline 1.2 with get-module psreadline
## else install with ``` powershell -noprofile -command "Install-Module PSReadline -Force" ```


###########################################################################################################################################
###########################################################################################################################################
###########################################################################################################################################



#################################################
######            STEP #3: ALIASES          #####
#################################################

Set-Alias -Name "powershell" -Value "${env:SystemRoot}\system32\WindowsPowerShell\v1.0\powershell.exe" -Force

Set-Alias -Name "Print-Path" -Value Show-Path

Set-Alias -Name "7z" -Value "${env:ProgramFiles}\7-zip\7z.exe"

# where whereis which
# probably a bad idea to reset where, it breaks a decent number of things.
#Set-Alias -Name where -Value "${env:windir}\System32\where.exe" -Force -Option AllScope
Set-Alias -Name "whereis" -Value "${env:windir}\System32\where.exe"
Set-Alias -Name "which" -Value "${env:windir}\System32\where.exe"

# new mv
if (alias mv -ErrorAction SilentlyContinue) { Remove-Item alias:mv }

# Ultimately this should be its own usr file
function gh { Set-Location "${env:Home}\Dev\src\github.com\erichiller\$($args[0])" }
function om { Set-Location ${env:Basedir} }

# less
Set-Alias -Name "less" -Value "${env:basedir}\system\git\usr\bin\less.exe"

# grep
Set-Alias -Name grep -Value "${env:basedir}\system\git\usr\bin\grep.exe"

# sed
Set-Alias -Name sed -Value "${env:basedir}\system\git\usr\bin\sed.exe"
