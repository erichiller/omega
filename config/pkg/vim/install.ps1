function installDir($dir) {
    mkdir -Path $dir -ErrorAction SilentlyContinue >$null 2>&1; if ( -not $? ) { Write-Output "$dir Already exists" } else { Write-Output "Creating directory $dir" }
}


installDir("${env:TEMP}\vimfiles\swap")
installDir("${env:TEMP}\vimfiles\undo")
installDir("${env:TEMP}\vimfiles\cache\neocomplete")
installDir("${env:TEMP}\vimfiles\sessions")

New-Shortcut -targetRelPath "system/vim/gvim.exe" -arguments "-u %LocalAppData%\omega\config\omega.vimrc" -iconRelFile "config\pkg\vim\vim.ico"
Register-App vim "${env:ALLUSERSPROFILE}\Microsoft\Windows\Start Menu\Programs\gvim.lnk"
sed -i "" 's/au BufDelete,BufFilePre \* call \<SID\>BMRemove/au BufUnload,BufDelete,BufFilePre \* call <SID>BMRemove/g' $(Join-Path $env:BaseDir "system/vim/menu.vim")

# set the registry; this is so that gvim can be opened as a registered app. "open with" and still have the proper settings
# $env:VIMINIT = 'source $VIM/../../config/omega.vimrc'
# ????
if ( -not (& setx VIMINIT /m 'source $VIM/../../config/omega.vimrc' ) ) { return $false }

# see :help startup
# see EXTINIT or put $VIM/.vimrc in so that direct links to gvim work

########
# Set File Associations
# vim @ Control Panel\Programs\Default Programs\Set Associations
########

########
# gvim shortcut
# arguments:    -u %LocalAppData%\omega\config\omega.vimrc
# New-Shortcut -targetRelPath "system/vim/gvim.exe" -arguments "-u %LocalAppData%\omega\config\omega.vimrc" -iconRelDir "config\pkg\vim\vim.ico"
# Register-App vim "${env:ALLUSERSPROFILE}\Microsoft\Windows\Start Menu\Programs\gvim.lnk"



# // remove the "" after the -i if NOT on the mac
# sed -i "" 's/au BufDelete,BufFilePre \* call \<SID\>BMRemove/au BufUnload,BufDelete,BufFilePre \* call <SID>BMRemove/g' menuvim.foo

# https://github.com/vim/vim/issues/1522

