# Environment


## Environment variables

Environment variables can be set temporarily with their in-session `$ENV:varname` variables or permanently with 

```powershell
[Environment]::GetEnvironmentVariable("PSModulePath")
$p += ";C:\Program Files\Fabrikam\Fabrikam8;C:\Program Files\Fabrikam\Fabrikam9"
[Environment]::SetEnvironmentVariable("PSModulePath",$p)
```