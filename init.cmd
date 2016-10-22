:: Init Script for alpha
:: launch conemu prompt
:: Eric D Hiller
:: 17 October 2016

:: BaseDir WILL HAVE A TRAILING SLASH ---> ___ \ ___

SET BaseDir=%~dp0
SET BaseDir=%BaseDir:~0,-1%
SET StartExe=%BaseDir%\system\ConEmu\ConEmu64.exe
SET ConfigDir=%BaseDir%\config
SET FontDir=%BaseDir%\system\nerd_hack_font


SET PROGRAMNAME=ConEmu64.exe
tasklist.exe /FI "IMAGENAME eq %PROGRAMNAME%" 2>NUL | find.exe /I /N "%PROGRAMNAME%">NUL
if "%ERRORLEVEL%"=="0" (
	::start %StartExe% -NoSingle -NoUpdate -LoadCfgFile "%ConfigDir%\ConEmu.xml" -SaveCfgFile "%ConfigDir%\ConEmu_detached.xml" -GuiMacro "WindowPosSize(0,0,\"100%%\",\"25%%\"); SetOption(\"Check\",2333,0); WindowMode(9)" -FontDir "%BaseDir%" /Icon "%BaseDir%\icons\omega256.ico" -cmd {Msys2}
	echo foo
) ELSE (
	start %StartExe% /LoadCfgFile "%ConfigDir%\ConEmu.xml" /FontDir "%FontDir%" /Icon "%BaseDir%\icons\omega_256.ico" /run "@%ConfigDir%\powershell.taskfile"
)