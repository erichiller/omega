

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

# step 3 -> run
# python get-pip.py
# https://pip.pypa.io/en/latest/installing/

## then the config should be updated
# omega config that is
# the status
# the date
# the version
# 
