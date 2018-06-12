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
        $local = $True
        if ( $local -eq $true ){
            # this is windows, we don't need no stinking group information
            $format = "-o"
        } else {
            # not local -> so display EVERYTHING, including group information
            $format = "-l"
        }
		if ( $pipelineInput -eq $Null ){
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