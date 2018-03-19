
`core/pkg` contains package definitions 



# `pkg.json` definition file values:

`pkg.json` files define the package being installed. Packages can consist of many different types of programs, functions, modules, scripts, etc. Both binary, script, powershell and non. Git , node , conemu are all packages.

Packages definitions are in json format and have serveral *required* fields and several optional ones. Definitions follow:


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

### `Provides.*`

| Field                 | Required? | Description
|---                    |---        |---      
| Provides.Commands     | No        | Commands this package provides and should be registered.
| Provides.Binaries     | No        | Critical Binary (Executables) that other packages may desire/depend on that this package provides


### `System.*`

| Field                 | Required? | Description
|---                    |---        |---      
| SystemPathAdditions   | No        | *Array* of directories to be added to the system `%PATH%`
| SystemEnvironmentVariables | No   | `{"VarName": "VarValue",...}` of variables to be added to the System Environment (`$Env:VarName`)
| SymLinks              | No        | SymLinks to create in the form of `"/internal/path/of/pkg/": "/path/within/system"`

* If either `SystemPathAdditions` or `SystemEnvironmentVariables` is specified `adminRequired` is equated to `$True`.

### `Install.*`

The `GitRelease` package source downloads a *release* from a github repo.

| Field					| Required? | Description
|---					|---        |---       
| AdminRequired         | Yes       | Are administrator privileges required to install this package?
| Source                | Yes       | Type of package, method of installation
| Destination	        | Yes		| destination for the installation, either an exact path string, or the keyword `SystemPath` which installs to `<basedir>\system\<pkgname>`

| org					| Yes		| org name for the organization the package can be found at
| repo					| Yes		| repo of org to download from
| searchTerm			| Yes		| wildcard style search pattern to select appropriate file to download from repo releases
| versionPattern		| Yes		| regex string to extract the version from the downloaded filename



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
            "SearchTerm": "*-64-bit.tar.bz2*",
            "VersionPattern": "^Git-(.*)-64-bit\\.tar\\.bz2$"
        }
    }
]
```

## Additional Resources

* **Helpfiles** can (and _should_) be provides for each of the `Provides.Commands` in the form of `help.<commandname>.md` with the content inside being standard PowerShell help _manpage_ style (`.SYNOPSIS` etc...)