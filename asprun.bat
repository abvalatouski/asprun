:main (
    @ echo off

    setlocal
    set batchfile=%0
    shift
    set project=
    set port=5001
    set buildconfig=Debug
    set useswagger=0
    set usebrowser=0

:parsearg
    if "%0" == "/?" (
        call :printusage %batchfile%
        exit /b
    ) else if /i "%0" == "/p" (
        if "%1" == "" (
            echo Expected a port after %0.
            echo See '%batchfile% /?'.
            exit /b 1
        )

        call :isnumber %1
        if errorlevel 1 (
            echo Expected the port to be a number.
            echo See '%batchfile% /?'.
            exit /b 1
        )

        set port=%1
        shift
        shift
        goto :parsearg
    ) else if /i "%0" == "/c" (
        if "%1" == "" (
            echo Expected a build configuration after %0.
            echo See '%batchfile% /?'.
            exit /b 1
        )

        if not "%1" == "Debug" (
            if not "%1" == "Release" (
                echo The build configuration can be either Debug or Release.
                echo See '%batchfile% /?'.
                exit /b 1
            )
        )

        set buildconfig=%1
        shift
        shift
        goto :parsearg
    ) else if /i "%0" == "/s" (
        set useswagger=1
        shift
        goto :parsearg
    ) else if /i "%0" == "/o" (
        set usebrowser=1
        shift
        goto :parsearg
    ) else if not "%0" == "" (
        if not exist "%0" (
            echo The folder does not exist.
            echo See '%batchfile% /?'.
            exit /b 1
        )

        set project=%0
        shift
        goto :parsearg
    )

    if "%project%" == "" (
        echo Name of the project is not defined.
        echo See '%batchfile% /?'.
        exit /b 1
    )

    call :runproject %project% %port% %buildconfig% %useswagger% %usebrowser%
    endlocal
    exit /b %errorlevel%
)

:printusage (
    setlocal
    set batchfile=%~1

    echo Runs the ASP.NET project at the specified port and prints its URL.
    echo The launched process can be stopped via 'taskkill /f /im project.exe',
    echo if its name matches name of the project.
    echo.
    echo     %batchfile% project [/?] [/p port] [/c buildconfig] [/s] [/o]
    echo.
    echo Options
    echo.
    echo     project         Path to the project's folder.
    echo.
    echo.    /?              Show this help message.
    echo                     Other options will be ignored.
    echo.
    echo     /p port         Defaulted to %port%.
    echo.
    echo     /c buildconfig  Either Debug or Release.
    echo                     Defaulted to %buildconfig%.
    echo.
    echo     /s              Print URL of Swagger UI.
    echo.
    echo     /o              Open URL in the browser.
    echo.
    echo     Options can be placed in any order.
    echo     In case of duplication newer options will override older ones.
    echo     Unknown option will be treated as a project path.
    echo.
    echo Example
    echo.
    echo     mkdir WeatherForecast
    echo     dotnet new webapi -o WeatherForecast
    echo     %batchfile% WeatherForecast /s /o
    echo     taskkill /f /im WeatherForecast.exe
    echo.
    echo Source Code
    echo.
    echo     See 'https://github.com/abvalatouski/vsless'.

    endlocal
    exit /b
)

:runproject (
    setlocal
    set project=%~1
    set port=%~2
    set buildconfig=%~3
    set useswagger=%~4
    set usebrowser=%~5

    dotnet build %project% -c %buildconfig% >nul 2>&1
    if errorlevel 1 (
        echo Failed to build. 2>&1
        endlocal
        exit /b 1
    )

    set url=https://localhost:%port%
    start /b dotnet run -p %project% -c %buildconfig% -- --urls=%url% >nul 2>&1
    if errorlevel 1 (
        echo Failed to run. 2>&1
        endlocal
        exit /b 1
    )

    if "%useswagger%" == "1" (
        set url=%url%/swagger
    )
    echo %url%

    if "%usebrowser%" == "1" (
        start %url%
    )

    endlocal
    exit /b
)

:isnumber (
    rem Absence of a whitespace after %~1 is mandatory.
    echo %~1| findstr /r "^[0-9][0-9]*$" >nul
    exit /b %errorlevel%
)
