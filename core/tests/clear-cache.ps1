# PowerShell caches classes and modules in %LOCALAPPDATA%

# "%AppData%\Microsoft\Windows\PowerShell\


# extreme
# https://www.sepago.com/blog/2016/03/01/powershell-response-is-slow-after-each-command-on-command-line-get-childitem-start-a
# Remove-ChildItem "%AppData%\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
# Remove-ChildItem "%AppData%\Microsoft\Windows\PowerShell\PSReadline"
Remove-Item "%AppData%\Microsoft\Windows\PowerShell\*"
