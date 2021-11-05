@ echo off

rem Copyright © 2021 Aliaksei Valatouski <abvalatouski@gmail.com>
rem 
rem Permission is hereby granted, free of charge, to any person obtaining a copy
rem of this software and associated documentation files (the “Software”),
rem to deal in the Software without restriction, including without limitation
rem the rights to use, copy, modify, merge, publish, distribute, sublicense,
rem and/or sell copies of the Software, and to permit persons to whom
rem the Software is furnished to do so, subject to the following conditions:
rem 
rem The above copyright notice and this permission notice shall be included
rem in all copies or substantial portions of the Software.
rem 
rem THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
rem OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
rem FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
rem THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
rem LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
rem FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
rem IN THE SOFTWARE.

:main (
    set command=%0
    shift

    set project=
    set port=5001
    set host=localhost
    set buildconfig=Debug
    set useswagger=0
    set usebrowser=0
    set quiet=0
    set wait=0

:parsearg
    if "%0" == "/?" (
        call :usage %command%
        exit /b
    ) else if /i "%0" == "/p" (
        if "%1" == "" (
            call :argerror "Expected a port after %0."
            exit /b 1
        )

        call :isnumber %1
        if errorlevel 1 (
            call :argerror "Expected the port to be a number."
            exit /b 1
        )

        set port=%1
        shift
        shift
        goto :parsearg
    ) else if /i "%0" == "/h" (
        if "%1" == "" (
            call :argerror "Expected a host URL after %0."
            exit /b 1
        )

        set host=%1
        shift
        shift
        goto :parsearg
    ) else if /i "%0" == "/c" (
        if "%1" == "" (
            call :argerror "Expected a build configuration after %0."
            exit /b 1
        )

        if not "%1" == "Debug" (
            if not "%1" == "Release" (
                call :argerror^
                    "The build configuration can be either Debug or Release."
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
    ) else if /i = "%0" == "/q" (
        set quiet=1
        shift
        goto :parsearg
    ) else if /i = "%0" == "/w" (
        set wait=1
        shift
        goto :parsearg
    ) else if not "%0" == "" (
        if not exist "%0" (
            call :argerror "The folder does not exist."
            exit /b 1
        )

        set project=%0
        shift
        goto :parsearg
    )

    if "%project%" == "" (
        call :argerror "Name of the project is not defined."
        exit /b 1
    )

    call :runproject
    exit /b %errorlevel%
)

:usage (
    echo Runs the ASP.NET project at the specified port and prints its URL.
    echo The launched process can be stopped via 'taskkill /f /im project.exe',
    echo if its name matches name of the project.
    echo.
    echo     %~n1 project [/?] [/c buildconfig] [/h hostname^|hostip] [/o]
    echo         [/p port] [/q] [/s] [/w]
    echo.
    echo Options
    echo.
    echo     project              Path to the project's folder.
    echo.
    echo.    /?                   Show this help message.
    echo                          Other options will be ignored.
    echo.
    echo     /c buildconfig       Either Debug or Release.
    echo                          Defaulted to "%buildconfig%".
    echo.
    echo     /h hostname^|hostip   Defaulted to "localhost" ("127.0.0.1").
    echo.
    echo     /o                   Open URL in the browser.
    echo.
    echo     /p port              Defaulted to "%port%".
    echo.
    echo     /q                   Disable URL printing.
    echo.
    echo     /s                   Print URL of Swagger UI.
    echo.
    echo     /w                   Wait pressing any key to stop the project.
    echo.
    echo     Options can be placed in any order.
    echo     In case of duplication newer options will override older ones.
    echo     Unknown option will be treated as a project path.
    echo.
    echo Examples
    echo.
    echo     dotnet new mvc -o SimpleMvc
    echo     %~n1 SimpleMvc /o /q /w
    echo.
    echo     dotnet new webapi -o WeatherForecast
    echo     %~n1 WeatherForecast /o /q /s /w
    echo.
    echo Source Code
    echo.
    echo.    Written by Aliaksei Valatouski ^<abvalatouski@gmail.com^>.
    echo     The source code is licensed under the MIT License.
    echo.
    echo     See 'type %~f1'
    echo     or 'https://github.com/abvalatouski/vsless'.

    exit /b
)

:runproject (
    dotnet build %project% --configuration=%buildconfig% >nul 2>&1
    if errorlevel 1 (
        echo Failed to build. >&2
        exit /b 1
    )

    set url=https://%host%:%port%
    start /b dotnet run^
        --project=%project%^
        --configuration=%buildconfig%^
        --no-build^
        --^
        --urls=%url%^
        --Logging:LogLevel:Microsoft.Hosting.Lifetime=None
    rem That thing may handle errors from both `dotnet` and the application.
    if errorlevel 1 (
        echo Failed to run. >&2
        exit /b 1
    )

    rem Waiting the application to startup.
    timeout 1 >nul

    if "%useswagger%" == "1" (
        set url=%url%/swagger
    )

    if "%quiet%" == "0" (
        echo %url%
    )

    if "%usebrowser%" == "1" (
        start %url%
    )

    if "%wait%" == "1" (
        echo Press any key to stop the execution...
        pause >nul
        for /f %%f in ('dir %project%\bin /b /s ^| findstr ".exe"') do (
            taskkill /f /im %%~nf.exe >nul
        )
    )

    exit /b
)

:argerror (
    echo %~1 >&2
    echo See '%batchfile% /? ^| more'. >&2
    exit /b 0
)

:isnumber (
    rem Absence of a whitespace after %~1 is mandatory.
    echo %~1| findstr /r "^[0-9][0-9]*$" >nul
    exit /b %errorlevel%
)
