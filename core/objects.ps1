<#
Objects, Types
#>

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

    [string] $BinDir
    [string] $SysDir
    [string] $ConfDir
    [string] $HelpDir
    [string] $system_environment_key
    [string] $user_environment_key
    [string] $app_paths_key
    [string[]] $compression_extensions
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


}

Class RegisteredCommand {
    [string] $Name
    [string] $Synopsis
    [string] $Source
}

Class User {
    [string] $GitUser;
    [string] $GitRepoState;
    [System.Collections.ArrayList] $SystemPathAdditions;
    static hidden [string] $UserStateFilePath = ( Join-Path ([OmegaConfig]::GetInstance()).BaseDir (Join-Path "local" "state.json" ) );
    [psobject] $Packages;
    [RegisteredCommand[]] $RegisteredCommands;
    # these defaults can be overriden
    [VerbosityConfig] $Verbosity = ([OmegaConfig]::GetInstance()).DefaultVerbosity;
    [PushConfig] $Push = ([OmegaConfig]::GetInstance()).Push;

    # Singleton
    static hidden [User] $instance
    static [User] GetInstance() {
        if ([User]::instance -eq $null) {
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
        Write-Verbose "User::GetInstance() -> returning instance $([User]::instance)"
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
    setPackageState([PackageState] $Package) {
        Write-Debug "Adding Package $Package"
        Debug-Variable $Package
        # if ( $this.Packages -eq $null ){
        #     $this.Packages = New-Object System.Management.Automation.PSCustomObject;
        # }
        $this.Packages | Add-Member -MemberType NoteProperty -TypeName PackageState -Name $Package.Name -Value $Package -Force
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
    GitRelease

}

class PackageProvides {
    [string[]] $Commands; # this commands will be registered into the User's state RegisteredCommands
    [string[]] $Binaries;
}

class PackageInstallParameters {
    [PackageInstallSource] $Source;
    [string] $Destination;
    [bool] $AdminRequired;

    [string] $SearchTerm;
    [string] $VersionPattern;

    # Present only for GitRelease
    [string] $Org;
    [string] $Repo;
}

class PackageSystemAlterations {
    [System.Collections.ArrayList] $PathAdditions;
    [PSObject] $SystemEnvironmentVariables;
    [PSObject] $SymLinks;

    [Object[]] SystemEnvironmentVariables_Iterable(){
        Write-Debug "[PackageSystemAlterations]::SystemEnvironmentVariables_Iterable is Returning SystemEnvironmentVariables as name,value iterable"
        return ($this.SystemEnvironmentVariables.PSObject.Properties | select-object name,value)
    }
}

class Package {
    [string] $Name;
    [string] $Brief;
    [bool] $Required;
    [PackageInstallParameters] $Install;
    [PackageProvides] $Provides;
    [PackageSystemAlterations] $System;


    static hidden [string] $pkgPathBase = ( Join-Paths ([OmegaConfig]::GetInstance()).BaseDir "core" "pkg" )

    # Singleton of Package[Name]
    # static hidden [hashtable] $instance
    static hidden [psobject] $instance

    static [Package] GetInstance([string] $PackageName) {
        Write-Verbose "Package::GetInstance($PackageName)"
        if ([Package]::instance.$PackageName -eq $null) {
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


    Package () {}
    # constructor reads pkg.json
    Package([string] $name) {
        Write-Debug "in actionless init Package($name)"
    }

}

class PackageState : Package {
    [string] $UpdateDate;
    [string] $version;

    PackageState() {
        Write-Debug "PackageState empty constructor"
    }

    PackageState([string] $PackageName, [string] $VersionIn) {
        Write-Debug "PackageState constructor --> PackageName=$PackageName"
        $this.Name = $PackageName;
        $this.Version = $VersionIn;
        $this.UpdateDate = (Get-Date -format "yyyy-MMM-dd HH:mm" );
        $this.loadPackageFromName($PackageName)
        Debug-Variable $this "PackageState created (constructor)"
    }

    hidden loadPackageFromName([string] $PackageName) {
        $pkg = [Package]::GetInstance($PackageName)
        $pkg.PSObject.Properties | ForEach-Object {
            $propertyName = $_.Name
            $this.$propertyName = $_.value
        }
    }
}
