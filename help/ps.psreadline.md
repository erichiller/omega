# Powershell - PSReadline


## Available Functions

Tab this to see all the possible functions

```powershell
[Microsoft.PowerShell.PSConsoleReadLine]::
```

## Use `demo mode` for keystroke tracing and HotKey diagnostics

When [Demo mode][demo_mode] is turned on, it displays every key that is typed. This includes the Ctrl and the Alt keys, **but not SHIFT**


Set-PSReadlineKeyHandler -Key ^E -Function EnableDemoMode

 Set-PSReadlineKeyHandler -Key ^D -Function DisableDemoMode  


[demo_mode]: https://blogs.technet.microsoft.com/heyscriptingguy/2014/06/19/useful-shortcuts-from-psreadline-powershell-module/

## Good Examples

https://blogs.technet.microsoft.com/heyscriptingguy/2014/06/20/a-better-powershell-console-with-custom-psreadline-functions/


## Helper functions of use

**Insert into clipboard from the command line** [source][^clipboard_function_source]
```powershell
Set-PSReadlineKeyHandler -Key Ctrl+Shift+v `
   -BriefDescription PasteAsHereString `
   -LongDescription “Paste the clipboard text as a here string” `
   -ScriptBlock 
{
   param($key, $arg)
   Add-Type -Assembly PresentationCore
   if ([System.Windows.Clipboard]::ContainsText()){
      # Get clipboard text – remove trailing spaces, convert rn to n, and remove the final n.
      $text = ([System.Windows.Clipboard]::GetText() -replace “p{Zs}*`r?`n”,”`n”).TrimEnd()
      [PSConsoleUtilities.PSConsoleReadLine]::Insert(“@’`n$text`n’@”)
   } else {
      [PSConsoleUtilities.PSConsoleReadLine]::Ding()
   }
}
```
[^clipboard_function_source]: https://blogs.technet.microsoft.com/heyscriptingguy/2014/06/20/a-better-powershell-console-with-custom-psreadline-functions/

















































```
[Alt]+[PrtScrn] => capture
```
# CaptureScreen is good for blog posts or email showing a transaction
# of what you did when asking for help or demonstrating a technique.
```
Set-PSReadlineKeyHandler -Chord 'Ctrl+D,Ctrl+C' -Function CaptureScreen
```



```powershell
Set-PSReadlineKeyHandler -Key Backspace `
                         -BriefDescription SmartBackspace `
                         -LongDescription "Delete previous character or matching quotes/parens/braces" `
                         -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0)
    {
        $toMatch = $null
        if ($cursor -lt $line.Length)
        {
            switch ($line[$cursor])
            {
                <#case#> '"' { $toMatch = '"'; break }
                <#case#> "'" { $toMatch = "'"; break }
                <#case#> ')' { $toMatch = '('; break }
                <#case#> ']' { $toMatch = '['; break }
                <#case#> '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch)
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
        }
        else
        {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
}

======

# This example will replace any aliases on the command line with the resolved commands.
Set-PSReadlineKeyHandler -Key "Alt+%" `
                         -BriefDescription ExpandAliases `
                         -LongDescription "Replace all aliases with the full command" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $startAdjustment = 0
    foreach ($token in $tokens)
    {
        if ($token.TokenFlags -band [System.Management.Automation.Language.TokenFlags]::CommandName)
        {
            $alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
            if ($alias -ne $null)
            {
                $resolvedCommand = $alias.ResolvedCommandName
                if ($resolvedCommand -ne $null)
                {
                    $extent = $token.Extent
                    $length = $extent.EndOffset - $extent.StartOffset
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                        $extent.StartOffset + $startAdjustment,
                        $length,
                        $resolvedCommand)

                    # Our copy of the tokens won't have been updated, so we need to
                    # adjust by the difference in length
                    $startAdjustment += ($resolvedCommand.Length - $length)
                }
            }
        }
    }
}

=====

# F1 for help on the command line - naturally
Set-PSReadlineKeyHandler -Key F1 `
                         -BriefDescription CommandHelp `
                         -LongDescription "Open the help window for the current command" `
                         -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $commandAst = $ast.FindAll( {
        $node = $args[0]
        $node -is [System.Management.Automation.Language.CommandAst] -and
            $node.Extent.StartOffset -le $cursor -and
            $node.Extent.EndOffset -ge $cursor
        }, $true) | Select-Object -Last 1

    if ($commandAst -ne $null)
    {
        $commandName = $commandAst.GetCommandName()
        if ($commandName -ne $null)
        {
            $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
            if ($command -is [System.Management.Automation.AliasInfo])
            {
                $commandName = $command.ResolvedCommandName
            }

            if ($commandName -ne $null)
            {
                Get-Help $commandName -ShowWindow
            }
        }
    }
}


===== let `cd` add a mark =====




#
# Ctrl+Shift+j then type a key to mark the current directory.
# Ctrj+j then the same key will change back to that directory without
# needing to type cd and won't change the command line.

#
$global:PSReadlineMarks = @{}

Set-PSReadlineKeyHandler -Key Ctrl+Shift+j `
                         -BriefDescription MarkDirectory `
                         -LongDescription "Mark the current directory" `
                         -ScriptBlock {
    param($key, $arg)

    $key = [Console]::ReadKey($true)
    $global:PSReadlineMarks[$key.KeyChar] = $pwd
}

Set-PSReadlineKeyHandler -Key Ctrl+j `
                         -BriefDescription JumpDirectory `
                         -LongDescription "Goto the marked directory" `
                         -ScriptBlock {
    param($key, $arg)

    $key = [Console]::ReadKey()
    $dir = $global:PSReadlineMarks[$key.KeyChar]
    if ($dir)
    {
        cd $dir
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
}

Set-PSReadlineKeyHandler -Key Alt+j `
                         -BriefDescription ShowDirectoryMarks `
                         -LongDescription "Show the currently marked directories" `
                         -ScriptBlock {
    param($key, $arg)

    $global:PSReadlineMarks.GetEnumerator() | % {
        [PSCustomObject]@{Key = $_.Key; Dir = $_.Value} } |
        Format-Table -AutoSize | Out-Host

    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
}


====== what is this? Can it replace my other complicated automation/dynamic parameter? ======

Set-PSReadlineOption -CommandValidationHandler {
    param([System.Management.Automation.Language.CommandAst]$CommandAst)

    switch ($CommandAst.GetCommandName())
    {
        'git' {
            $gitCmd = $CommandAst.CommandElements[1].Extent
            switch ($gitCmd.Text)
            {
                'cmt' {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                        $gitCmd.StartOffset, $gitCmd.EndOffset - $gitCmd.StartOffset, 'commit')
                }
            }
        }
    }
}

======
See:

-Function UndoAll

https://msdn.microsoft.com/en-us/powershell/reference/5.1/psreadline/set-psreadlinekeyhandler

Get-PSReadlineKeyHandler



======

Example #2, for jumping between ‘braces’ (curly brace, square brackets), try:

  Set-PSReadlineKeyHandler -Function GotoBrace -Key Ctrl+B



Origin & some defaults:

https://kurtroggen.wordpress.com/2016/05/22/powershell-cli-syntax-coloring-auto-completion-and-much-more-aka-psreadline/
