function installDir($dir) {
    mkdir -Path $dir -ErrorAction SilentlyContinue >$null 2>&1; if ( -not $? ) { Write-Output "$dir Already exists" } else { Write-Output "Creating directory $dir" }
}


installDir("${env:TEMP}\vimfiles\swap")
installDir("${env:TEMP}\vimfiles\undo")
installDir("${env:TEMP}\vimfiles\cache\neocomplete")
installDir("${env:TEMP}\vimfiles\sessions")
