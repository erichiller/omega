

# load the functions first
. $PSScriptRoot\..\..\package_install.ps1

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

# inject into python36._pth
# insert line-1 (lib/site-packages)
# uncomment last line (import site)

					# lib/site-packages
					# python36.zip
					# .

					# # Uncomment to run site.main() automatically
					# import site

# from: https://github.com/pypa/pip/issues/4207
######
# after this lib2to3 was broken; because of this
# https://bugs.python.org/issue24960
# I found that if I entirely remove
# python36._pth
# (and) python36._pth~
# I could install pip packages fine.

Remove-Item -ErrorAction Ignore -WarningAction SilentlyContinue -Path ( Join-Path ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir) $Package.name ) "python36._pth" )
Remove-Item -ErrorAction Ignore -WarningAction SilentlyContinue -Path ( Join-Path ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir) $Package.name ) "python36._pth~" ) -ErrorAction Cot

# YOU __MAY__ HAVE TO EXTRACT THE python36.zip into /Lib/

########################################
################ STEP 3 ################
# ADD TO PATH - MUST BE ADMIN
########################################
Update-SystemPath ( Join-Path (Join-Path $Env:Basedir $OMEGA_CONF.sysdir) $Package.name )

########################################
######### step 4 -> Install pip ########
########################################
# https://pip.pypa.io/en/latest/installing/

Start-BitsTransfer -Source "https://bootstrap.pypa.io/get-pip.py" -Destination $env:TEMP
python $env:TEMP\get-pip.py




## then the config should be updated
# omega config that is
# the status
# the date
# the version
# 
