# Module manifest for MaxPowerShell
# Eric D Hiller
# January 2018
@{
	Author = "Eric D Hiller"
	Description = "Max Power Shell - Get more out of your command environment."
	ModuleVersion = "1.0"
	GUID = "ad3159e1-ef91-4c84-9b48-62f746dc4a25"


	# RootModule = ""
	PowerShellVersion = "5.1"
	# RequiredModules = @()
	# RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's environment prior to importing this module
	# ScriptsToProcess = @()
	# TypesToProcess   = @()
	# FormatsToProcess = @()


	# CmdletsToExport   = @() # all
	# VariablesToExport = @() # all
	# FunctionsToExport = @() # all 
	


	# ModuleList           = @()
	# FileList             = @()
	# NestedModules        = @{}
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