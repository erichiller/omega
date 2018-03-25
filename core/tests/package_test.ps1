

foreach package in package dir



$versionString = "https://github.com/docker/compose/releases/download/1.20.1/docker-compose-Windows-x86_64.exe"
$versionPattern =  ".*download\/(.*)\/docker-compose-Windows-x86_64\.exe$"

Write-Host "VERSION IS $(Select-String -Pattern $versionPattern -InputObject $versionString | ForEach-Object {"$($_.matches.groups[1])"})"



if ( 1 -eq 1 -and 
2 -eq 2 -and 
3 -eq 3 ){
     Write-Output "4"
 }