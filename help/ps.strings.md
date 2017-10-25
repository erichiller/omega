# String Formatting

<https://kevinmarquette.github.io/2017-01-13-powershell-variable-substitution-in-strings/>

## Inline Variables


```powershell
Write-Output '$($object.dot) for object parameters'
```


## String manipulations

[Convert-String](https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.utility/convert-string) is extremely useful! Demo:

```powershell
"Mu Han", "Jim Hance", "David Ahs", "Kim Akers" | Convert-String -Example "Ed Wilson=Wilson, E."
```

[blog power on technet about Convert-String](https://blogs.technet.microsoft.com/heyscriptingguy/2015/08/17/use-the-powershell-5-convert-string-cmdlet/)