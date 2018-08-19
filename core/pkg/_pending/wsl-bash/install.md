powershell -command Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
%windir%\system32\bash.exe



# do the same as send-linuxconfig
Invoke-WebRequest -UseBasicParsing "http://gist.github.com/erichiller/ac3be5b4a562a61b255b0baccb3f2da8/raw/.bashrc" -OutFile "$env:HOME\.bashrc"
Invoke-WebRequest -UseBasicParsing "http://gist.github.com/erichiller/ac3be5b4a562a61b255b0baccb3f2da8/raw/.vimrc" -OutFile "$env:HOME\.vimrc"


# we have colors!
https://gist.githubusercontent.com/sdeaton2/8450564/raw/2c9a8121c1fd4d4eee3dae9f90994705f993629b/colors.sh


# ConEmu Notes on WSL
http://conemu.github.io/en/BashOnWindows.html

He even has a [wslbridge cmd script](https://raw.githubusercontent.com/Maximus5/ConEmu/daily/Release/ConEmu/wsl/wsl-con.cmd)


# Tried

```


cd /d "%ConEmuBaseDir%\wsl" & PATH=%ConEmuBaseDir%;%ConEmuBaseDir%\wsl;%PATH%; & echo [9999H & "%ConEmuBaseDir%\conemu-cyg-64.exe" --verbose --environ --wsl -t "bash --login --verbose --rcfile c:\users\ehiller\.bashrc"

```


cp /mnt/c/Users/ehiller/.bashrc ~/.bashrc