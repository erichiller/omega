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
        [bool]
        $lastCommandFailed,
        [string]
        $with
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
    echo "LASTCOMMANDFAILED=$($lastCommandFailed)"##kill
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
$colors.DebugForegroundColor = [ConsoleColor]::Gray
$colors.DebugBackgroundColor = $MASTER_BACKGROUND
$colors.ProgressForegroundColor = [ConsoleColor]::Yellow
$colors.ProgressBackgroundColor = $MASTER_BACKGROUND

$colors.VerboseForegroundColor = [ConsoleColor]::Gray
$colors.VerboseBackgroundColor = $MASTER_BACKGROUND
$colors.WarningForegroundColor = [ConsoleColor]::Yellow
$colors.WarningBackgroundColor = $MASTER_BACKGROUND
$colors.ErrorForegroundColor = [ConsoleColor]::Red
$colors.ErrorBackgroundColor = $MASTER_BACKGROUND

<# END #>

# Clear-Host is required to apply these properties
Clear-Host


$sl = $global:ThemeSettings #local settings

$sl.PromptSymbols.StartSymbol                       = [char]::ConvertFromUtf32(0x03a9)     # greek omega

$sl.PromptSymbols.ElevatedSymbol                    = [char]::ConvertFromUtf32(0xf0e7)
$sl.PromptSymbols.FailedCommandSymbol               = [char]::ConvertFromUtf32(0xf468)

$sl.PromptSymbols.SegmentForwardSymbol              = [char]::ConvertFromUtf32(0xE0B0)
$sl.PromptSymbols.SegmentBackwardSymbol             = [char]::ConvertFromUtf32(0xE0B2)
$sl.PromptSymbols.SegmentSeparatorForwardSymbol     = [char]::ConvertFromUtf32(0xE0B1)
$sl.PromptSymbols.SegmentSeparatorBackwardSymbol    = [char]::ConvertFromUtf32(0xE0B3)

$sl.GitSymbols.BranchSymbol                         = [char]::ConvertFromUtf32(0xf418)
$sl.GitSymbols.BranchUntrackedSymbol                = [char]::ConvertFromUtf32(0x2A2F)
$sl.GitSymbols.BranchIdenticalStatusToSymbol        = [char]::ConvertFromUtf32(0x2261)
$sl.GitSymbols.BranchAheadStatusSymbol              = [char]::ConvertFromUtf32(0xf47c)
$sl.GitSymbols.BranchBehindStatusSymbol             = [char]::ConvertFromUtf32(0xf47d)

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


<#
Set-PSReadlineOption -TokenKind comment -ForegroundColor white
Set-PSReadlineOption -TokenKind none -ForegroundColor white
Set-PSReadlineOption -TokenKind command -ForegroundColor white
Set-PSReadlineOption -TokenKind parameter -ForegroundColor white
Set-PSReadlineOption -TokenKind variable -ForegroundColor white
Set-PSReadlineOption -TokenKind type -ForegroundColor white
Set-PSReadlineOption -TokenKind number -ForegroundColor white
Set-PSReadlineOption -TokenKind string -ForegroundColor white
Set-PSReadlineOption -TokenKind operator -ForegroundColor white
Set-PSReadlineOption -TokenKind member -ForegroundColor white
#>





