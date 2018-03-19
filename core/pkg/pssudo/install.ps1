

# 2.5 sec
try {
	Import-Module PSSudo -ErrorAction Stop >$null
} catch {
	Write-Warning "PSSudo module failed to load. Either not installed or there was an error."
}