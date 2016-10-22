


# Binary files
# array of external binaries to be added to the `bin/` folder via hardlink
# remove them and they will be unlinked
# MUST BEGIN WITH \
# Resolve-Path may be useful in the future here
# (Resolve-Path ../bin).Path
# https://technet.microsoft.com/en-us/library/hh849858.aspx
# http://ss64.com/ps/common.html
$OMEGA_BIN_PATH = ( Join-Path $env:BaseDir "\bin\" ) 
<#
$extBinaries = @(
	# openssh https://github.com/PowerShell/Win32-OpenSSH/releases/
	"\system\openssh\ssh.exe"
#	,"\system\openssh\sshd.exe"
#	,"\system\openssh\sshd_config"
	,"\system\openssh\ssh-add.exe"
	,"\system\openssh\ssh-agent.exe"
	,"\system\openssh\ssh-keygen.exe"
#	,"\system\openssh\ssh-lsa.dll"
#	,"\system\openssh\ssh-shellhost.exe"
	,"\system\openssh\sftp.exe"
#	,"\system\openssh\sftp-server.exe"
#	,"\system\openssh\ntrights.exe"
#	,"\system\openssh\install-sshd.ps1"
#	,"\system\openssh\install-sshlsa.ps1"
#	,"\system\openssh\uninstall-sshd.ps1"
#	,"\system\openssh\uninstall-sshlsa.ps1"
#	,"\system\GetGnuWin32\gnuwin32\bin\l2s.exe"
	)
	#>
# see arrays here
# http://ss64.com/ps/syntax-arrays.html
# hash tables also look very useful
# http://ss64.com/ps/syntax-hash-tables.html


$OMEGA_EXT_BINARIES = @(
	"OpenSSH-Win64\ssh.exe"
	)