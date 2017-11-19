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
@set "config=%BaseDir%\config\omega.ssh.conf"
@set config=%config:\=/%

@rem Spoof terminal environment for git color.
@REM @set TERM=xterm

@ssh.exe -F "%config%" %*