@setlocal
@REM /////// Omega \\\\\\\\
@REM * Docker overlay cmd *
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
    @for /f "delims=" %%x in (.env) do ( @set "%%x" )
)

)


@if DEFINED save_docker_host (
	@REM echo Restore DOCKER_HOST
	set DOCKER_HOST=%save_docker_host%
)

@docker-compose.exe %*