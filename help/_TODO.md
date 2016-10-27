* rework `init.bat` into a powershell script that uses window=hidden

* use redirection of input to send from source console to elevated console and output of elevated console to source console, see how the `Invoke-ElevatedCommand` works and see:
	- [redirection syntax](http://ss64.com/ps/syntax-redirection.html)
	- [about_redirection](https://technet.microsoft.com/en-us/library/hh847746.aspx)
	- [Tee Object](https://technet.microsoft.com/en-us/library/hh849937.aspx)
	- [tail like method in powershell](http://stackoverflow.com/questions/4426442/unix-tail-equivalent-command-in-windows-powershell)

* `sudo` should load an elevated prompt which has the same prompt/theme/environment as the conemu one.