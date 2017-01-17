
autocmd BufNew * echom "New File - BufNew"
autocmd BufCreate * echom "New File - BufCreate"
autocmd BufAdd * echom "New File - BufAdd"
autocmd VimEnter *  if !did_filetype() | echom "vimstart" | set filetype=markdown | endif
autocmd BufNewFile * echom "Vimnewfile"
autocmd BufNewFile echom "vimnewfile2"
