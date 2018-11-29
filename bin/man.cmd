
vim -R --cmd "set ft=man nomod nolist" --cmd "map q :q<CR>" --cmd "map <SPACE> <C-D>" --cmd "map b <C-U>" --cmd "nmap K :Man <C-R>=expand(\'<cword>\')<CR><CR>' -" %*