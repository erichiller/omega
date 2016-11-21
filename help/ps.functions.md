# PowerShell Scripting


## Parameters

[Parameters](http://ss64.com/ps/syntax-functions.html)

Defined at the beggining of the function, in a `Param()` block these are listed in the form of `[TYPE]$NAME`:   
- [switch]$switchname` would define a boolean flag of the form `-switchname` for the function

## Data Handling

[Select-String] http://searchwindowsserver.techtarget.com/feature/Filtering-output-from-Windows-PowerShell

[Where-Object](https://technet.microsoft.com/en-us/library/ee177028.aspx)

[Select-Object](http://ss64.com/ps/select-object.html)

[Tee-Object](https://technet.microsoft.com/en-us/library/hh849937.aspx) allows for data to continue down the _Pipeline_ as well as be sent to a _File_ or _Variable_.

## Variables

Variables are Passed by **REFERENCE**, thus

```powershell
$foo = @{ "field_1": "value_1","field_2": "value_2"}
$bar = $foo;
$bar.field_2 = "value_zzz";
# now $foo = @{ "field_1": "value_1","field_2": "value_zzz"}
```

## Error Handling

Errors can be seen with the `$error` variable.

Errors can be redirected, see [Stack Overflow - How to handle errors thrown](http://stackoverflow.com/questions/17420474/how-to-capture-error-messages-thrown-by-a-command)

[Introduction to error handling](https://blogs.msdn.microsoft.com/kebab/2013/06/09/an-introduction-to-error-handling-in-powershell/)