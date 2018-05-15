# erics header
$codeBin = Split-Path (Resolve-Path $(which code)[0]) -Parent
# Push-Location -Path $codeMain

$tilde_dp0_parent = Split-Path $codebin -Parent

# below is from https://raw.githubusercontent.com/tats-u/vscode/609baa44542f4907f8b35d116deb257f32e4dc43/resources/win32/bin/code.ps1
# %~dp0.. in CMD
# $tilde_dp0_parent = Split-Path -Parent (Split-Path -Parent $MyInvocation.Mycommand.Path)

$env:VSCODE_DEV = ""
$env:ELECTRON_RUN_AS_NODE = "1"
&(Join-Path $tilde_dp0_parent "code.exe") (Join-Path $tilde_dp0_parent "resources" | Join-Path -ChildPath "app" | Join-Path -ChildPath "out" | Join-Path -ChildPath "cli.js") $args

# Pop-Location