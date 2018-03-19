<#
.SYNOPSIS
Convert PSColor Settings into dir_colors (ls use) for Windows Subsystem for Linux (Bash)
.DESCRIPTION

.NOTES
A color init string consists of one or more of the following numeric codes:
Attribute codes:
00=none 01=bold 04=underscore 05=blink 07=reverse 08=concealed
Text color codes:
30=black 31=red 32=green 33=yellow 34=blue 35=magenta 36=cyan 37=white
Background color codes:
40=black 41=red 42=green 43=yellow 44=blue 45=magenta 46=cyan 47=white
see `dircolors --print-database` for a description of the file format required

256 Colors described in ECMA-48

Test the LSCOLORS final output with
echo ${LS_COLORS} | tr \: \\n | grep exe

.LINK https://linux.die.net/man/5/dir_colors
.LINK https://linux.die.net/man/1/dircolors
.LINK https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
.LINK http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-048.pdf
.LINK https://github.com/seebi/dircolors-solarized/blob/master/README.md#understanding-solarized-colors-in-terminals
.LINK http://wiki.xiph.org/index.php/MIME_Types_and_File_Extensions
.LINK https://github.com/neilpa/cmd-colors-solarized
#>

# dc = dircolor string; string created as we create output
$dc = @"
# Eric  Hiller
# 2017 August 12
# PSColor -> WSL dircolors

COLOR tty

TERM xterm
TERM xterm-16color
TERM xterm-256color
TERM xterm-88color
TERM xterm-color
TERM xterm-debian
TERM color-xterm

# Reset to normal color
RESET 0

`n
"@

# Hash tables are fun
# https://technet.microsoft.com/en-us/library/ee692803.aspx
$ANSI_COLOR_CODE_MAP = @{
	foreground = @{
		black    = "01;30"
		red      = "01;31"
		green    = "01;32"
		yellow   = "01;33"
		brown    = "01;33"
		blue     = "01;34"
		magenta  = "01;35"
		cyan     = "01;36"
		white    = "01;37"
		gray     = "01;37"
		darkgray = "37"
	} 
	background = @{
		black    = "01;40"
		red      = "01;41"
		green    = "01;42"
		yellow   = "01;43"
		brown    = "01;43"
		blue     = "01;44"
		magenta  = "01;45"
		cyan     = "01;46"
		white    = "01;47"
		darkgray = "47"
	}
}

$BASE_DIRCOLORS = @{
	NORMAL         = "" # normal (nonfilename) text
	FILE           = "" # regular file
	DIR            = "" # directory
	LINK           = "" # symbolic link.
	ORPHAN         = "" # orphaned symbolic link (one which points to a nonexistent file)
	MISSING        = "" # a nonexistent file which nevertheless has a symbolic link pointing to it
	FIFO           = "" # pipe
	SOCK           = "" # socket
	DOOR           = "" # door (Solaris 2.5 and later).
	BLK            = "" # block device special file.
	CHR            = "" # character device special file.
	EXEC           = "" # file with the executable attribute set.
	# The following are not in the manpages, but are mentioned here https://github.com/trapd00r/LS_COLORS/blob/master/LS_COLORS
	# CAPABILITY
	# MULTIHARDLINK ? unknown if real
	# SETGID
	# SETUID
	# STICKY
	# STICKY_OTHER_WRITABLE 
}
<# there are also extension specific color settings 
*extension color-sequence - Specifies the color used for any file that ends in extension.
.extension color-sequence - Same as *.extension. Specifies the color used for any file that ends in .extension. Note that the period is included in the extension, which makes it impossible to specify an extension not starting with a period, such as ~ for emacs backup files. This form should be considered obsolete.
#>

<#
System defaults for filetypes not configured by PSColor.
PSColor config always overrides these
In the future this should be moved to themain module config
#>
$FILETYPE_DEFAULT_COLORS = @{
	'*.python_history' = 40
	'*.ps1'            = 36
	'*.py'             = 32
}

# HERE: Enter
# KEY is the PSColor.File.<KEY>
# Value(s) (can be array @()) are the BASE_DIRCOLORS which are the categories dircolors supports (see above)
$CLASS_MAP = @{
	Default    = @()
	Code       = $null
	Compressed = $null
	Directory  = @("DIR","OTHER_WRITABLE") # windows /mnt directories are `ow=` in LS_COLORS
	Hidden     = $null
	Text       = $null
	Executable = @("EXEC")
}

$remaining_defaults = $BASE_DIRCOLORS.Keys
Write-Debug "init:REMAINING_DEFAULTS($($remaining_defaults.getType()))==>$remaining_defaults"

$CLASS_MAP.GetEnumerator() | ForEach-Object { 
	if ( $_.Key -ne "Default" ){ 
		Write-Debug "`n`n++++`n_KEY=$($_.Key),_VALUE=$($_.Value)"
		if ( $_.Value ){
			$test_val = $_.Value
			Write-Debug "does value`n$($_.Value)`ntype($($_.Value.GetType()))-notcontain`n$remaining_defaults`n$($remaining_defaults.getType())"
			$remaining_defaults = $remaining_defaults | Where-Object { $test_val -notcontains $_ }
		}
		Write-Debug "REMAINING_DEFAULTS($($remaining_defaults.getType()))==>$remaining_defaults`n----"
	}
}
$CLASS_MAP.Default = $remaining_defaults

Write-Debug "____END_RESULT (size=$($CLASS_MAP.Default.Count))____`n$($CLASS_MAP.Default)`n`n"


$global:PSColor.File.GetEnumerator() | ForEach-Object { 
	$class = $_.key
	$global:PSColor.File.$class.GetEnumerator() | ForEach-Object {
		$subkey = $_.key
		$value = $_.value
		Write-Debug "$class -> $subkey"
		switch ( $subkey ) {
			"Color" {
				$color = $value
				Write-Debug $("Color is $color [" + $ANSI_COLOR_CODE_MAP.foreground.$($color.ToLower()) + "]")
			}
			"Pattern" {
				$pattern = $value
				Write-Debug "Pattern is $pattern"
			}
		}
	}
	Write-Debug "====$class===="
	# $color ="00;" + 
	$color = $ANSI_COLOR_CODE_MAP.foreground.$color
	$dc += "`n`n#### $class ####`n"
	if ( $CLASS_MAP.$class ){
		$CLASS_MAP.$class.GetEnumerator() | ForEach-Object { 
			Write-Debug "PIPELINE IS:$_"
			$dc += "$($_) $color`n"
		}
	} else {
		$dc += "# PSColor.File.$class has no equivalent mapping in dircolors`n"
	}
	if ($pattern -ne $False -and $pattern -match "\w+"){
		$pattern | select-string -pattern "(\w+)" -AllMatches | ForEach-Object {$_.Matches} | ForEach-Object {
			$singled_pattern = $($_.value)
			$FILETYPE_DEFAULT_COLORS = $FILETYPE_DEFAULT_COLORS | Where-Object { $singled_pattern -notcontains $_ }
			$dc += "*$singled_pattern $color`n"
		}
		$dc += "`n"
		$pattern = $False
	} else {
		$dc += "# PSColor.File.$class has no associated filetypes`n"
	}
	# reset color
	$color = $False
}

$dc += "`n`n#### System Defaults - Override these in PSColor ####`n"
$FILETYPE_DEFAULT_COLORS.GetEnumerator() | ForEach-Object { 
	$dc += "$($_.Key) $($_.Value)`n"
}
	

Write-Debug "--`n`n####### THIS IS DC ########`n"
Write-Debug $dc




Set-Content -Path (Join-Path ([OmegaConfig]::GetInstance()).basedir "\core\wsl_dir_colors" ) -Value $dc

