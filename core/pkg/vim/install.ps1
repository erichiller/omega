
sed -i "" 's/au BufDelete,BufFilePre \* call <SID>BMRemove/au BufDelete,BufUnload,BufFilePre \* call <SID>BMRemove/g' $(Join-Path ([OmegaConfig]::GetInstance()).basedir "system/vim/menu.vim")

# https://github.com/vim/vim-win32-installer/releases/download/v8.1.0290/gvim_8.1.0290_x64.zip
