<################################################
 ###### OMEGA - init script for PowerShell ######
 ################################################
 **** Setting up the PowerShell environment *****
 ############### Eric D Hiller ##################
 ############## October 18 2016 #################
#################################################>

# Compatibility with PS major versions <= 2
if(!$PSScriptRoot) {
	$PSScriptRoot = Split-Path $Script:MyInvocation.MyCommand.Path
}

# load the configuration variables
. $PSScriptRoot\ps_config.ps1
# load the functions first
. $PSScriptRoot\ps_functions.ps1

test-bin-hardlinks
install-bin-hardlinks

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
	Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart conemu."
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


###########################################################################################################################################
###########################################################################################################################################
###########################################################################################################################################



#################################################
######            STEP #3: ALIASES          #####
#################################################

Set-Alias -Name sudo -Value $env:BaseDir\winsudo.ps1 -PassThru