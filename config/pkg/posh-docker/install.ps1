
# 1.2 sec
try {
	# https://github.com/samneirinck/posh-docker
	# if(Get-Module posh-docker){ 
	Import-Module posh-docker -ErrorAction Stop >$null
	# }
} catch {
	Write-Warning "Posh-Docker module failed to load. Either not installed or there was an error. Docker autocomplete commands will not function."
	Write-Warning "It can be installed in an admin console with:"
	Write-Warning "Save-Module posh-docker -path $env:basedir\system\psmodules"
	
}