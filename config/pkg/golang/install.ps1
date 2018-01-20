# go is going to have to be a module too
try {
	$env:GOPATH = Resolve-Path $OMEGA_CONF.gopath
	if( ( Test-Path $env:GOPATH ) `
		-and ( Test-Path ( Join-Path $env:GOPATH "bin" ) ) `
		-and ( Test-Path ( Join-Path $env:GOPATH "pkg" ) ) `
		-and ( Test-Path ( Join-Path $env:GOPATH "src" ) ) `
	){
		Add-DirToPath ( Join-Path $env:GOPATH "bin" )
	} else {
		# if GOROOT wasn't found, remove the environment variable;
		# this keeps the environment clean of garbage
		Write-Warning "${$env:GOPATH} (GOPATH) is not present"
		Remove-Item Env:\GOPATH
	}
	$env:GOROOT = Join-Path $env:BaseDir "\system\go\"
	if( ( Test-Path $env:GOROOT ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "bin" ) ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "pkg" ) ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "src" ) ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "misc" ) ) `
		-and ( Test-Path ( Join-Path $env:GOROOT "lib" ) ) `
	){
		Add-DirToPath ( Join-Path $env:GOROOT "bin" )
	} else {
		# if GOROOT wasn't found, remove the environment variable;
		# this keeps the environment clean of garbage
		Write-Warning "${$env:GOROOT} (GOROOT) is not present"
		Remove-Item Env:\GOROOT
	}

	# get msys2 , msys64 here: https://sourceforge.net/projects/msys2/files/Base/x86_64/
	$unixesq = Join-Path $env:BaseDir $OMEGA_CONF.unixesq
	if( ( Test-Path $unixesq ) `
		-and ( Test-Path ( Join-Path $unixesq "mingw64\bin" ) ) `
		-and ( Test-Path ( Join-Path $unixesq "mingw64\bin\gcc.exe" ) ) `
	){

	}
} catch {
	Write-Warning "GO not found. Either not installed or there was an error. Go and related commands will be unavailable."
}