try { . ([ScriptBlock]::Create("using module '$($MyInvocation.MyCommand.ScriptBlock.Module.ModuleBase)\objects.ps1'")); } catch { Write-Verbose $_ }

<#
####### OMEGA - init script for PowerShell ######
#################################################
***** Setting up the PowerShell environment *****
################ Eric D Hiller ##################
################ March 18 2018 ##################
################################################
#>

<#
# PowerShell defaults $VerbosePreference to "SilentlyContinue" which will not display verbose messages
# Set this to continue to display verbose messages where available
# See $config.verbosity for these configurations
#>
$User = [User]::GetInstance()
$Config = [OmegaConfig]::GetInstance()
$VerbosePreference = $User.verbosity.verbose
$InformationPreference = $User.verbosity.information
$DebugPreference = $User.verbosity.debug


#################################################
###### STEP #1: ADD DIRECTORIES TO THE PATH #####
#################################################

# Add local bin dir (for single file executable or user-runnable scripts)
# ensure it isn't already added, as in the case of root tab copy
Add-DirToPath($Config.bindir)

$local:ModulePath = Join-Path $Config.BaseDir "\system\psmodules"
if ( Test-Path $local:ModulePath ) {
	# Add local modules directory to the autoload path.
	if ( -not $env:PSModulePath.Contains($local:ModulePath) ) {
		$env:PSModulePath = $env:PSModulePath.Insert(0, $local:ModulePath + ";")
	}
	# load local psmodules
	$global:UserModuleBasePath = $local:ModulePath
}


#################################################
######        STEP #2: IMPORT MODULES       #####
######        -----> mandatory <-----       #####
#################################################
try {
	# test for git
	$script:DebugPreference_prior = $DebugPreference
    $DebugPreference = "SilentlyContinue"
    if ( Get-Module "posh-git" ){
        Write-Verbose "module 'posh-git' already loaded, skipping forced load"
    } else {
        Import-Module -Name "posh-git" -ErrorAction Stop >$null
    }
	$DebugPreference = $script:DebugPreference_prior
	# set status as true
	$gitStatus = $true
	# if git is loaded, this means ssh is most likely available, lets check for KeeAgent's socket too and set if present
	# **NOTE** This must be configured as a CYGWIN compatible socket in KeeAgent
	if ( Test-Path ( Join-Path $env:TEMP "KeeAgent.sock" ) ) { $env:SSH_AUTH_SOCK = Join-Path $env:TEMP "KeeAgent.sock" }
	else { Write-Verbose "KeeAgent.sock was not found in ${env:TEMP}, it will not be used as ssh-agent" }
	# For information on Git display variables, see:
	# $env:ConEmuDir\system\psmodules\posh-git\GitPrompt.ps1
	# posh-git change name of tab // remove annoying
	$GitPromptSettings.EnableWindowTitle = "git:"
	# set git's pager to Windows' native `more` ; because git's `less` is unstable on Windows in ConEmu
	$env:GIT_PAGER = "'less' -c -d"
} catch {
	Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart terminal (ConEmu,Omega)."
	$gitStatus = $false
}

# 0.6 sec
# load GitStatusCachePoshClient
# see: https://github.com/cmarcusreid/git-status-cache-posh-client
try {
	Import-Module -Name "GitStatusCachePoshClient" -ErrorAction Stop >$null
} catch {
	Write-Warning "The GitStatusCachePoshClient module could not be found & imported, large directories may take significantly longer without it."
}

# 4.2 sec
try {
    if ( Get-Module "oh-my-posh" ){
        Write-Verbose "module 'oh-my-posh' already loaded, skipping forced load"
    } else {
        Import-Module oh-my-posh -ErrorAction Stop >$null
    }
	$global:ThemeSettings.MyThemesLocation = "$($config.basedir)\core\"
    Set-Theme themeOmega
} catch {
	Write-Warning "oh-my-posh module failed to load. Either not installed or there was an error. Modules styling will not be present."
}

# 4.4 sec
try {
    if ( Get-Module "PSColor" ){
        Write-Verbose "module 'PSColor' already loaded, skipping forced load"
    } else {
        Import-Module PSColor -ErrorAction Stop >$null
    }
} catch {
	Write-Warning "PSColor module failed to load. Either not installed or there was an error. Directory and console coloring will be limited."
}


#################################################
######       continued IMPORT MODULES       #####
######       ------> optional <------       #####
######        do not error for these        #####
#################################################

# can install
# - GO
# - posh-docker
# - vim
# - pssudo

# Set config for ViM
if ( Test-Path ( Join-Path $config.basedir "/system/vim/vim.exe" ) ) {
	$env:GIT_EDITOR = Convert-DirectoryStringtoUnix (Join-Path $config.basedir "/system/vim/vim.exe" )
	$env:VIMINIT = 'source $VIM/../../core/config/omega.vimrc'
	Set-Alias -Name "vim" -Value "$($config.basedir)\system\vim\vim.exe"
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
Set-Alias -Name "which" -Value "${env:windir}\System32\where.exe"
<#
.SYNOPSIS
Search-Executable is a replacement and expansion of *nix's where. It can locate a command in the file hierarchy, as well as return its containing directory.
.PARAMETER command
The name of the command to search for
.PARAMETER directory
A switch, its presence will return the containing directory rather than the path to the command itself.
.EXAMPLE
Search-Executable notepad.exe
.NOTES
Often aliased to `whereis`
#>
function Search-Executable {
	param (
		[Parameter(Mandatory = $true)]
		[string] $command,
		[Parameter(Mandatory = $false)]
		[switch] $directory
	)
	if ($directory -eq $true) {
		Split-Path (Get-Command $command | Select-Object -ExpandProperty Definition) -parent
	} else {
		$(Get-Command $command).source
	}
}
Set-Alias -Name "whereis" -Value Search-Executable

# new mv
if (alias mv   -ErrorAction SilentlyContinue) { Remove-Item alias:mv   }

# new curl
if (alias wget -ErrorAction SilentlyContinue) { Remove-Item alias:wget }

# new curl
if (alias curl -ErrorAction SilentlyContinue) { Remove-Item alias:curl }

# less
Set-Alias -Name "less" -Value "$($config.basedir)\system\git\usr\bin\less.exe"

# sed
Set-Alias -Name sed -Value "$($config.basedir)\system\git\usr\bin\sed.exe"

# File hashes for md5sum and sha256sum
function Get-md5sum { Get-FileHash -Algorithm "md5" -Path $args }; Set-Alias -Name md5sum -Value Get-md5sum
function Get-sha256sum { Get-FileHash -Algorithm "sha256" -Path $args }; Set-Alias -Name sha256sum -Value Get-sha256sum

# hexdump
if (-not (Get-Command hexdump.exe -ErrorAction ignore )) { Set-Alias -Name hexdump -Value "Format-Hex" }

# psr "PowerShell Remoting" -> Enter-PSSession 
Set-Alias -Name psr -Value Enter-PSSession

# Use the Silver Searcher to do 
# Find File; -g finds files
function ff { & "$($config.basedir)\bin\ag.exe" -i -g $args }


#################################################
######        STEP #4: USER SPECIFICS       #####
#################################################
# Ultimately this should be its own usr file
function Open-GitHubDevDirectory { Set-Location "${env:Home}\Dev\src\github.com\$($user.GitUser)\$($args[0])" }
set-alias -Name gh -Value Open-GitHubDevDirectory
function Open-OmegaBaseDirectory { Set-Location ( Join-Path $config.Basedir $args[0] ) }
set-alias -Name om -Value Open-OmegaBaseDirectory

<#
.Synopsis
Tail follows file updates and prints to screen as they occur
#>
function Get-FileContentTail { 
	param(
		[Parameter(Mandatory = $true, Position = 1)]
		[Alias("f")]
		[string] $file
	)
	Get-Content -Tail 10 -Wait -Path $file
}
set-alias -Name tail -Value Get-FileContentTail
<#
.Synopsis
 Search Knowledge Base files for text using Silver Surfer
#>
function Search-KnowledgeBase {
	param (
		[Parameter(Mandatory = $false, Position = 1)]
		[string] $Term,

		[Parameter(Mandatory = $false, HelpMessage = "The Path can not have a trailing slash.")]
		[string] $Path = (Join-Path ${env:Home} "\Google Drive\Documents\Knowledge Base"),

		[Parameter(Mandatory = $false, HelpMessage = "Opens a new vscode window into your kb folder.")]
		[switch] $Create,

		[Parameter(Mandatory = $false, HelpMessage = "Open file, Read-only.")]
		[Alias("o")][switch] $Open,
		
		[Parameter(Mandatory = $false, HelpMessage = "Search in filenames only, not contents.")]
		[Alias("f")][switch] $SearchFilenames,
		
		[Parameter(Mandatory = $false, HelpMessage = "Display filenames only, not contents.")]
		[Alias("l")][switch] $DisplayFilenames,

		[Parameter(Mandatory = $false, HelpMessage = "Ignore Filename/Path pattern. Can take *.ext or Filename.ext as item,comma,list")]
		[Alias("i")][string[]] $IgnorePath = "*.ipynb",
		
		[Parameter(Mandatory = $false, HelpMessage = "Disable Filename/Path pattern.")]
		[Alias("n")][switch] $NoIgnorePath,

		[Parameter(Mandatory = $False)][string] $Editor = "code",

		[Alias("h", "?" )][switch] $help
	)
	# NOTE: THE PATH CAN _NOT_ HAVE A TRAILING SLASH , but we will make it safe just in case nobody listens
	# replace the last character ONLY IF IT IS / or \
	$path = $path -replace "[\\/]$"
	if ($Create) {
		# https://code.visualstudio.com/docs/editor/command-line
		. $Editor $path
		#### -$Edit HERE
		# code file:line[:character]

	} elseif ( $Term ) {
		if ( $Term -eq "--help" ) {
			$help = $True
		} else {
			# if ( $File ){
			#     & "$($config.basedir)bin\ag.exe" -g --stats --ignore-case $Term $Path 
			# }
			$Modifiers = @(	"--stats",
				"--smart-case",
				"--color-win-ansi", 
				"--pager", "more" )
			If ($DisplayFilenames) {
				$Modifiers += "--count"
			}
			$IgnorePathSplat = @()			
			if ( $NoIgnorePath -eq $False ) {
				$IgnorePath | ForEach-Object { $IgnorePathSplat += "--ignore"; $IgnorePathSplat += "$_" }
			}
			$Params = $Term , $Path
			if ( $SearchFilenames -eq $True ) {
				$Params = "--filename-pattern" , $Params
			}
			If ($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent) { $exe = "EchoArgs.exe" } else { $exe = "ag.exe" }
			# "--ignore","*.ipynb","--ignore","ConEmu.md"
			# & "$($config.basedir)\bin\ag.exe" --stats --smart-case @IgnorePathSplat --color-win-ansi --pager more (&{If($DisplayFilenames) {"--count"}}) $Term $Path 
			# & "$($config.basedir)\bin\ag.exe" @modifiers @IgnorePathSplat @Params
			$output = & "$($config.basedir)\bin\$exe" @Modifiers @IgnorePathSplat @Params
			$output	# in the future, this could be prettied-up
			if ( $Open -eq $True ) {
				# .  ( $output | Select-String -Pattern "\w:\\[\w\\\s\/.]*" )
				Write-Host -ForegroundColor Magenta ( $output | select-string -Pattern "\w:\\[\w\\\/. /]*" ).Matches
				
				
				( $output | select-string -Pattern "\w:\\[\w\\\/. /]*" ).Matches | ForEach-Object {
					if ( Enter-UserConfirm -dialog "Open $_ in editor?"  ) {
						. $Editor $_
					}
				}
			}



		}
	} else {
		Write-Warning "Please enter search text"
		
		Write-Output "---kb---help---start---"
		Get-Help $MyInvocation.MyCommand
		Write-Output "---kb---help---end---"
	}
	if ( $help ) { Get-Help $MyInvocation.MyCommand; return; } # Call help on self and exit
}
Set-Alias -Name kb -Value Search-KnowledgeBase

<#
.Synopsis
Complete hosts for ssh
#>
Register-ArgumentCompleter -Native -CommandName ssh -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	$known_hosts_path = Join-Path $env:HOME ".ssh\known_hosts"
	if ( Test-Path $known_hosts_path ) {
		$matches = select-string $known_hosts_path -pattern "^[\d\w.:]*" -AllMatches
		$matches += select-string $known_hosts_path -pattern "(?<=,)([\w.:]*)" -AllMatches

		$matches | Where-Object { 
			$_.matches.Value -like "$wordToComplete*"
		} | Sort-Object | 
			Foreach-Object { 
			$CompletionText = $_.matches.Value 
			$ListItemText = $_.matches.Value 
			$ResultType = 'ParameterValue'
			$ToolTip = $_.matches.Value 
			[System.Management.Automation.CompletionResult]::new($CompletionText, $ListItemText, $ResultType, $ToolTip)
		}
	} else {
		Write-Debug "$known_hosts_path not found"
	}
}