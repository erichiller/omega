@rem Do not use "echo off" to not affect any child calls.
@setlocal

@rem Get the abolute path to the parent directory, which is assumed to be the
@rem Git installation root.
@for /F "delims=" %%I in ("%~dp0..") do @set BaseDir=%%~fI
@set git_install_root=%BaseDir%\system\git
@set PATH=%git_install_root%\usr\bin;%PATH%

@if not exist "%HOME%" @set HOME=%HOMEDRIVE%%HOMEPATH%
@if not exist "%HOME%" @set HOME=%USERPROFILE%

@REM Reverse config path dividers \ to /
@set "config=%BaseDir%\core\config\omega.ssh.conf"
@set config=%config:\=/%

@rem Spoof terminal environment for git color.
@REM @set TERM=xterm

@rem we are going to call the cygwin connector if available.
@IF DEFINED ConEmuBaseDirShort (
	@set CHERE_INVOKING=1
	@%ConEmuBaseDirShort%\conemu-msys2-64.exe -cur_console:p ssh.exe -F "%config%" %*
) else (	
	@ssh.exe -F "%config%" %*
)