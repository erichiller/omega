# Module manifest for MaxPowerShell
# Eric D Hiller
# January 2018
@{
	Author = "Eric D Hiller"
	Description = "Max Power Shell - Get more out of your command environment."
	ModuleVersion = "0.0.0.1"
	GUID = "ad3159e1-ef91-4c84-9b48-62f746dc4a25"


	RootModule = "core/user.init.ps1"
	PowerShellVersion = "5.1"
	# RequiredModules are modules which are required to be loaded into the GLOBAL environment before this module loads (else it fails to load)
	# RequiredModules = @()
	# RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's (GLOBAL) environment prior to importing this module
	# ScriptsToProcess = @()
	# TypesToProcess   = @()
	# FormatsToProcess = @()


	# CmdletsToExport   = @() # all
	# VariablesToExport = @() # all
	# FunctionsToExport = @() # all 
	


	# ModuleList           = @()
	# FileList             = @()
	# Script files , modules , etc that are run in the module's environment prior to importing this module	
	NestedModules        = @(
		"core/core.ps1",
		"core/core.chk.ps1",
		"core/core.ui.ps1",
		"core/objects.ps1",
		"core/user.omega.ps1",
		"core/user.utilities.ps1"
	)
	PrivateData          = @{
		PSData                 = @{
			Category = "Console Suite"
			Tags = @("powershell", "console", "cli", "conemu", "git", "vim")
			IconUri = ""
			ProjectUri = "https://MaxPower.sh"
			LicenseUri = "https://MaxPower.sh/"
			ReleaseNotes = "https://MaxPower.sh/release/Changelog"
			RequireLicenseAcceptance = 'False'
			IsPrerelease = 'True'

		}
	}

	# HelpInfoURI          = ""
	# DefaultCommandPrefix = ""


}

# see: https://docs.microsoft.com/en-us/powershell/module/Microsoft.PowerShell.Core/New-ModuleManifest?view=powershell-5.1
# https://msdn.microsoft.com/en-us/library/dd878337(v=vs.85).aspx