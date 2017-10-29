# PowerShell Scripting

## Approved Verbs

When writing programs, modules, etc... you are supposed to use a set of [approved verbs]

[approved verbs]: https://msdn.microsoft.com/en-us/library/ms714428(v=vs.85).aspx

## Parameters

[Parameters](http://ss64.com/ps/syntax-functions.html)

Defined at the beggining of the function, in a `Param()` block these are listed in the form of `[TYPE]$NAME`:   

- `[switch]$switchname` would define a boolean flag of the form `-switchname` for the function


**Example**   
This example shows how to define whether a parameter is 
- mandatory: `Mandatory=$True`
- what its position must be: `Position=1`
- a help message: `HelpMessage="Source/Origin - this is the file or folder/directory to copy"`
- possible aliases: `[Alias("src","s")]`
- the parameter type: `[String]`
```powershell
#function
	param(
	[Parameter(Mandatory=$True,Position=1,
					HelpMessage="Source/Origin - this is the file or folder/directory to copy")]
	[Alias("src","s")]
	[String] $Source,
#....
```

### Parameter _Attributes_

All attributes are _Optional_

Parameter Name                      | Date Type | Notes
---                                 | ---       | ---
Mandatory                           | Boolean   | If a required parameter is not provided when the cmdlet is invoked, Windows PowerShell prompts the user for a parameter value
ParameterSetName                    | String    | Specifies the parameter set that this cmdlet parameter belongs to
Position                            | Interger  | When you specify positional parameters, limit the number of positional parameters in a parameter set to **less than five**. 
 _(Position continued)_               |           | And, positional parameters do not have to be contiguous. Positions **5, 100, and 250 work the same as positions 0, 1, and 2.**
ValueFromPipeline                   | Boolean   | 
ValueFromPipelineByPropertyName     | Boolean   | 
ValueFromRemainingArguments         | Boolean   | 
HelpMessage                         | String    | This must be a **constant**, thus use `'` single quotes
HelpMessageBaseName                 |           |
HelpMessageResourceId               |           | 


[Official Documentation: Parameter Attribute Declaration](https://msdn.microsoft.com/en-us/library/ms714348(v=vs.85).aspx)


### Remainder Parameters

Remainder parameters are incredibly useful and are akin to `*args` in Python.
Simply declare in `Param()` like:
```powershell
[parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$Remaining
```


### Dynamic Parameters

<http://stackoverflow.com/questions/14844542/powershell-cmdlet-parameter-value-tab-completion>  
<https://foxdeploy.com/2017/01/13/adding-tab-completion-to-your-powershell-functions/>

[TabExpansionPlusPlus](https://github.com/lzybkr/TabExpansionPlusPlus) is an autocompletion extension allowing for easier creation of your own autocomplete functions. An example can be found [here](https://github.com/lzybkr/TabExpansionPlusPlus/blob/master/WindowsExe.ArgumentCompleters.ps1)

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


```powershell
 if ( $PSCmdlet.MyInvocation.BoundParameters["debug"].IsPresent ) {
    echo "Debug is turned on via a switch to this function"
}
if ( $DebugPreference -eq "Continue" ) {
    echo "Debug is turned on in the profiles"
}
```

For `-Debug` , `-Verbose` and other `CommonParamers` see the excellent article [Using Common Parameters](https://nancyhidywilson.wordpress.com/2011/11/21/powershell-using-common-parameters/).

## Stack

Get Caller functions and Stack Traces

```powershell
# powershell stack - get caller function
$command = $((Get-PSCallStack)[1].Command)
```

<https://social.technet.microsoft.com/Forums/windows/en-US/9b8f3677-8416-4685-978a-7daef61d7c52/how-to-get-the-caller-function-name-in-the-called-function-in-ps?forum=winserverpowershell>

### Discover source module of function

```powershell
Get-Item -Path Function:\Get-VCSStatus
```
