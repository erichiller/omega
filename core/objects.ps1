<#
Objects, Types
#>


# for some unknown reason, powershell will not load the first definition of this file
# so make it useless
class NoType {}

class PushConfig {
	[string] $bashrc
	[string] $vimrc
}

class VerbosityConfig {
	[string] $Information = $InformationPreference;
	[string] $Verbose = $VerbosePreference;
	[string] $Debug = $DebugPreference;
}

## only have immutable configurations here ; mutable goes into user
## something like this could even be the basis for shared variables ???
class OmegaConfig {

	[string] $Name = "Omega"
	[string] $BinDir
	[string] $SysDir
	[string] $ConfDir
	[string] $UserDir
	[string] $HelpDir
	[string] $system_environment_key
	[string] $user_environment_key
	[string] $app_paths_key
	[string[]] $compression_extensions
	[string[]] $SingleFileExtensions
	[string] $LogPath
	[PushConfig] $Push
	[VerbosityConfig] $DefaultVerbosity;

	# generated
	[string] $BaseDir;
	# static, generated
	static hidden [string] $ConfigPath;
	# Singleton
	static hidden [OmegaConfig] $instance
	static [OmegaConfig] GetInstance() {
		if ([OmegaConfig]::instance -eq $null) {

			if (!$PSScriptRoot) {
				$local:BaseDir = Split-Path $script:MyInvocation.MyCommand.Path -Parent
				$PSScriptRoot = $local:BaseDir
				Write-Verbose "[OmegaConfig]::BaseDir set via MyInvocation to $($local:BaseDir)"
			}
			else {
				$local:BaseDir = Split-Path $PSScriptRoot -Parent
				Write-Verbose "[OmegaConfig]::BaseDir set via PSScriptRoot to $($local:BaseDir)"
			}

			[OmegaConfig]::ConfigPath = ( Join-Paths ($local:BaseDir) "core" "config" "config.json" )
			Write-Debug "[OmegaConfig]:: Testing to Path $([OmegaConfig]::ConfigPath)"
			if (Test-Path ( [OmegaConfig]::ConfigPath ) ) {
				Write-Debug "[OmegaConfig]:: Found ConfigPath @ $([OmegaConfig]::ConfigPath)"
				[OmegaConfig]::instance = [OmegaConfig] ( Get-Content ( [OmegaConfig]::ConfigPath ) | ConvertFrom-Json )
				([OmegaConfig]::instance).BaseDir = $local:BaseDir
			}
			else {
				Write-Error "[OmegaConfig] -- Config file not found: $( [OmegaConfig]::ConfigPath )"
			}
		}
		return [OmegaConfig]::instance
	}

	OmegaConfig() {
		Write-Debug "Empty OmegaConfig init --> SHOULD USE ::GetInstance()"
	}

	[string] GetLogPath() {
		return ( Join-Path $this.BaseDir $this.LogPath )
	}


}

Class User {
	[string] $GitUser;
	[string] $GitRepoState;
	[System.Collections.ArrayList] $SystemPathAdditions;
	static hidden [string] $UserStateFilePath = ( Join-Path ([OmegaConfig]::GetInstance()).BaseDir (Join-Path "local" "state.json" ) );
	[psobject] $Packages;
	[string[]] $RegisteredCommands;
	# these defaults can be overriden
	[VerbosityConfig] $Verbosity = ([OmegaConfig]::GetInstance()).DefaultVerbosity;
	[PushConfig] $Push = ([OmegaConfig]::GetInstance()).Push;

	# Singleton
	static hidden [User] $instance
	static [User] GetInstance() {
		if ($null -eq [User]::instance) {
			Write-Verbose "User::GetInstance() -> -eq Null -> new()"

			Write-Verbose "[User]::UserStateFilePath $([User]::UserStateFilePath)"
			Write-Debug "[OmegaConfig]::GetInstance().BaseDir "
			Write-Debug ([OmegaConfig]::GetInstance()).BaseDir
			Write-Debug "In User::GetIntance Seeking UserStateFilePath ; Testing to Path $([User]::UserStateFilePath)"
			if (Test-Path ( [User]::UserStateFilePath ) ) {
				Write-Debug "Found UserStateFilePath @ $([User]::UserStateFilePath)"

				# [User]::instance = [User]::new()
				[User]::instance = [User] (Get-Content ( [User]::UserStateFilePath ) | ConvertFrom-Json)
			}
			else {
				Write-Warning "UserState file not found: $( [User]::UserStateFilePath )"
			}
		} 
		return [User]::instance
	}
	# constructor
	# Git & GitRepoState
	# Use this to download State from Repo
	# RESTORATION
	User([string] $GitUser, [string] $GitRepoState) {
		$this.GitUser = $GitUser;
		$this.GitRepoState = $GitRepoState;
		Debug-Variable $this "User init from GitUser=$GitUser + $GitRepoState"
		# [User]::instance = $this
	}
	# constructor for JSON Input
	# if file IS found, then create from JSON
	# if file is NOT found, then operate with no parameters
	User() {
		Write-Debug "Empty User init --> SHOULD USE ::GetInstance()"
	}

	# add Package
	setInstalledPackage([InstalledPackage] $Package) {
		Write-Debug "Adding Package $Package"
		Debug-Variable $Package
		# if ( $this.Packages -eq $null ){
		#     $this.Packages = New-Object System.Management.Automation.PSCustomObject;
		# }
		$this.Packages | Add-Member -MemberType NoteProperty -TypeName InstalledPackage -Name $Package.Name -Value $Package -Force
		# $this.Packages | Add-Member $Package -Name Package.Name - ScriptProperty
		$this.SaveState()
	}

	add_SystemPathAdditions([String] $SystemPathAddition) {
		$this.SystemPathAdditions = @( ArrayAddUnique -AddTo $this.SystemPathAdditions -AdditionalItem $SystemPathAddition )
	}

	SaveState() {
		Write-Verbose "Saving State to $([User]::UserStateFilePath)"
		$this | ConvertTo-Json -Depth 5 | Set-Content ( [User]::UserStateFilePath )
	}

	# see git submodules
	# save /local
	SaveUserConfig() {}

	SetUserRepo ([string] $GitUser ) {

	}


	NewUserConfigRepo ([string] $GitUser, [string] $GitRepo = "maxpowershell_config" ) {
	}

}


Enum PackageInstallSource {
	GitRelease;
	GitMaster;
	WebDirSearch
}

class PackageProvides {
	[string[]] $Commands; # this commands will be registered into the User's state RegisteredCommands
	[string[]] $Binaries;
}

class PackageInstallParameters {
	[PackageInstallSource] $Source;
	[string] $Destination;
	[bool] $AdminRequired;

	# Only for WebDirSearch
	[System.Array] $SearchPath;
	# Not used by GitMaster
	[string] $VersionPattern;

	# Present only for GitRelease
	[string] $Org;
	[string] $Repo;
}


<#
 ShortCut data object for Package Parameters
#>
class PackageShortcut {
	[string] $ShortcutPutPath;       # Where the shortcut should be located after creation
	[string] $TargetPath;            # What the shortcut points to
	[string] $Arguments;             # Arguments for the Target
	[string] $IconPath;              # Path to Icon which will be used for Shortcut
	[bool]   $RegisterApp;             # Register the "App" with Windows, this allows it to be found via Cortana Search
}

class PackageSystemAlterations {
	[System.Collections.ArrayList] $PathAdditions;
	[PSObject] $SystemEnvironmentVariables;
	[PSObject] $SymLinks;
	[string[]] $Directories;

	[Object[]] SystemEnvironmentVariables_Iterable() {
		Write-Debug "[PackageSystemAlterations]::SystemEnvironmentVariables_Iterable is Returning SystemEnvironmentVariables as name,value iterable"
		return ($this.SystemEnvironmentVariables.PSObject.Properties | select-object name, value)
	}
}

class Package {
	[string] $Name;
	[string] $Brief;
	[bool] $Required;
	[PSObject] $Dependencies;
	[PackageInstallParameters] $Install;
	[PackageSystemAlterations] $System;
	[PackageProvides] $Provides;
	[PackageShortcut[]] $Shortcuts;

	static hidden [string] $pkgPathBase = ( Join-Paths ([OmegaConfig]::GetInstance()).BaseDir "core" "pkg" )

	# Singleton of Package[Name]
	# static hidden [hashtable] $instance
	static hidden [psobject] $instance

	static [Package] GetInstance([string] $PackageName) {
		Write-Verbose "Package::GetInstance($PackageName)"
		if ( $null -eq [Package]::instance.$PackageName ) {
			[Package]::instance = ( New-Object psobject )
			Write-Verbose "Package::GetInstance($PackageName) -> -eq Null -> new()"

			$ConfigPath = ( Join-Paths ( [Package]::pkgPathBase ) $PackageName "pkg.json" )

			Write-Debug "Testing to Path $ConfigPath"
			if (Test-Path $ConfigPath ) {
				Write-Debug "Found pkg ConfigPath @ $ConfigPath"

				Write-Debug "ConfigPath Content---"
				( "gc $ConfigPath :" + ( (Get-Content $ConfigPath)  )) | Write-Host -ForegroundColor "DarkMagenta"
				( "Get-Content $ConfigPath | ConvertFrom-Json :`n" + ( (Get-Content $ConfigPath | ConvertFrom-Json | Format-List) | out-string )) | Write-Host -ForegroundColor "Cyan"
				$json = (Get-Content $ConfigPath | ConvertFrom-Json)
				( "`$json type :`n" + ( $json.getType()  )) | Write-Host -ForegroundColor "Green"
				( "cast `$json to [Package] :`n" + ( [Package]$json | get-member | out-string) ) | Write-Host -ForegroundColor "Cyan"
				( "([Package]`$json).Install.AdminRequired :`t" + ( ([Package]$json).Install.AdminRequired | out-string) ) | Write-Host -ForegroundColor "green"
				( "([Package]`$json).name :`t" + ( ([Package]$json).name | out-string) ) | Write-Host -ForegroundColor "green"


				[Package] $obj = ([Package] ( Get-Content $ConfigPath | ConvertFrom-Json ))
				Debug-Variable $obj "Package::GetInstance($PackageName) -> obj"

				# [User]::instance = [User]::new()
				Add-Member -InputObject ([Package]::instance) -MemberType NoteProperty -Name $PackageName -Value $obj -TypeName [Package]

			}
			else {
				"pkgConfig file not found: $ConfigPath"
			}
		}
		Debug-Variable ([Package]::instance) "[Package]::GetInstance($PackageName)"
		Write-Verbose "Package::GetInstance($PackageName) -> returning instance $(([Package]::instance).$PackageName)"
		return ([Package]::instance).$PackageName
	}

	[Object[]] Dependencies_Iterable() {
		Write-Debug "[Package]::Dependencies_Iterable is returning Dependencies as name,value iterable"
		return ($this.Dependencies.PSObject.Properties | select-object name, value)
	}

	Package () {
		Write-Debug "Package() init is actionless"
	}
	# constructor reads pkg.json
	Package([string] $name) {
		Write-Debug "Package($name) init is actionless"
	}

	[bool] TestPrerequisites() {
		Write-Verbose "Checking Prerequisites for the PACKAGE<$($this.Name)>"
		

		$local:e = "Missing Dependency! Installation is impossible; missing:"


		if ( ( Test-Path variable:this.Dependencies ) ) {
			$this.Dependencies_Iterable() | ForEach-Object {
				$dependencyPackageName = $_.name
				$requiredPackageVersion     = $_.value
				try {
					$installedPackage = [User]::GetInstance().Packages.$dependencyPackageName
					$installedVersion = $installedPackage.Version
					if ( $installedVersion -match $requiredPackageVersion ){
						throw "$installedVersion of $dependencyPackageName does not meet the version requirement of $requiredPackageVersion"
					}
				} catch {
					Write-Error $e
					return $False
				}
			}
		}


		if ( ( [boolean] (Get-Command -Name "7z" -ErrorAction SilentlyContinue) ) -eq $False ) {
			if (Test-Path "C:\Program Files\7-Zip\7z.exe") {
				Add-DirToPath "C:\Program Files\7-Zip\"
			}
			else {
				Write-Error "${local:e} 7zip"
				return $False
			}
		}

		Write-Debug "Package.Install.AdminRequired: $($this.Install.AdminRequired)"
		Write-Debug "Test-Admin: $(Test-Admin)"
		if ( ( Test-Path variable:this.System.PathAdditions ) -or ( Test-Path variable:this.System.SystemEnvironmentVariables ) ) {
			if ( -not $this.Install.AdminRequired ) {
				Write-Warning "Package.adminRequired is `$False ; however if either `PathAdditions` or `SystemEnvironmentVariables` is specified `Install.AdminRequired` is equated to `$True`."
				# set to $True for operations.
				$this.Install.AdminRequired = $True
			}
		}
		if ( $this.Install.AdminRequired -and !(Test-Admin) ) {
			Write-Warning "You must be in administrator shell to install this package. Opening Administrator prompt..."
			# powershell.exe "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -File c:\install.ps1' -Verb RunAs"
			powershell.exe "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoLogo' -Verb RunAs"
			Write-Verbose "Returning False in `$Package.Install.AdminRequired -and !(Test-Admin)"
			return $False
		}
		( "{ in test-preq } `$Package members:`n" + ( $this | get-member | out-string) ) | Write-Host -ForegroundColor "Magenta"
		Write-Verbose "Test-InstallPrerequisite reporting success, $True"
		return $True
	}

	[bool] InvokeInstallScript() {
		Write-Debug "looking for path at $([Package]::pkgPathBase) + $($this.Name) + install.ps1"
		$local:install_ps1_path = ( Join-Paths ( [Package]::pkgPathBase ) $this.Name "install.ps1"  )
		if ( Test-Path $local:install_ps1_path ){
			Write-Debug "InstallScript found, running..."
			try {
				. $local:install_ps1_path
			} catch {
				Write-Warning ( "Received Exception '" + $_.Exception.Message + "' ; will not continue executing install.ps1" )
				return $False
			}
			return $True
		}
		Write-Debug "No InstallScript exists, continuing"
		return $True
	}


}


class InstalledPackage : Package {
	[string] $UpdateDate;
	[string] $Version;

	InstalledPackage() {
		Write-Debug "InstalledPackage empty constructor"
	}

	# InstalledPackage([string] $PackageName){
	# 	Get-Content( [User]::UserStateFilePath ) | ConvertFrom-Json
	# 	if ( Test-Path variable:userLoadedObject.PSObject.$PackageName.Version ) {
	# 		[Package]
	# 	}
	# }

	InstalledPackage([string] $PackageName, [string] $VersionIn) {
		Write-Debug "InstalledPackage constructor --> PackageName=$PackageName"
		$this.Name = $PackageName;
		$this.Version = $VersionIn;
		$this.UpdateDate = (Get-Date -format "yyyy-MMM-dd HH:mm" );
		$this.loadPackageFromName($PackageName)
		Debug-Variable $this "InstalledPackage created (constructor)"
	}

	hidden loadPackageFromName([string] $PackageName) {
		$pkg = [Package]::GetInstance($PackageName)
		$pkg.PSObject.Properties | ForEach-Object {
			$propertyName = $_.Name
			$this.$propertyName = $_.value
		}
	}
}
