@rem Do not use "echo off" to not affect any child calls.
@setlocal

@rem Get the abolute path to the parent directory, which is assumed to be the
@rem Git installation root.
@for /F "delims=" %%I in ("%~dp0..") do @set msys2_install_root=%%~fI
@set msys2_install_root=%msys2_install_root%\system\msys
@if not exist "%msys2_install_root%" ( echo "msys must be installed" )
@set PATH=%msys2_install_root%\usr\bin;%msys2_install_root%\mingw64\bin;%PATH%

@if not exist "%HOME%" @set HOME=%HOMEDRIVE%%HOMEPATH%
@if not exist "%HOME%" @set HOME=%USERPROFILE%

@telnet.exe %*