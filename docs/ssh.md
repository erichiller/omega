# ssh

SSH included is OpenSSH based, man files can be found here: <https://www.openssh.com/manual.html>

## Debugging Configurations

**Useful Flags to `ssh.exe`**  
**flag**        | **resulting action**
---             | ---
`-v`            | for verbosity  
`-G`            | prints config for attempted host and exits
`-E <logfile>`  | dumps log output to a file rather than to stdout

## Setting the Identity Agent

`SSH_AUTH_SOCK` is the environment variable which by default is set to use KeeAgent a plugin for KeePass. This can be easily overriden either by changing the environment variable, or by setting `IdentityAgent` in `ssh.conf`

## Windows SSH Server

Windows OpenSSH implementation requires `TERM=xterm`

## Omega's `ArgumentCompleter`

Omega has an ArgumentCompleter for ssh when run within Powershell that will complete hostnames that are in `known_hosts`.
For more on `ArgumentCompleter`s see:
- https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.completionresult.-ctor?view=powershellsdk-1.1.0#System_Management_Automation_CompletionResult__ctor_System_String_System_String_System_Management_Automation_CompletionResultType_System_String_
- 