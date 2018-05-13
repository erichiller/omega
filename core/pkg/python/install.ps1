$conf = [OmegaConfig]::GetInstance()

# must be ADMIN
if( -not (Test-Admin -warn) ){
	Write-Host -BackgroundColor Red -ForegroundColor White 'Will not continue without Admin rights'
	exit
}

# step 1 -> download the embeddable version
# ftp is here
# https://www.python.org/ftp/python/
# use pattern matching for highest version to yield ->
# https://www.python.org/ftp/python/3.6.1/
# then pattern match to...
# https://www.python.org/ftp/python/3.6.1/python-3.6.1-embed-amd64.zip
# extra packages here 
# https://www.python.org/ftp/python/3.6.1/amd64/

$Package = ( Get-Content (Join-Path $PSScriptRoot "\package.json" ) | ConvertFrom-Json )

Install-PackageFromURL($Package)



# step 2 -> unpack

# from: https://github.com/pypa/pip/issues/4207
######
# after this lib2to3 was broken; because of this
# https://bugs.python.org/issue24960
# I found that if I entirely remove
# python36._pth
# (and) python36._pth~
# I could install pip packages fine.

## THE PYTHON36 ___36___ version part of the filename will have to be derived from the ACTUAL version!

Remove-Item -ErrorAction Ignore -WarningAction SilentlyContinue -Path ( Join-Path ( Join-Path (Join-Path $conf.basedir $conf.sysdir) $Package.name ) "python36._pth" )
Remove-Item -ErrorAction Ignore -WarningAction SilentlyContinue -Path ( Join-Path ( Join-Path (Join-Path $conf.basedir $conf.sysdir) $Package.name ) "python36._pth~" )


# YOU __MAY__ HAVE TO EXTRACT THE python36.zip into /Lib/
# YOU MAY have to copy an older version of lib2to3 and libimport from an installed version into your site-packages
# You DO HAVE TO UNPACK!!!
7z x ( Join-Path ( Join-Path (Join-Path $conf.basedir $conf.sysdir) $Package.name ) "python36.zip" ) "-o$( Join-Path ( Join-Path (Join-Path $conf.basedir $conf.sysdir) $Package.name ) "Lib" )"
Remove-Item -ErrorAction Ignore -WarningAction SilentlyContinue -Path ( Join-Path ( Join-Path (Join-Path $conf.basedir $conf.sysdir) $Package.name ) "python36.zip" )


///// NO ///// DO NOT KEEP THE ZIP ///// DO THIS::::::


Converting the Embedded Python into Full
Embedded Python is using compiled main libraries (apparent by the *.pyc file endings) to convert, remove all of these and use *.py source libraries


Get-ChildItem -Recurse "C:\Users\ehiller\AppData\omega\system\python\Lib\" | Where-Object { $_.LastWriteTime -lt (Get-Date -year 2017 -month 7 -day 16)}

(Get-ChildItem -Recurse "C:\Users\ehiller\AppData\omega\system\python\Lib\" -include "*.pyc" | Where-Object { $_.Directory.Name.CompareTo("__pycache__") -and $_.Directory.Name.CompareTo("Lib") } ).Directory | Get-Unique | Remove-Item -Recurse -Force

Get-ChildItem -Recurse "C:\Users\ehiller\AppData\omega\system\python\Lib\" -include "*.pyc" | Where-Object { -not $_.Directory.Name.CompareTo("Lib") } | Remove-Item -Recurse -Force

Simply grab the `.tgz` from the python ftp and copy over the `/Lib` into the windows _Python_ install directory `/Lib`


//////

########################################
################ STEP 3 ################
########################################
# ! ADD TO PATH - MUST BE ADMIN
########################################
Update-SystemPath ( Join-Path (Join-Path $conf.basedir $conf.sysdir) $Package.name )

########################################
######### step 4 -> Install pip ########
########################################
# https://pip.pypa.io/en/latest/installing/

(new-object System.Net.WebClient).DownloadFile( "https://bootstrap.pypa.io/get-pip.py", ( Join-Path $env:TEMP "get-pip.py" ) )
python $env:TEMP\get-pip.py
# Add Scripts to the $PATH
Update-SystemPath ( Join-Path ( Join-Path (Join-Path $conf.basedir $conf.sysdir) $Package.name ) "Scripts" )





## then the config should be updated
# omega config that is
# the status
# the date
# the version
# 
