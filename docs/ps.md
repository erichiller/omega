# PowerShell - Main help file

Check the version of PowerShell, as well as Windows itself with `$PSVersionTable`

## Clipboard Management

As of PowerShell 5.x `Get-Clipboard` and `Set-Clipboard` commandlets are available.

See here for an [excellent overview of Set-Clipboard](http://www.adminarsenal.com/powershell/set-clipboard/)

## Strings

[Great overview of functions and how to work with Strings](https://technet.microsoft.com/en-us/library/ee692804.aspx)

## Profiles

Default load locations

1. Current User, Current Host
2. Current User, All Hosts
3. All Users, Current Host
4. All Users, All Hosts

[Profile](https://technet.microsoft.com/en-us/library/hh847857.aspx)

## Useful modules

[PoshSSH](https://www.powershellgallery.com/packages/Posh-SSH/1.7.6) - and on [GitHub](https://github.com/darkoperator/Posh-SSH) waiting on for now as I'd rather use OpenSSH

[PowerShell Cookbook repo](https://www.powershellgallery.com/packages/PowerShellCookbook/1.3.6) has a large number of useful examples and scripts 

[PowerShell Scriptable FTP](https://gallery.technet.microsoft.com/scriptcenter/PowerShell-FTP-Client-db6fe0cb)

[Subnet Scan](https://gallery.technet.microsoft.com/scriptcenter/SubNet-Scan-dad0311f)

[Resize Image](https://gallery.technet.microsoft.com/scriptcenter/Resize-Image-File-f6dd4a56/view/Discussions#content)

## Console Status State

Can expore the snap-ins, and aliases present with [console-export](https://technet.microsoft.com/en-us/library/hh849706.aspx)

## Alias commands

See properties of an alias; readonly can not be changed with a simple `Set-Alias <alias> <command>` nor removed with `Remote-Item alias:<alias>`

```powershell
(get-alias curl).Options
```

But you can do:

```powershell
Set-Alias -Name <alias> -Value <command> -Force -Option AllScope
```

For very detailed information on aliases present:

```powershell
[Management.Automation.Runspaces.InitialSessionState].getproperty(
        "BuiltInAliases", [reflection.bindingflags]"NonPublic,Static").getvalue(
             $null, @()) | format-table -auto
```

[source](http://stackoverflow.com/questions/2770526/where-are-the-default-aliases-defined-in-powershell)

## Web Download

`Invoke-Webrequest` seems to rely upon Internet Explorer, so to bypass this requirement use `-UseBasicParsing`

In order to use SSL/TLS connections, you must set SecurityProtocol before using `Invoke-Webrequest`

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```
