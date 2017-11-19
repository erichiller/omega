# Character Map

Display Raw ASCII in Powershell with:

    23..40|%{[char]$_}

where `23..40` signifies the decimal numbers of the ASCII characters you wish to display

Powershell accepts hex as well in the form of `0x0A` (simply use a prefix of `0x`)

Unicode , UTF-8 in U+ format is Hex.

Example:

0x2190..0x2193|%{[char]$_}
Will give the arrow keys:
← 
↑ 
→ 
↓ 

Ensure any files encoded with UTF8 are read by `Get-Content` with the argument `-encoding UTF8`