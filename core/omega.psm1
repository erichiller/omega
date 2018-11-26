try { . ([ScriptBlock]::Create("using module '$($MyInvocation.MyCommand.ScriptBlock.Module.ModuleBase)\objects.ps1'")); } catch { Write-Verbose $_ }

<#
####### OMEGA - init script for PowerShell ######
#################################################
***** Setting up the PowerShell environment *****
################ Eric D Hiller ##################
################ March 18 2018 ##################
################################################
#>

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
Add-DirToPath(Join-Path $Config.BaseDir $Config.bindir)

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
        Import-Module -Global -Name "posh-git" -ErrorAction Stop >$null
    }
	$DebugPreference = $script:DebugPreference_prior
	# set status as true
	$gitStatus = $true
	# if git is loaded, this means ssh is most likely available, lets check for KeeAgent's socket too and set if present
	# **NOTE** This must be configured as a CYGWIN compatible socket in KeeAgent
	if ( Test-Path ( Join-Path $env:TEMP "KeeAgent.sock" ) ) { $env:SSH_AUTH_SOCK = Join-Path $env:TEMP "KeeAgent.sock" }
	else { Write-Verbose "KeeAgent.sock was not found in ${env:TEMP}, it will not be used as ssh-agent" }
    # For information on Git display / style preference variables, see the [PoshGitPromptSettings] class
    # https://github.com/dahlbyk/posh-git/blob/master/src/PoshGitTypes.ps1
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
    if ( Get-Module "GitStatusCachePoshClient" ){
        Write-Verbose "module 'GitStatusCachePoshClient' already loaded, skipping forced load"
    } else {
        Import-Module -Name "GitStatusCachePoshClient" -ErrorAction Stop >$null
    }
} catch {
	Write-Warning "The GitStatusCachePoshClient module could not be found & imported, large directories may take significantly longer without it."
}

# # 4.2 sec
try {
    if ( Get-Module "oh-my-posh" ){
        Write-Verbose "module 'oh-my-posh' already loaded, skipping forced load"
    } else {
        if ( $gitStatus -eq $True ){
            Import-Module oh-my-posh -Global -ErrorAction Stop >$null
            $global:ThemeSettings.MyThemesLocation = "$($config.basedir)\core"
            Set-Theme themeOmega
        }
    }
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
Set-Alias -Name "whereis" -Value Search-Executable

# new ls
if (alias ls   -ErrorAction SilentlyContinue) { Remove-Item alias:ls   }
if (alias ls   -ErrorAction SilentlyContinue) { Remove-Item alias:ls   }

# new mv
if (alias mv   -ErrorAction SilentlyContinue) { Remove-Item alias:mv   }

# new wget
if (alias wget -ErrorAction SilentlyContinue) { Remove-Item  -Force alias:wget }
if (alias wget -ErrorAction SilentlyContinue) { Remove-Item  -Force alias:wget }
Set-Alias -Name "wget" -Value "$($config.basedir)\bin\wget.exe"

# new curl
if (alias curl -ErrorAction SilentlyContinue) { Remove-Item  -Force alias:curl }
if (alias curl -ErrorAction SilentlyContinue) { Remove-Item  -Force alias:curl }
Set-Alias -Name "curl" -Value "$($config.basedir)\bin\curl.cmd"

# scp
if (alias scp -ErrorAction SilentlyContinue) { Remove-Item  -Force alias:scp }
if (alias scp -ErrorAction SilentlyContinue) { Remove-Item  -Force alias:scp }
Set-Alias -Name "scp" -Value "$($config.basedir)\bin\scp.cmd"

# less
Set-Alias -Name "less" -Value "$($config.basedir)\system\git\usr\bin\less.exe"

# sed
Set-Alias -Name sed -Value "$($config.basedir)\system\git\usr\bin\sed.exe"

# ssh
Set-Alias -Name ssh -Value "$($config.basedir)\bin\ssh.cmd"

# file hashes
Set-Alias -Name md5sum -Value Get-md5sum
Set-Alias -Name sha256sum -Value Get-sha256sum

# alias linux's `ifconfig` with windows' `ipconfig`
Set-Alias -Name ifconfig -Value ipconfig

# hexdump
if (-not (Get-Command hexdump.exe -ErrorAction ignore )) { Set-Alias -Name hexdump -Value "Format-Hex" }

# psr "PowerShell Remoting" -> Enter-PSSession
Set-Alias -Name psr -Value Enter-PSSession

# f is Search-FrequentDirectory
Set-Alias -Name f -Value Search-FrequentDirectory -ErrorAction Ignore



#################################################
######        STEP #4: USER SPECIFICS       #####
#################################################
set-alias -Name gh -Value Open-GitHubDevDirectory
set-alias -Name om -Value Open-OmegaBaseDirectory


set-alias -Name tail -Value Get-FileContentTail
Set-Alias -Name kb -Value Search-KnowledgeBase

# function Show-HelpKeyGrid {
#     Select-Xml -Path "\\nas\users\eric\Documents\WindowsPowerShell\Modules\omega\core\config\ConEmu.xml" -XPath "//key[@name='HotKeys']" |  Select-Object –ExpandProperty "node" | Select-Object -ExpandProperty "value" | foreach { $_.data }
# }

<#
.Synopsis
Complete hosts for ssh
.NOTES
Non-filename completers are currently not capable of returning when there is no initial text
It will be overriden by the default, which is to use the local path.
thus ssh <tab> will yield the files in the local directory
For more information see:
https://github.com/PowerShell/PowerShell/issues/8092
$PSDefaultParameterValues variable does not affect native commands
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-6
#>
Register-ArgumentCompleter -Native -CommandName ssh -ScriptBlock {
	param($wordToComplete, $commandAst, $cursorPosition)
	$known_hosts_path = Join-Path $env:HOME ".ssh\known_hosts"
	$ssh_config_path = Join-Path $env:HOME ".ssh\config"
	$matches = @()
	if ( Test-Path $known_hosts_path ) {
		(select-string $known_hosts_path -pattern "((?<=,)([\w.:]+))|(^[\d\w.:]+)" -AllMatches) | ForEach-Object {
			$matches += $_.Matches.Value
		}
	}
	if ( Test-Path $known_hosts_path ) {
		# select Hostnames and Aliases
		(select-string $ssh_config_path -pattern "((?<=host )([\w\d.\- ]*))|([\d]{1,3}\.[\d]{1,3}.[\d]{1,3}.[\d]{1,3})" -AllMatches) | foreach-object {
			$matches += $_.Matches.Value.Split(" ")
		}
	}
	if ( Test-Path variable:matches ){
		$matches | Select -Unique | Where-Object {
			$_ -like "$wordToComplete*"
		} | Sort-Object |
			Foreach-Object {
			$CompletionText = $_
			$ListItemText = $_
			$ResultType = 'ParameterValue'
			$ToolTip = $_
			[System.Management.Automation.CompletionResult]::new($CompletionText, $ListItemText, $ResultType, $ToolTip)
	}
}

<#
.Synopsis
Complete paths from history
.Notes
`CommandName` can be an ARRAY listed as `Command1 , Command2`
# #>
# Register-ArgumentCompleter -CommandName  f -ParameterName Path -ScriptBlock {
#     param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
# 	$known_hosts_path = Join-Path $env:HOME ".ssh\known_hosts"
# 	if ( Test-Path $known_hosts_path ) {
# 		$matches = select-string $known_hosts_path -pattern "^[\d\w.:]*" -AllMatches
# 		$matches += select-string $known_hosts_path -pattern "(?<=,)([\w.:]*)" -AllMatches

# 		$matches | Where-Object {
# 			$_.matches.Value -like "$wordToComplete*"
# 		} | Sort-Object |
# 			Foreach-Object {
# 			$CompletionText = $_.matches.Value
# 			$ListItemText = $_.matches.Value
# 			$ResultType = 'ParameterValue'
# 			$ToolTip = $_.matches.Value
# 			[System.Management.Automation.CompletionResult]::new($CompletionText, $ListItemText, $ResultType, $ToolTip)
# 		}
# 	} else {
# 		Write-Debug "$known_hosts_path not found"
# 	}
# }

