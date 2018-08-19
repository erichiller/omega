
`core/pkg` contains package definitions 



# `pkg.json` definition file values:

`pkg.json` files define the package being installed. Packages can consist of many different types of programs, functions, modules, scripts, etc. Both binary, script, Powershell and non. Git , node , ConEmu are all packages.

Packages definitions are in json format and have several *required* fields and several optional ones. Definitions follow:


# fields

**Preface**

- If the field is only required when another field has a specific value it will be denoted as `(dependencyField=requiredValue)`
- If the field is a parameter of an object then it will be in object notation of `parent.child.subchild`


| Field                 | Required? | Description
|---                    |---        |---          
| Name                  | Yes       | Package name
| Brief                 | Yes       | Package description
| Required              | Yes       | Is this package required to operate **NOTE: this is _internal_ use only**
| `Install.*`           | **BELOW** | Parameters required for Installation
| `Provides.*`          | No        | Resources this package provides
| `System.*`            | No        | System Alterations which will be made by this package.

### `Install.*`

The `GitRelease` package source downloads a *release* from a github repo.

| Field					| Required? | Description
|---					|---        |---       
| AdminRequired         | Yes       | Are administrator privileges required to install this package?
| Source                | Yes       | Type of package, method of installation, see Enum `PackageInstallSource`
| Destination	        | Yes		| destination for the installation, either an exact path string, or the keyword `SystemPath` which installs to `<basedir>\system\<pkgname>`
| versionPattern		| Yes		| regex string to extract the version from the downloaded (full URL)

#### If source=WebDirSearch
| SearchPath			| Yes		| **ARRAY** of URLs listed from parent to child in which to search for downloadable file

#### If Source=GitRelease
| Field					| Required? | Description
|---					|---        |---       
| org					| Yes		| org name for the organization the package can be found at
| repo					| Yes		| repo of org to download from

### `Shortcut.*`

| Field                 | Required? | Description
|---                    |---        |---      
| ShortcutPutPath   | No        | *Array* of directories to be added to the system `%PATH%`

### `System.*`

| Field                 | Required? | Description
|---                    |---        |---      
| SystemPathAdditions   | No        | *Array* of directories to be added to the system `%PATH%`
| SystemEnvironmentVariables | No   | `{"VarName": "VarValue",...}` of variables to be added to the System Environment (`$Env:VarName`)
| SymLinks              | No        | SymLinks to create in the form of `"/internal/path/of/pkg/": "/path/within/system"`
| Directories           | No        | Directories which this package owns, Created if necessary

* If either `SystemPathAdditions` or `SystemEnvironmentVariables` is specified `adminRequired` is equated to `$True`.

### `Provides.*`

| Field                 | Required? | Description
|---                    |---        |---      
| Provides.Commands     | No        | Commands this package provides and should be registered.
| Provides.Binaries     | No        | Critical Binary (Executables) that other packages may desire/depend on that this package provides




- Directories
- Shortcut
    - ShortCutPath
    - TargetPath
    - Arguments
    - IconPath
    - Register
- *run `install.ps1` if present*
- 


# example


```json
[
    {
        "name": "git",
        "brief": "Git for Windows 64 bit",
		"required": true,
        "Install": {
	    	"adminRequired": true,
            "installSource": "GitRelease",
            "InstallDestination": "SystemPath",
            "Org": "git-for-windows",
            "Repo": "git",
            "VersionPattern": "^Git-(.*)-64-bit\\.tar\\.bz2$"
        }
    }
]
```

## Additional Resources

* **Helpfiles** can (and _should_) be provided for each of the `Provides.Commands` in the form of `help.<commandname>.md` with the content inside being standard PowerShell help _manpage_ style (`.SYNOPSIS` etc...)

Testing:
```powershell
powershell.exe "&{ Start-Process powershell -Verb runAs -argumentlist '&{ Install-OmegaPackage vim;Pause;}'}"
```