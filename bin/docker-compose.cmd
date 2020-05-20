@setlocal
@REM /////// Omega \\\\\\\\
@REM * Docker-compose overlay cmd *
@REM *** Eric D Hiller  ***

@REM  if DOCKER_HOST environment variable exists, save it and re-import
@if DEFINED DOCKER_HOST (
	@REM echo DOCKER_HOST environment variable exist
	set save_docker_host=%DOCKER_HOST%

)


@if exist .\.env (
    @for /f "delims=" %%x in (.env) do @( @set "%%x" )
) else (

@if exist %USERPROFILE%\.docker\.env (
    pushd %USERPROFILE%\.docker
    @for /f "delims=" %%x in (.env) do @( @set "%%x" )
    popd
)

)

@if DEFINED save_docker_host (
	@REM echo Restore DOCKER_HOST
	set DOCKER_HOST=%save_docker_host%
)


@if DEFINED DOCKER_TLS if %DOCKER_TLS% EQU 1 (
    echo Using TLS...
    @docker-compose-cli.exe --tlsverify --skip-hostname-check %*
) else (
    @docker-compose-cli.exe %*
)