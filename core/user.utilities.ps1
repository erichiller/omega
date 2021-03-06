<#
 Utility Functions
#>


function mv {
	param(
	[Parameter(Mandatory=$True,Position=1,
					HelpMessage="Source/Origin - this is the file or folder/directory to copy")]
	[Alias("src","s")]
	[String] $Source,

	[Parameter(Mandatory=$True,Position=2,
					HelpMessage="Destination - this is the folder/directory which the source will be placed")]
	[Alias("dest","d")]
	[String] $Destination,

	[Parameter(Mandatory=$False,
					HelpMessage="Flag to set whether a directory should be created for the Destination, defaults to yes. This is RECURSIVE.")]
	[switch] $Create,
	[switch] $Force
	
	)
	Process
	{

	If ( -not ( Test-Path -Path $Source) ) {
		Write-Warning "Source '$Source' does not exist"
		return 1
	}

	
	If ( $Destination.EndsWith("\") `
	-and ( -not ( Test-Path -Path $Destination) ) ){
		If ( $Create -eq $false ){
			New-Item $Destination -Type directory -Confirm
		}
		If ( $Create -eq $true ){
			New-Item $Destination -Type directory
		}
	}

	# http://go.microsoft.com/fwlink/?LinkID=113350
	# -Confirm 		Prompts you for confirmation before running the cmdlet.
	# -Credential	Specifies a user account that has permission to perform this action. The default is the current user.
	# -Destination	Specifies the path to the location where the items are being moved. 
	#				The default is the current directory. 
	#				Wildcards are permitted, but the result must specify a single location.
	# 				To rename the item being moved, specify a new name in the value of the Destination parameter.
	# -Exclude		Specifies, as a string array, an item or items that this cmdlet excludes from the operation. 
	#				The value of this parameter qualifies the Path parameter. 
	#				Enter a path element or pattern, such as *.txt. 
	#				Wildcards are permitted.
	# -Filter		Specifies a filter in the provider's format or language. 
	#				The value of this parameter qualifies the Path parameter.
	# 				The syntax of the filter, including the use of wildcards, depends on the provider. 
	#				Filters are more efficient than other parameters, because the provider applies them when the cmdlet gets the objects, rather than having Windows PowerShell filter the objects after they are retrieved.
	# -Force		Forces the command to run without asking for user confirmation.
	# -Include		Specifies, as a string array, an item or items that this cmdlet moves in the operation. The value of this parameter qualifies the Path parameter. Enter a path element or pattern, such as *.txt. Wildcards are permitted.
	# -LiteralPath	Specifies the path to the current location of the items. Unlike the Path parameter, the value of LiteralPath is used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.
	# -PassThru		Returns an object representing the item with which you are working. By default, this cmdlet does not generate any output.
	# -Path
	# -UseTransaction
	# -WhatIf
	#
		If ($Force) {
			Move-Item -Path "$Source" -Destination "$Destination" -Force
		} else {
			Move-Item -Path "$Source" -Destination "$Destination" -Force
		}
	}
}



<#
.SYNOPSIS
Wrapper for GNU grep which allows for setting default parameters. Defaults here are --color=auto and --ignore-case
It accepts pipeline input.
#>
function grep {
	[CmdletBinding()]
	Param(
		[Parameter(
			Mandatory=$False,
			ValueFromPipeline=$True)]
		$pipelineInput,
		[Parameter(Position=0)]
			[string]$needle="--help",
		[parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$Remaining
	)
	Begin {
		$op = $env:PATH
		$env:PATH += ";$(([OmegaConfig]::GetInstance()).basedir)\system\git\usr\bin\"
		Write-Verbose "in grep, searching ${pipelineInput} for ${needle}"
	}
	Process {
		if ( $pipelineInput -eq $Null ){
			grep.exe --ignore-case --color=auto @Remaining $needle
		}
		ForEach ($input in $pipelineInput) {
			Write-Verbose "input item=>${input}"
			$input| Out-String | grep.exe --ignore-case --color=auto @Remaining $needle
		}
	}
	End {
		$env:PATH = $op
	}
}

<#
.SYNOPSIS
Change directory / Location to prior
#>
function back {
	if ( Test-Path variable:Global:Location ){
		$curr = Get-Location
		$Global:Location | Foreach-Object {
			if ( $_ -ne $curr) {
				Set-Location $_
			}
		}
	}
}

<#
.SYNOPSIS
Unix-like killall utility. A simple wrapper for taskkill
#>
function killall {
	Param(
		[Parameter(Mandatory=$True)]
		$ImageName
	)
	# Forcefully kill images containing ImageName
	& taskkill /FI "imagename eq $ImageName*" /F
}

<#
.SYNOPSIS
Wrapper for Get-ChildItem to emulate GNU ls (coreutils) which allows for pipelining and ls style arguments.
.PARAMETER all
In directories show hidden files
Alias `a`
.LINK
http://www.gnu.org/software/coreutils/manual/coreutils.html#ls-invocation
.LINK
http://man7.org/linux/man-pages/man1/ls.1.html
#>
function ls {
	[CmdletBinding()]
	Param(
		[Parameter(
			Mandatory=$False,
			ValueFromPipeline=$True)]
		$pipelineInput,
		[parameter(mandatory=$false, position=1, ValueFromRemainingArguments=$true)]$Remaining
	)
	Begin {
		$op = $env:PATH
		$env:PATH += ";$(([OmegaConfig]::GetInstance()).basedir)\system\git\usr\bin\"
	}
	Process {
        <#
        LS_COLORS was taken from the wsl script - I had to remove the first TERM definitions part for git's dircolors to work.
        test with:
        & "C:\Program Files\WindowsPowerShell\Modules\omega\system\git\usr\bin\ls.exe" -oa --human-readable --classify --color=auto
        #>
		$env:LS_COLORS = 'rs=0:ln=01;37:bd=01;37:pi=01;37:cd=01;37:do=01;37:no=01;37:or=01;37:so=01;37:mi=01;37:fi=01;37:*java=01;35:*c=01;35:*cpp=01;35:*cs=01;35:*js=01;35:*css=01;35:*html=01;35:*zip=01;32:*tar=01;32:*gz=01;32:*rar=01;32:*jar=01;32:*war=01;32:di=01;36:ow=01;36:*txt=01;33:*cfg=01;33:*conf=01;33:*ini=01;33:*csv=01;33:*log=01;33:*config=01;33:*xml=01;33:*yml=01;33:*md=01;33:*markdown=01;33:ex=01;31:*exe=01;31:*bat=01;31:*cmd=01;31:*py=01;31:*pl=01;31:*ps1=01;31:*psm1=01;31:*vbs=01;31:*rb=01;31:*reg=01;31:*.py=32:*.ps1=36:*.python_history=40:';
		$env:LC_COLLATE = 'en_US.utf8'
        $local = $True
        if ( $local -eq $true ){
            # this is windows, we don't need no stinking group information
            $format = "-o"
        } else {
            # not local -> so display EVERYTHING, including group information
            $format = "-l"
        }
		if ( $Null -eq $pipelineInput ){
			ls.exe --all $format --human-readable --group-directories-first --classify --color=auto @Remaining
		}
		ForEach ($input in $pipelineInput) {
			Write-Verbose "input item=>${input}"
			$input| Out-String | ls.exe --all $format --human-readable --group-directories-first --classify --color=auto @Remaining
		}
	}
	End {
		$env:PATH = $op
	}
}

function Get-ArgumentCompleter {
    <#
    .SYNOPSIS
        Get custom argument completers registered in the current session.
    .DESCRIPTION
        Get custom argument completers registered in the current session.
        
        By default Get-ArgumentCompleter lists all of the completers registered in the session.
    .EXAMPLE
        Get-ArgumentCompleter
        
        Get all of the argument completers for PowerShell commands in the current session.
    .EXAMPLE
        Get-ArgumentCompleter -CommandName Invoke-ScriptAnalyzer
        
        Get all of the argument completers used by the Invoke-ScriptAnalyzer command.
    .EXAMPLE
        Get-ArgumentCompleter -Native
        Get all of the argument completers for native commands in the current session.
    #>

    [CmdletBinding(DefaultParameterSetName = 'PSCommand')]
    param (
        # Filter results by command name.
        [String]$CommandName = '*',

        # Filter results by parameter name.
        [Parameter(ParameterSetName = 'PSCommand')]
        [String]$ParameterName = '*',

        # Get argument completers for native commands.
        [Parameter(ParameterSetName = 'Native')]
        [Switch]$Native
    )

    $getExecutionContextFromTLS = [PowerShell].Assembly.GetType('System.Management.Automation.Runspaces.LocalPipeline').GetMethod(
        'GetExecutionContextFromTLS',
        [System.Reflection.BindingFlags]'Static,NonPublic'
    )
    $internalExecutionContext = $getExecutionContextFromTLS.Invoke(
        $null,
        [System.Reflection.BindingFlags]'Static, NonPublic',
        $null,
        $null,
        $psculture
    )

    if ($Native) {
        $argumentCompletersProperty = $internalExecutionContext.GetType().GetProperty(
            'NativeArgumentCompleters',
            [System.Reflection.BindingFlags]'NonPublic, Instance'
        )
    } else {
        $argumentCompletersProperty = $internalExecutionContext.GetType().GetProperty(
            'CustomArgumentCompleters',
            [System.Reflection.BindingFlags]'NonPublic, Instance'
        )
    }

    $argumentCompleters = $argumentCompletersProperty.GetGetMethod($true).Invoke(
        $internalExecutionContext,
        [System.Reflection.BindingFlags]'Instance, NonPublic, GetProperty',
        $null,
        @(),
        $psculture
    )
    foreach ($completer in $argumentCompleters.Keys) {
        $name, $parameter = $completer -split ':'

        if ($name -like $CommandName -and $parameter -like $ParameterName) {
            [PSCustomObject]@{
                CommandName   = $name
                ParameterName = $parameter
                Definition    = $argumentCompleters[$completer]
            }
        }
    }
}






<#
.Synopsis
Exports environment variable from the .env file to the current process.
.Description
This function looks for .env file in the current directoty, if present
it loads the environment variable mentioned in the file to the current process.
.Parameter Path
Path to .env file. Optional, defaults to .env
.Example
 Set-Env
 
 .Example
 #.env file format
 #To Assign value, use "=" operator
 <variable name>=<value>
 #To Prefix value to an existing env variable, use ":=" operator
 <variable name>:=<value>
 #To Suffix value to an existing env variable, use "=:" operator
 <variable name>=:<value>
 #To comment a line, use "#" at the start of the line
 #This is a comment, it will be skipped when parsing
.Example
 # This is function is called by convention in PowerShell
 # Auto exports the env variable at every prompt change
 function prompt {
     Set-PsEnv
 }
.LINK
https://github.com/rajivharris/Set-PsEnv
#>
function Set-Env {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [ValidateScript( {
                if (-Not ($_ | Test-Path) ) {
                    throw "File or folder does not exist"
                }
                if (-Not ($_ | Test-Path -PathType Leaf) ) {
                    throw "The Path argument must be a file. Folder paths are not allowed."
                }
                if ($_ -notmatch "(\.env)") {
                    throw "The file specified in the path argument must be either of type env"
                }
                return $true 
            })]
        [Alias("p")]
        [System.IO.FileInfo]$Path = ".env"
    )

    if ($Global:PreviousDir -eq (Get-Location).Path) {
        Write-Verbose "Set-PsEnv:Skipping same dir"
        return
    } else {
        $Global:PreviousDir = (Get-Location).Path
    }

    #return if no env file
    if (!( Test-Path $Path)) {
        Write-Verbose "No .env file"
        return
    }

    #read the local env file
    $content = Get-Content $Path -ErrorAction Stop
    Write-Verbose "Parsed .env file"

    #load the content to environment
    foreach ($line in $content) {

        if ([string]::IsNullOrWhiteSpace($line)) {
            Write-Verbose "Skipping empty line"
            continue
        }

        #ignore comments
        if ($line.StartsWith("#")) {
            Write-Verbose "Skipping comment: $line"
            continue
        }

        #get the operator
        if ($line -like "*:=*") {
            Write-Verbose "Prefix"
            $kvp = $line -split ":=", 2            
            $key = $kvp[0].Trim()
            $value = "{0};{1}" -f $kvp[1].Trim(), [System.Environment]::GetEnvironmentVariable($key)
        } elseif ($line -like "*=:*") {
            Write-Verbose "Suffix"
            $kvp = $line -split "=:", 2            
            $key = $kvp[0].Trim()
            $value = "{1};{0}" -f $kvp[1].Trim(), [System.Environment]::GetEnvironmentVariable($key)
        } else {
            Write-Verbose "Assign"
            $kvp = $line -split "=", 2            
            $key = $kvp[0].Trim()
            $value = $kvp[1].Trim()
        }

        Write-Verbose "$key=$value"
        
        if ($PSCmdlet.ShouldProcess("environment variable $key", "set value $value")) {            
            [Environment]::SetEnvironmentVariable($key, $value, "Process") | Out-Null
        }
    }
}