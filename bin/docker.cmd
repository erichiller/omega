@setlocal
@REM /////// Omega \\\\\\\\
@REM * Docker overlay cmd *
@REM *** Eric D Hiller  ***

@if exist .\.env (
    @for /f "delims=" %%x in (.env) do @( @set "%%x" )
) else (

@if exist %USERPROFILE%\.docker\.env (
    pushd %USERPROFILE%\.docker
    @for /f "delims=" %%x in (.env) do @( @set "%%x" )
    popd
)

)

@docker-cli.exe %*