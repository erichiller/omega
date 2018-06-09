# Module manifest for MaxPowerShell
# Eric D Hiller
# January 2018

<#
 # For formatting and properties, see:
 # https://msdn.microsoft.com/en-us/library/dd878337(v=vs.85).aspx
 #>
@{
	Author            = "Eric D Hiller"
	Description       = "Max Power Shell - Get more out of your command environment."
	ModuleVersion     = "0.0.0.2"
	GUID              = "ad3159e1-ef91-4c84-9b48-62f746dc4a25"


	RootModule        = "core\omega.psm1"
	PowerShellVersion = "5.1"
	# RequiredModules are modules which are required to be loaded into the GLOBAL environment before this module loads (else it fails to load)
	# Nothing is processed within the module before this, so it is impossible to 'install' dependencies first

	#IDEA i updated these, make sure it is proper.
	#            may not want these here because they'd prevent the install script from running
	#            i could have the install script update an ./local/module.state.psd1 that is included here
	#            so that required assemblies and some other values only exist post-install
	#            this would be great for installing modules!
	RequiredModules = @(
        # "posh-git"
    )
	# RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's (GLOBAL) environment prior to importing this module
	#    Having _anything_ present in this field causes it to be present as a *seperate* module in the user's environment
	ScriptsToProcess = @()
	TypesToProcess   = @()
	FormatsToProcess = @()

	AliasesToExport   = @(
        "7z"
        "curl"
        "f"
        "gh"
        "hexdump"
        "kb"
        "less"
        "om"
        "powershell"
        "Print-Path"
        "psr"
        "sed"
        "ssh"
        "tail"
        "wget"
        "whereis"
        "which"
        )
    CmdletsToExport   = @()
	VariablesToExport = @(
        "GitPromptScriptBlock"
    ) # all
	FunctionsToExport = @(
        "Add-DirToPath"
        "Show-Env"
        "Show-Path"
        "Get-DirectoryDiff"
        "Open-OmegaBaseDirectory"
        "Open-GitHubDevDirectory"
        "Convert-DirectoryStringtoUnix"
        "Remove-DirFromPath"
        "Send-LinuxConfig"
        "Get-DirectorySize"
        "Search-Executable"
        "Write-Prompt"
        "Get-PrettyPath"
        "New-OmegaShortcut"
        "mv"
        "grep"
        "ff"
        "ls"



## non-omega
#         "Get-ComputerName"
#         "Get-Drive"
#         "Get-FullPath"
#         "Get-ShortPath"
#         "Get-Theme"
#         "Get-VcsInfo"
#         "Get-VCSStatus"
#         "Get-VirtualEnvName"

#         "ThemeCompletion"
#         "NewCompletionResult"

#         "Test-NotDefaultUser"
#         "Set-CursorForRightBlockWrite"
#         "Reset-CursorPosition"
#         "Set-CursorUp"
#         "Set-Newline"
#         "Start-Up"
#         "Set-Prompt"

#         "Set-CursorUp"
#         "Set-Newline"
#         "Set-CursorForRightBlockWrite"
#         "Set-Theme"
#         "Show-Colors"
#         "Show-ThemeColors"
#         "Show-ThemeSymbols"
#         "Test-Administrator"
#         "Test-NotDefaultUser"
#         "Test-VirtualEnv"

#         "Update-AllBranches"
#         "Write-GitBranchName"
#         "Write-GitBranchStatus"
#         "Write-GitIndexStatus"
#         "Write-GitStashCount"
#         "Write-GitStatus"
#         "Write-GitWorkingDirStatus"
#         "Write-GitWorkingDirStatusSummary"

#         "Add-PoshGitToProfile"

#         "Format-GitBranchName"
#         "Get-GitBranchStatusColor"
#         "Get-GitDirectory"
#         "Get-GitStatus"
#         "Get-PromptPath"
#         "Get-SshAgent"
#         "Get-SshPath"

#         "TabExpansion"

# ## omega
#         "Omega-Help"
#         "Remove-DirFromPath"
#         "SafeObjectArray"
#         "Save-UserConfig"
        "Search-FrequentDirectory"
        "Search-KnowledgeBase"
        # "Set-RegisterCommandAvailable"
#         "Set-UserRepo"
#         "Test-Admin"

#         "ArrayAddUnique"
#         "checkGit"
#         "Convert-DirectoryStringtoUnix"
#         "Debug-Title"
#         "Debug-Variable"
#         "Enter-UserConfirm"
#         "ff"
#         "Get-CommandsAvailable"
#         "Get-DirectoryDiff"
#         "Get-DirectorySize"
        "Get-FileContentTail"
#         "Get-md5sum"
#         "Get-sha256sum"
#         "grep"
#         "Join-Paths"
#         "New-UserConfigRepo"

#         "tgit"
#         "Start-SshAgent"
#         "Stop-SshAgent"
#         "Add-SshKey"
    )
    


	# ModuleList can be either array of strings or of
	#     objects with ModuleName , ModuleVersion , and optional GUID keys
	ModuleList        = @()
	FileList          = @()
	<# NestedModules
    Type:	[Object[]]
    Default:	@()

    Modules to import as nested modules of the module specified in RootModule/ModuleToProcess.

    Adding a module name to this element is similar to calling Import-Module from within your script or assembly code. The main difference is that it’s easier to see what you are loading here in the manifest file. Also, if a module fails to load here, you will not yet have loaded your actual module.

    In addition to other modules, you may also load script (.ps1) files here. These files will execute in the context of the root module. (This is equivalent to dot sourcing the script in your root module.)
    #>
	# Nested modules can be listed as an object (same as ModuleList) or as a path relative to the ModuleBase
	# Script files , modules , etc that are run in the module's environment prior to importing this module
	NestedModules     = @(
		# "core/prep.ps1"
		# "core/install.ps1"
		"core\core.ps1"
		"core\core.chk.ps1"
		"core\core.ui.ps1"
		# "core/system.install.ps1"
		"core\user.omega.ps1"
        "core\user.utilities.ps1"
		"core\resources.create.ps1"
	)

	# HelpInfoURI          = ""
	# DefaultCommandPrefix = ""
	# PackageManagementProviders = @()

	# BE SURE TO UPDATE THESE URIs !
	PrivateData       = @{
		PSData = @{
			Category                 = "Console Suite"
			Tags                     = @("powershell", "console", "cli", "conemu", "git", "vim")
			IconUri                  = ""
			ProjectUri               = "https://MaxPower.sh"
			LicenseUri               = "https://MaxPower.sh/"
			ReleaseNotes             = "https://MaxPower.sh/release/Changelog"
			RequireLicenseAcceptance = 'False'
			IsPrerelease             = 'True'

		}
	}


}
   

# see: https://docs.microsoft.com/en-us/powershell/module/Microsoft.PowerShell.Core/New-ModuleManifest?view=powershell-5.1
# https://msdn.microsoft.com/en-us/library/dd878337(v=vs.85).aspx