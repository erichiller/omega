
# IMMEDIATE

* vim
* Install Script

# Soon

* Update opkg script
* `scp` functionality?
	- hack - use ssh like ~ `tar -c dir/ | gzip | gpg -c | ssh user@remote 'dd of=dir.tar.gz.gpg'`
* seperate developers branch with `.vscode` and full `system/` directory (and any **build** scripts if they exist)
* structured environment variables; `mxpBase` , `GIT_CONFIG`, `SSH_AUTH_SOCK`


# Intermediate

* `sudo` should load an elevated prompt which has the same prompt/theme/environment as the conemu one.
* a script fix for `EnvironmentSet` in `ConEmu.xml` so that it doesn't keep setting `%PATH%` with copies of _SCRIPTS_
* ssh key push script mush check for pre-existance of key, and not duplicative add



# Theory

* use redirection of input to send from source console to elevated console and output of elevated console to source console, see how the `Invoke-ElevatedCommand` works and see:
	- [redirection syntax](http://ss64.com/ps/syntax-redirection.html)
	- [about_redirection](https://technet.microsoft.com/en-us/library/hh847746.aspx)
	- [Tee Object](https://technet.microsoft.com/en-us/library/hh849937.aspx)


```powershell
5
Get complete command history
Get-History
same
6
Set maximum remembered commands
$MaximumHistoryCount = integer
$MaximumHistoryCount = 1000
7
Get last n commands from history
Get-History -count n
ghy -Count 25
8
Get last n commands from history containing substring
Get-History | Select-String string | Select -last n
h | sls child | Select -last 25
```
