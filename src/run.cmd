@echo off
setlocal enabledelayedexpansion

REM Function to execute a command in directories containing a Pipfile
:execute_in_dirs
set "command=%~1"
for /r %%d in (.) do (
    if exist "%%d\Pipfile" (
        echo Executing in %%d
        pushd %%d
        call %command%
        popd
    )
)
goto :eof

REM Function to run pytest and generate junit_xml reports against directories containing a Pipfile
:test_and_report_from_dirs
for /r %%d in (.) do (
    if exist "%%d\Pipfile" (
        echo Executing in %%d
        pushd %%d
        call pipenv run python -m pytest --junitxml=..\reports\%%~nd\unit_tests.xml
        popd
    )
)
goto :eof

REM Check if an argument was provided
if "%~1"=="" (
    echo Usage: %0 [lock^|sync^|test^|requirements^|test_and_report]
    echo   lock: Update pipenv lockfile
    echo   sync: Refresh the pipenv environment
    echo   test: Run tests
    echo   requirements: Exports a requirements.txt and runtime-requirements.txt
    echo   test_and_report: Runs tests and generates reports in junit format locally.
    exit /b 1
)

REM Handle the provided argument
if "%~1"=="lock" (
    call :execute_in_dirs "pipenv lock"
) else if "%~1"=="sync" (
    call :execute_in_dirs "pipenv sync"
) else if "%~1"=="test" (
    call :execute_in_dirs "pipenv run pytest"
) else if "%~1"=="requirements" (
    call :execute_in_dirs "pipenv lock -r > requirements.txt"
    call :execute_in_dirs "pipenv lock -r --dev > runtime-requirements.txt"
) else if "%~1"=="test_and_report" (
    call :test_and_report_from_dirs
) else (
    echo Invalid option: %~1
    exit /b 1
)

endlocal
