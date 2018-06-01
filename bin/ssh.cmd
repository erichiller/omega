@rem Do not use "echo off" to not affect any child calls.
@setlocal



@rem we are going to call the cygwin connector if available.
@IF "%1" == "-v" (
	@echo ****************************************	
	@echo Notice: SSH called via Omega/bin/ssh.cmd
	@echo ****************************************
)

@rem Get the abolute path to the parent directory, which is assumed to be the
@rem Git installation root.
@for /F "delims=" %%I in ("%~dp0..") do @set BaseDir=%%~fI
@set git_install_root=%BaseDir%\system\git
@set PATH=%git_install_root%\usr\bin;%PATH%

@REM Ensure we use a HOME directory that has a preexisting .ssh directory
@if not exist "%HOME%\.ssh\config" @set HOME=%USERPROFILE%
@if not exist "%HOME%\.ssh\config" @set HOME=%HOMEDRIVE%%HOMEPATH%

@REM Reverse config path dividers \ to /
@set "config=%BaseDir%\core\config\omega.ssh.conf"
@set config=%config:\=/%

@rem Spoof terminal environment for git color.
@REM @set TERM=xterm

@rem SSHCallBasic forces basic call
@IF DEFINED SSHCallBasic (
	Goto SSHCallBasic
)

@rem we are going to call the cygwin connector if available.
@IF DEFINED ConEmuBaseDirShort (
	@set CHERE_INVOKING=1
	@%ConEmuBaseDirShort%\conemu-msys2-64.exe -cur_console:p ssh.exe -F "%config%" %*
	@GOTO:eof
)

:SSHCallBasic
@ssh.exe -F "%config%" %*
