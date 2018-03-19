# Providers

PowerShell has the concept of providers which can contain multiple different kinds of information, but are wrapped in a uniform way.

**see `Get-PSProviders`**

```
Name                 Capabilities                                      Drives
----                 ------------                                      ------
Registry             ShouldProcess, Transactions                       {HKLM, HKCU}
Alias                ShouldProcess                                     {Alias}
Environment          ShouldProcess                                     {Env}
FileSystem           Filter, ShouldProcess, Credentials                {C}
Function             ShouldProcess                                     {Function}
Variable             ShouldProcess                                     {Variable}
Certificate          ShouldProcess                                     {Cert}
```
