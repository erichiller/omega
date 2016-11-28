<################################################
####### OMEGA - init script for PowerShell ######
#################################################
***** Setting up the PowerShell environment *****
################ Eric D Hiller ##################
############### October 18 2016 #################
#################################################>


# Compatibility with PS major versions <= 2
if(!$PSScriptRoot) {
	$PSScriptRoot = Split-Path $Script:MyInvocation.MyCommand.Path
}

# set THIS as the PROFILE for the user
$PROFILE = $script:MyInvocation.MyCommand.Path;

# load config from json into object
$OMEGA_CONF = ( Get-Content (Join-Path $PSScriptRoot "\config.json" ) | ConvertFrom-Json )

<#
# PowerShell defaults $VerbosePreference to "SilentlyContinue" which will not display verbose messages
# Set this to continue to display verbose messages where available
# See $OMEGA_CONF.verbosity for these configurations
#>
$VerbosePreference			= $OMEGA_CONF.verbosity.verbose
$InformationPreference		= $OMEGA_CONF.verbosity.information
$DebugPreference			= $OMEGA_CONF.verbosity.debug

# Binary files
# array of external binaries to be added to the `bin/` folder via hardlink
# remove them and they will be unlinked
# MUST BEGIN WITH \
# Resolve-Path may be useful in the future here
# (Resolve-Path ../bin).Path
# https://technet.microsoft.com/en-us/library/hh849858.aspx
# http://ss64.com/ps/common.html
$env:BaseDir = Resolve-Path ( Join-Path ( Split-Path $Script:MyInvocation.MyCommand.Path ) ".." )













<#
$extBinaries = @(
	# openssh https://github.com/PowerShell/Win32-OpenSSH/releases/
	"\system\openssh\ssh.exe"
#	,"\system\openssh\sshd.exe"
#	,"\system\openssh\sshd_config"
	,"\system\openssh\ssh-add.exe"
	,"\system\openssh\ssh-agent.exe"
	,"\system\openssh\ssh-keygen.exe"
#	,"\system\openssh\ssh-lsa.dll"
#	,"\system\openssh\ssh-shellhost.exe"
	,"\system\openssh\sftp.exe"
#	,"\system\openssh\sftp-server.exe"
#	,"\system\openssh\ntrights.exe"
#	,"\system\openssh\install-sshd.ps1"
#	,"\system\openssh\install-sshlsa.ps1"
#	,"\system\openssh\uninstall-sshd.ps1"
#	,"\system\openssh\uninstall-sshlsa.ps1"
#	,"\system\GetGnuWin32\gnuwin32\bin\l2s.exe"
	)
	#>
# see arrays here
# http://ss64.com/ps/syntax-arrays.html
# hash tables also look very useful
# http://ss64.com/ps/syntax-hash-tables.html


$OMEGA_EXT_BINARIES = @(
#	"OpenSSH-Win64\ssh.exe"
	)











# load the functions first
. $PSScriptRoot\ps_functions.ps1

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
# For information on Git display variables, see:
# $env:ConEmuDir\system\psmodules\posh-git\GitPrompt.ps1
# posh-git change name of tab // remove annoying
$GitPromptSettings.EnableWindowTitle = "git:"


try {
	Import-Module oh-my-posh
	$global:ThemeSettings.MyThemesLocation = "$env:BaseDir\config\"
	Set-Theme omega
} catch {
	Write-Warning "oh-my-posh module failed to load. Either not installed or there was an error."
}

try {
	Import-Module PSSudo
} catch {
	Write-Warning "PSSudo module failed to load. Either not installed or there was an error."
}

try {
	Import-Module PSColor -ErrorAction Stop >$null
} catch {
	Write-Warning "PSColor module failed to load. Either not installed or there was an error. Directory and console coloring will be limited."
}

try {
	Import-Module PoShKeePass -Force -ErrorAction Stop >$null
} catch {
	Write-Warning "PoShKeePass module failed to load. Either not installed or there was an error. Password commands and access will be unavailable."
}

##  PSGnuwin32 ??


###########################################################################################################################################
###########################################################################################################################################
###########################################################################################################################################



#################################################
######            STEP #3: ALIASES          #####
#################################################

Set-Alias -Name "powershell" -Value "${env:SystemRoot}\system32\WindowsPowerShell\v1.0\powershell.exe" -Force

Set-Alias -Name "Print-Path" -Value Print-Path


New-Alias -Name "7z" -Value "${env:ProgramFiles}\7-zip\7z.exe"