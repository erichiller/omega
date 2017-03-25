#requires -Version 2 -Modules posh-git

<#

***** omega *****
default theme for omega command suite
*****
Eric Hiller
16 October 2016
*****

#>

function Write-Theme
{
    param(
        [bool]$lastCommandFailed,
        [string]$with
    )

    $lastColor = $sl.Colors.PromptBackgroundColor


    <##### START CLOCK ######>

    # Create the right block first, set to 1 line up on the right
    Save-CursorPosition
    $date = Get-Date -UFormat %Y-%b-%d
    $timeStamp = Get-Date -UFormat %R 

    $leftText = "$($sl.PromptSymbols.SegmentBackwardSymbol) $date $($sl.PromptSymbols.SegmentBackwardSymbol) $timeStamp "
    Set-CursorUp -lines 1
    Set-CursorForRightBlockWrite -textLength  ($leftText.Length - 1)  

    Write-Prompt -Object "$($sl.PromptSymbols.SegmentBackwardSymbol)" -ForegroundColor $sl.Colors.ClockBackgroundColor 
    Write-Prompt " $date " -ForegroundColor $sl.Colors.ClockTextColor -BackgroundColor $sl.Colors.ClockBackgroundColor
    Write-Prompt "$($sl.PromptSymbols.SegmentBackwardSymbol)" -ForegroundColor $sl.Colors.ClockForegroundColor -BackgroundColor $sl.Colors.ClockBackgroundColor
    Write-Prompt " $timeStamp " -ForegroundColor $sl.Colors.ClockTextColor -BackgroundColor $sl.Colors.ClockForegroundColor 
    
    <##### END CLOCK ######>

    Pop-CursorPosition

    # Write the prompt
    Write-Prompt -Object " $($sl.PromptSymbols.StartSymbol) " -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor

    #check the last command state and indicate if failed
    If ($lastCommandFailed)
    {
        Write-Prompt -Object "$($sl.PromptSymbols.FailedCommandSymbol) " -ForegroundColor $sl.Colors.CommandFailedIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    # Check for elevated prompt
    If (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
    {
        Write-Prompt -Object "$($sl.PromptSymbols.ElevatedSymbol) " -ForegroundColor $sl.Colors.AdminIconForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    }

    #$user = [Environment]::UserName
    #$computer = $env:computername
    $path = Get-FullPath -dir $pwd
    
    #Write-Prompt -Object "$user " -ForegroundColor $sl.Colors.SessionInfoForegroundColor -BackgroundColor $sl.Colors.SessionInfoBackgroundColor
    Write-Prompt -Object "$($sl.PromptSymbols.SegmentForwardSymbol) " -ForegroundColor $sl.Colors.SessionInfoBackgroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor

    # Writes the drive portion
    Write-Prompt -Object "$path " -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    
    $status = Get-VCSStatus
    if ($status)
    {
        $themeInfo = Get-VcsInfo -status ($status)
        $lastColor = $themeInfo.BackgroundColor
        Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $sl.Colors.PromptBackgroundColor -BackgroundColor $lastColor
        Write-Prompt -Object " $($themeInfo.VcInfo) " -BackgroundColor $lastColor -ForegroundColor $sl.Colors.GitForegroundColor      
    }

    if ($with)
    {
        Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -ForegroundColor $lastColor -BackgroundColor $sl.Colors.WithBackgroundColor
        Write-Prompt -Object " $($with.ToUpper()) " -BackgroundColor $sl.Colors.WithBackgroundColor -ForegroundColor $sl.Colors.WithForegroundColor
        $lastColor = $sl.Colors.WithBackgroundColor
    }

    # Writes the postfix to the prompt
    Write-Prompt -Object $sl.PromptSymbols.SegmentForwardSymbol -BackgroundColor $host.UI.RawUI.BackgroundColor -ForegroundColor $lastColor

    # Set ConEmu Tab Title (if in ConEmu)
    $host.ui.RawUI.WindowTitle = $(Get-PrettyPath -dir $pwd)
    
    #Show-Glyphs
}

<#
function Show-Glyphs {
    for($i=0xf400;$i -le 0xF498;$i++){
        Write-Prompt -Object " $([char]::ConvertFromUtf32($i)) " -ForegroundColor $sl.Colors.PromptForegroundColor -BackgroundColor $sl.Colors.PromptBackgroundColor
    }

    Write-Prompt -Object "     $([char]::ConvertFromUtf32(0xf417)) " -ForegroundColor $sl.Colors.PromptForegroundColor
    Write-Prompt -Object " $([char]::ConvertFromUtf32(0xf41b))     " -ForegroundColor $sl.Colors.PromptForegroundColor

    Write-Prompt -Object " $($sl.PromptSymbols.FailedCommandSymbol) " -ForegroundColor $sl.Colors.PromptForegroundColor
    Write-Prompt -Object " $([char]::ConvertFromUtf32(0xf0a2)) " -ForegroundColor $sl.Colors.PromptForegroundColor 
    
    Write-Prompt -Object " $([char]::ConvertFromUtf32(0x2A2F)) " -ForegroundColor $sl.Colors.PromptForegroundColor 
    
    Write-Prompt -Object " Untracked=$($sl.GitSymbols.BranchUntrackedSymbol) " -ForegroundColor $sl.Colors.PromptForegroundColor
    Write-Prompt -Object " $([char]::ConvertFromUtf32(0xf070)) " -ForegroundColor $sl.Colors.PromptForegroundColor 
    Write-Prompt -Object " Identical=$($sl.GitSymbols.BranchIdenticalStatusToSymbol) " -ForegroundColor $sl.Colors.PromptForegroundColor 
    #Write-Prompt -Object " $([char]::ConvertFromUtf32(0xf42e)) " -ForegroundColor $sl.Colors.PromptForegroundColor 
    Write-Prompt -Object " $([char]::ConvertFromUtf32(0xf07e)) " -ForegroundColor $sl.Colors.PromptForegroundColor 
    Write-Prompt -Object " Ahead=$($sl.GitSymbols.BranchAheadStatusSymbol) " -ForegroundColor $sl.Colors.PromptForegroundColor 
    Write-Prompt -Object " $([char]::ConvertFromUtf32(0xf47c)) " -ForegroundColor $sl.Colors.PromptForegroundColor 
    Write-Prompt -Object " Behind=$($sl.GitSymbols.BranchBehindStatusSymbol) " -ForegroundColor $sl.Colors.PromptForegroundColor
    Write-Prompt -Object " $([char]::ConvertFromUtf32(0xf47d)) " -ForegroundColor $sl.Colors.PromptForegroundColor 
}
#>


$MASTER_BACKGROUND = [ConsoleColor]::Black

$console = $host.UI.RawUI
# defines the default for ALL text
$console.ForegroundColor = [ConsoleColor]::Green
# defines the default background ONCE Clear-Host has been executed, else ConEmu's background color applies. 
$console.BackgroundColor = $MASTER_BACKGROUND


<# START More thorough settings for info messages 
    => http://windowsitpro.com/powershell/powershell-basics-console-configuration
    => https://technet.microsoft.com/en-us/library/ee692799.aspx 
    view settings with
    (Get-Host).PrivateData
    #>

$colors = $host.PrivateData
$colors.DebugForegroundColor = [ConsoleColor]::Blue
$colors.DebugBackgroundColor = $MASTER_BACKGROUND
$colors.ProgressForegroundColor = [ConsoleColor]::Yellow
$colors.ProgressBackgroundColor = $MASTER_BACKGROUND

$colors.VerboseForegroundColor = [ConsoleColor]::Gray
$colors.VerboseBackgroundColor = $MASTER_BACKGROUND
$colors.WarningForegroundColor = [ConsoleColor]::Yellow
$colors.WarningBackgroundColor = $MASTER_BACKGROUND

# Most message colors can be set
# https://technet.microsoft.com/en-us/library/ee692799.aspx
# Write-Information can not
# https://blogs.technet.microsoft.com/heyscriptingguy/2015/07/04/weekend-scripter-welcome-to-the-powershell-information-stream/
$colors.ErrorForegroundColor = [ConsoleColor]::Red
$colors.ErrorBackgroundColor = $MASTER_BACKGROUND

<# END #>

# Clear-Host is required to apply these properties
#Clear-Host


$sl = $global:ThemeSettings #local settings

$sl.PromptSymbols.StartSymbol                       = [char]::ConvertFromUtf32(0x03a9)     # greek omega , b1 is alpha

$sl.PromptSymbols.ElevatedSymbol                    = [char]::ConvertFromUtf32(0x26A1)      # Octicons "zap"
$sl.PromptSymbols.FailedCommandSymbol               = [char]::ConvertFromUtf32(0xf081)      # Octicons "x"

$sl.PromptSymbols.SegmentForwardSymbol              = [char]::ConvertFromUtf32(0xE0B0)
$sl.PromptSymbols.SegmentBackwardSymbol             = [char]::ConvertFromUtf32(0xE0B2)
$sl.PromptSymbols.SegmentSeparatorForwardSymbol     = [char]::ConvertFromUtf32(0xE0B1)
$sl.PromptSymbols.SegmentSeparatorBackwardSymbol    = [char]::ConvertFromUtf32(0xE0B3)

$sl.GitSymbols.BranchSymbol                         = [char]::ConvertFromUtf32(0xf020)      # Octicons "git-branch"
$sl.GitSymbols.BranchUntrackedSymbol                = [char]::ConvertFromUtf32(0x2260)      # Not Equal to symbol
$sl.GitSymbols.BranchIdenticalStatusToSymbol        = [char]::ConvertFromUtf32(0x2261)
$sl.GitSymbols.BranchAheadStatusSymbol              = [char]::ConvertFromUtf32(0xf0a2)      # Octicons "chrevron-up"
$sl.GitSymbols.BranchBehindStatusSymbol             = [char]::ConvertFromUtf32(0xf0a3)      # Octicons "chevron-down"

#$sl.Colors.SessionInfoBackgroundColor       = [ConsoleColor]::DarkRed
$sl.Colors.SessionInfoBackgroundColor       = [ConsoleColor]::DarkGreen
    
$sl.Colors.SessionInfoForegroundColor       = [ConsoleColor]::White
$sl.Colors.CommandFailedIconForegroundColor = [ConsoleColor]::DarkRed
$sl.Colors.AdminIconForegroundColor         = [ConsoleColor]::DarkYellow

$sl.Colors.DriveForegroundColor             = [ConsoleColor]::DarkBlue


$sl.Colors.GitDefaultColor                  = [ConsoleColor]::DarkGreen
$sl.Colors.GitLocalChangesColor             = [ConsoleColor]::Green
$sl.Colors.GitNoLocalChangesAndAheadColor   = [ConsoleColor]::DarkMagenta
#$sl.Colors.GitForegroundColor = [ConsoleColor]::Black
$sl.Colors.GitForegroundColor = [ConsoleColor]::Magenta


$sl.Colors.WithForegroundColor = [ConsoleColor]::Gray
$sl.Colors.WithBackgroundColor = [ConsoleColor]::DarkRed # DISABLE 

$sl.Colors.PromptForegroundColor = [ConsoleColor]::White
$sl.Colors.PromptBackgroundColor = [ConsoleColor]::DarkBlue
$sl.Colors.PromptHighlightColor = [ConsoleColor]::DarkRed ###??? DISABLE ???
$sl.Colors.PromptSymbolColor = [ConsoleColor]::White

$sl.Colors.ClockBackgroundColor = [ConsoleColor]::DarkBlue
$sl.Colors.ClockForegroundColor = [ConsoleColor]::DarkYellow
$sl.Colors.ClockTextColor       = [ConsoleColor]::White

# add some newer languages --> typescript, jsx, tsx, golang
# change the color to goldy
$global:PSColor.File.Code = @{ Color = 'DarkYellow'; Pattern = '\.(java|c|cpp|cs|js|ts|go|jsx|tsx|css|html)$' }
 
<###########################################
 ##### PSReadline options ##################
 ###########################################

Options can be seen with the command:
    Get-PSReadlineOption

See: https://technet.microsoft.com/en-us/library/mt560335.aspx

Can use this to create syntax highlighting


# Defaults
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadlineOption -TokenKind Command -ForegroundColor DarkBlue
Set-PSReadlineOption -TokenKind Parameter -ForegroundColor Yellow
#>

# see possible options under "Tab Complete" here: 
# https://github.com/lzybkr/PSReadLine/blob/master/PSReadLine/en-US/about_PSReadline.help.txt
Set-PSReadlineKeyHandler -Key Tab -Function Complete
# Note: Ctrl + Space already performs MenuComplete
# TabCompleteNext , Complete , MenuComplete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward



Set-PSReadlineOption -TokenKind comment -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind none -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind command -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind parameter -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind variable -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind type -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind number -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind string -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind operator -BackgroundColor $MASTER_BACKGROUND
Set-PSReadlineOption -TokenKind member -BackgroundColor $MASTER_BACKGROUND






#################################################################################
# Eric D Hiller                                                                 #
# 2017 March 25                                                                 #
#################################################################################
# Smart Insert, Bracing functions                                               #
#################################################################################
# ORIGINALLY FROM PSREADLINE , modified because some was anti-user              #
#################################################################################
# The next four key handlers are designed to make entering matched quotes
# parens, and braces a nicer experience.  I'd like to include functions
# in the module that do this, but this implementation still isn't as smart
# as ReSharper, so I'm just providing it as a sample.
################################################################################

Set-PSReadlineKeyHandler -Key '"',"'" `
                         -BriefDescription SmartInsertQuote `
                         -LongDescription "Insert paired quotes if not already on a quote" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $quoteNumber = Select-String -InputObject $line -Pattern $key.KeyChar -AllMatches
    # insert a SINGLE quote if 
    #   1) there is an ODD number of quotes on the line currently
    #   2) There is a character to the immediate right of the cursor
    if (($quoteNumber.Matches.Count % 2 -eq 1) -or (-not [string]::IsNullOrWhiteSpace($line[$cursor + 1]))) {
        # If there is an uneven amount of quotes, put just one quote (modulus 1 / Remainder)
        [Microsoft.PowerShell.PSConsoleReadline]::Insert($key.KeyChar)
    }
    # elseif ($line[$cursor + 1]) {
        # Just move the cursor
        # [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    # }
    else {
        # Insert matching quotes, move cursor to be in between the quotes
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)" * 2)
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
    }
}

Set-PSReadlineKeyHandler -Key '(','{','[' `
                         -BriefDescription InsertPairedBraces `
                         -LongDescription "Insert matching braces" `
                         -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar)
    {
        <#case#> '(' { [char]')'; break }
        <#case#> '{' { [char]'}'; break }
        <#case#> '[' { [char]']'; break }
    }
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    #"LINE=$line;CURSOR=$cursor;CHAR=$line[$cursor];-1=" + $line[$cursor-1] + ";+1=" + $line[$cursor+1] >> diagnostic_log.txt

    # insert the entered character itself
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
    # If there isn't another character to the immediate right, insert matching braces
    if ([string]::IsNullOrWhiteSpace($line[$cursor + 1])) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$closeChar")
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
    }      
}

# Set-PSReadlineKeyHandler -Key ')',']','}' `
#                          -BriefDescription SmartCloseBraces `
#                          -LongDescription "Insert closing brace or skip" `
#                          -ScriptBlock {
#     param($key, $arg)

#     $line = $null
#     $cursor = $null
#     [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

#     if ($line[$cursor] -eq $key.KeyChar)
#     {
#         [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
#     }
#     else
#     {
#         [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
#     }
# }

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadlineKeyHandler -Key 'Alt+(' `
                         -BriefDescription ParenthesizeSelection `
                         -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
                         -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1)
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    }
    else
    {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}
