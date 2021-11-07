@ echo off

rem Copyright © 2021 Aliaksei Valatouski ^<abvalatouski@gmail.com^>
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
    setlocal enabledelayedexpansion
    goto :parse-options
:options-were-parsed
    call :run-project
    endlocal
    exit /b !errorlevel!
)

:usage (
    echo Runs the ASP.NET project at the specified port and prints its URL.
    echo The launched process can be stopped via 'taskkill /f /im project.exe',
    echo if its name matches name of the project.
    echo.
    echo     %~n1 project [/?] [//] [/c build-configuration] [/h host] [/i] [/o]
    echo         [/ port] [/q] [/s] [/w]
    echo.
    echo Options
    echo.
    echo     project                 Path to the project's folder.
    echo.
    echo.    /?                      Show this help message.
    echo                             Other options will be ignored.
    echo.
    echo     //                      Update the command, fetching its source code
    echo                             from the Internet.
    echo                             Other options will be ignored.
    echo.
    echo     /c build-configuration  Either Debug or Release.
    echo                             Defaulted to "%build-configuration%".
    echo.
    echo     /h host                 Can be either host name, host IP, or '%%n',
    echo                             where number 'n' refers to nth IPv4 from 'ipconfig'.
    echo                             In case of negative 'n' IPs will be peaked,
    echo                             starting from the end.
    echo                             See 'ipconfig ^| findstr "IPv4" ^| findstr /n ".*"'.
    echo                             Defaulted to "localhost" (same as "127.0.0.1").
    echo.
    echo     /i                      Use HTTP instead of HTTPS.
    echo                             ===================
    echo                             Mnemonic: insecure.
    echo.
    echo     /o                      Open URL in the browser.
    echo.
    echo     /p port                 Defaulted to "%port%".
    echo.
    echo     /q                      Disable URL printing.
    echo                             ================
    echo                             Mnemonic: quiet.
    echo.
    echo     /s                      Print URL of Swagger UI.
    echo.
    echo     /w                      Wait pressing any key to stop the project.
    echo.
    echo     Options can be placed in any order.
    echo     In case of duplication newer options will override older ones.
    echo     Unknown option will be treated as a project path.
    echo.
    echo Examples
    echo.
    echo     ^> dotnet new mvc -o SimpleMvc
    echo     ^> %~n1 SimpleMvc /o /q
    echo     ^> taskkill /f /im SimpleMvc.exe
    echo.
    echo     ^> dotnet new webapi -o WeatherForecast
    echo     ^> %~n1 WeatherForecast /o /q /s /w
    echo     Press any key to stop the execution...
    echo     ^>
    echo.
    echo     ^> dotnet new webapi -o WeatherForecast
    echo     ^> rem See 'ipconfig' to find IP of your local network.
    echo     ^> %~n1 WeatherForecast /h %%-1 /i /p 80 /s
    echo     http://192.168.x.x:80/swagger
    echo     ^> rem Connect another device to the local network an try to open that
    echo     ^> rem link.
    echo     ^> taskkill /f /im WeatherForecast.exe
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

:parse-options (
    set command=%~f0
    shift

    set project=
    set build-configuration=Debug
    set host=localhost
    set protocol=https
    set use-browser=0
    set port=5001
    set quiet=0
    set use-swagger-ui=0
    set wait=0

:parse-option
    if "%0" == "/?" (
        call :usage %command%
        endlocal
        exit /b
    ) else if "%0" == "//" (
        call :update-self %command%
        endlocal
        exit /b !errorlevel!
    ) else if /i "%0" == "/c" (
        if "%1" == "" (
            call :option-error^
                %command%^
                "Expected a build configuration after %0."
            endlocal
            exit /b 1
        )

        if not "%1" == "Debug" (
            if not "%1" == "Release" (
                call :option-error^
                    %command%^
                    "The build configuration can be either Debug or Release."
                endlocal
                exit /b 1
            )
        )

        set build-configuration=%1
        shift
        shift
        goto :parse-option
    ) else if /i "%0" == "/h" (
        if "%1" == "" (
            call :option-error^
                %command%^
                "Expected a host after %0."
            endlocal
            exit /b 1
        )

        set host=%1
        if "!host:~0,1!" == "%%" (
            if not "!host:~1,1!" == "-" (
                set reversed-search=0
                call :lookup-ip-config !reversed-search! "!host:~1!"
            ) else (
                set reversed-search=1
                call :lookup-ip-config !reversed-search! "!host:~2!"
            )

            if not "!errorlevel!" == "0" (
                >&2 echo 'ipconfig' does not provide an IPv4 with number '!host:~1!'.
                >&2 echo See 'ipconfig ^| findstr "IPv4" ^| findstr /n ".*"'.
                endlocal
                exit /b 1
            )
        )

        echo !host!
        exit /b 1

        shift
        shift
        goto :parse-option
    ) else if /i = "%0" == "/i" (
        set protocol=http
        shift
        goto :parse-option
    ) else if /i "%0" == "/o" (
        set use-browser=1
        shift
        goto :parse-option
    ) else if /i "%0" == "/p" (
        if "%1" == "" (
            call :option-error^
                %command%^
                "Expected a port after %0."
            endlocal
            exit /b 1
        )

        set port=%1
        shift
        shift
        goto :parse-option
    ) else if /i = "%0" == "/q" (
        set quiet=1
        shift
        goto :parse-option
    ) else if /i "%0" == "/s" (
        set use-swagger-ui=1
        shift
        goto :parse-option
    ) else if /i = "%0" == "/w" (
        set wait=1
        shift
        goto :parse-option
    ) else if not "%0" == "" (
        if not exist "%0" (
            call :option-error^
                %command%^
                "The project folder '%0' does not exist."
            endlocal
            exit /b 1
        )

        set project=%0
        shift
        goto :parse-option
    )

    if "%project%" == "" (
        call :option-error^
            %command%^
            "Name of the project is not defined."
        endlocal
        exit /b 1
    )

    goto :options-were-parsed
)

:option-error (
    >&2 echo %~2
    >&2 echo See '%~n1 /? ^| more'.
    exit /b
)

:update-self (
    set self-url=https://raw.githubusercontent.com/
    set self-url=%self-url%/abvalatouski/asprun/master/asprun.bat

    >nul 2>&1 powershell -c "Invoke-WebRequest -Outfile %~1 -Uri %self-url%"
    if not "!errorlevel!" == "0" (
        >&2 echo Can't download the source code. Try to do it yourself
        >&2 echo at '%self-url%'.
        exit /b 1
    )

    exit /b
)

:run-project (
    call :build-project
    if not "!errorlevel!" == "0" (
        exit /b 1
    )

    set url=%protocol%://!host!:%port%
    start /b dotnet run^
        --project=%project%^
        --configuration=%build-configuration%^
        --no-build^
        --^
        --urls=%url%^
        --Logging:LogLevel:Microsoft.Hosting.Lifetime=None

    if "%use-swagger-ui%" == "1" (
        set url=%url%/swagger
    )

    if "%quiet%" == "0" (
        echo %url%
    )

    if "%use-browser%" == "1" (
        start %url%
    )

    if "%wait%" == "1" (
        echo Press any key to stop the execution...
        >nul pause
        for /f %%f in ('dir %project%\bin /b /s ^| findstr ".exe"') do (
            >nul 2>&1 taskkill /f /im %%~nf.exe >nul
        )
    )

    exit /b
)

:build-project (
    rem `for` does not work properly when MSBuild properties are specified.
    call :generate-temporary-file-name build-output dotnet. .build
    >%build-output% dotnet build %project%^
        --configuration=%build-configuration%^
        --nologo^
        --verbosity=quiet^
        -property:WarningLevel=0
    if not "!errorlevel!" == "0" (
        call :parse-compiler-errors %build-output%
        del %build-output%
        exit /b 1
    )

    del %build-output%
    exit /b
)

:parse-compiler-errors (
    setlocal
    set parsed-at-least-one-error=0

    rem All the errors begin with a fully qualified filepath
    rem and may be duplicated.
    for /f "tokens=*" %%a in ('type %~1 ^| findstr "^.:" ^| sort /unique') do (
        if "!parsed-at-least-one-error!" == "1" (
            >&2 echo.
        )

        set error=%%a
        set parsed-at-least-one-error=1

        rem Passing variable name to avoid quoting problems.
        call :parse-compiler-error error
    )

    endlocal
    exit /b
)

:parse-compiler-error (
    setlocal
    set error=!%~1!

    rem Escaping some characters to split the error message, using them
    rem as delimiters.
    set error=!error:":"=^<quoted-colon^>!
    set error=!error:"["=^<quoted-bracket^>!

    rem The format of the error message is following:
    rem {drive}:{path}:({line},{column}): error {code}: {message} [{csproj}]
    for /f "tokens=1,2,3,4 delims=:[" %%a in ("!error!") do (
        for /f "tokens=1,2,3,4,6 delims=:,() " %%a in ("%%a:%%b:%%c") do (
            >&2 echo %%a:%%b:%%c:%%d: error %%e:
        )

        call :trim-spaces-around-arguments error %%d

        rem Unescaping.
        set error=!error:^<quoted-colon^>=":"!
        set error=!error:^<quoted-bracket^>="["!
        
        <nul >&2 set /p=!error!
        if not "!error:~-1!" == "." (
            rem For visual consistency.
            rem Some errors are not ended with a period.
            >&2 echo .
        ) else (
            >&2 echo.
        )
    )

    endlocal
    exit /b
)

:lookup-ip-config (
    set no-ip=1

    if "%~1" == "0" (
        for /f "tokens=3,4,5,6 delims=.: " %%a in (
            'ipconfig^
                ^| findstr "IPv4"^
                ^| findstr /n ".*"^
                ^| findstr "^%~2"'
        ) do (
            set host=%%a.%%b.%%c.%%d
            set no-ip=0
        )
    ) else (
        for /f "tokens=4,5,6,7 delims=.: " %%a in (
            'ipconfig^
                ^| findstr "IPv4"^
                ^| findstr /n ".*"^
                ^| sort /reverse^
                ^| findstr /n ".*"^
                ^| findstr "^%~2"'
        ) do (
            set host=%%a.%%b.%%c.%%d
            set no-ip=0
        )
    )

    exit /b %no-ip%
)

:generate-temporary-file-name (
    set temporary-file-name=%~2%random%%~3
    if exist "%temporary-file-name%" (
        goto :generate-temporary-file-name
    )

    set "%~1=%temporary-file-name%"
    exit /b
)

:trim-spaces-around-arguments (
    for /f "tokens=1*" %%a in ("%*") do (
        set "%%a=%%b"
    )

    exit /b
)
