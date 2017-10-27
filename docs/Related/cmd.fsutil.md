# fsutil

For fsutil information see technet article:

* <https://technet.microsoft.com/en-ca/library/cc753059.aspx>
* <http://stackoverflow.com/questions/894430/powershell-hard-and-soft-links>

Examples:

```powershell
fsutil hardlink create NEW EXISTING
fsutil hardlink create C:\cmder\bin\ssh.exe C:\cmder\system\openssh\ssh.exe

fsutil hardlink list MyFileName.txt
fsutil hardlink list C:\cmder\system\openssh\ssh.exe
```