"
powershell -NoExit -command "& { $DebugPreference=\"continue\";$VerbosePreference=\"continue\";$start=(Get-Date -uformat %s);import-module omega;$end=(Get-Date -uformat %s);Write-Host \"took $($end - $start) seconds to run\"; }"
"