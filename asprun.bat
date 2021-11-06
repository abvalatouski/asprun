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
  setlocal enabledelayedexpansion

  set command=%~f0
  shift

  set project=
  set build-configuration=Debug
  set host=localhost
  set use-ip-number=0
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
        "Expected a host URL after %0."
      endlocal
      exit /b 1
    )

    set host=%1
    if "!host:~0,1!" == "%%" (
      call :lookup-ip-config "!host:~1!"
      if not "!errorlevel!" == "0" (
        >&2 echo 'ipconfig' does not provide an IPv4 with number '!host:~1!'.
        >&2 echo See 'ipconfig ^| findstr "IPv4" ^| findstr /n ".*"'.
        endlocal
        exit /b 1
      )
    )

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

  call :run-project
  endlocal
  exit /b %errorlevel%
)

:usage (
  echo Runs the ASP.NET project at the specified port and prints its URL.
  echo The launched process can be stopped via 'taskkill /f /im project.exe',
  echo if its name matches name of the project.
  echo.
  echo   %~n1 project [/?] [/c build-configuration] [/h host] [/i] [/o] [/p port]
  echo     [/q] [/s] [/w]
  echo.
  echo Options
  echo.
  echo   project                 Path to the project's folder.
  echo.
  echo.  /?                      Show this help message.
  echo                           Other options will be ignored.
  echo.
  echo   /c build-configuration  Either Debug or Release.
  echo                           Defaulted to "%build-configuration%".
  echo.
  echo   /h host                 Can be either host name, host IP, or '%%%%n',
  echo                           where number 'n' refers to nth IPv4 from 'ipconfig'.
  echo                           See 'ipconfig ^| findstr "IPv4" ^| findstr /n ".*"'.
  echo                           Defaulted to "localhost" (same as "127.0.0.1").
  echo.
  echo   /i                      Use HTTP instead of HTTPS.
  echo                           ===================
  echo                           Mnemonic: insecure.
  echo.
  echo   /o                      Open URL in the browser.
  echo.
  echo   /p port                 Defaulted to "%port%".
  echo.
  echo   /q                      Disable URL printing.
  echo                           ================
  echo                           Mnemonic: quiet.
  echo.
  echo   /s                      Print URL of Swagger UI.
  echo.
  echo   /w                      Wait pressing any key to stop the project.
  echo.
  echo   Options can be placed in any order.
  echo   In case of duplication newer options will override older ones.
  echo   Unknown option will be treated as a project path.
  echo.
  echo Examples
  echo.
  echo   ^> dotnet new mvc -o SimpleMvc
  echo   ^> %~n1 SimpleMvc /o /q
  echo   ^> taskkill /f /im SimpleMvc.exe
  echo.
  echo   ^> dotnet new webapi -o WeatherForecast
  echo   ^> %~n1 WeatherForecast /o /q /s /w
  echo   Press any key to stop the execution...
  echo   ^>
  echo.
  echo   ^> dotnet new webapi -o WeatherForecast
  echo   ^> rem See 'ipconfig' to find IP of your local network.
  echo   ^> %~n1 WeatherForecast /h %%2 /i /p 80 /s
  echo   http://192.168.x.x:80/swagger
  echo   ^> rem Connect another device to the local network an try to open that
  echo   ^> rem link.
  echo   ^> taskkill /f /im WeatherForecast.exe
  echo.
  echo Source Code
  echo.
  echo.  Written by Aliaksei Valatouski ^<abvalatouski@gmail.com^>.
  echo   The source code is licensed under the MIT License.
  echo.
  echo   See 'type %~f1'
  echo   or 'https://github.com/abvalatouski/vsless'.

  exit /b
)

:run-project (
  call :build-project
  if not "%errorlevel%" == "0" (
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
  setlocal
  set has-errors=0

  for /f "tokens=*" %%a in (
    'dotnet build %project%^
        --configuration=%build-configuration%^
        --nologo^
        --verbosity=quiet^
      ^| findstr "^.:"^
      ^| sort /unique'
  ) do (
    set message=%%a

    rem Escaping some characters to split the error message, using them
    rem as delimiters.
    set message=!message:":"=^<quoted-colon^>!
    set message=!message:"["=^<quoted-bracket^>!

    for /f "tokens=1,2,3,4 delims=:[" %%a in ("!message!") do (
      set is-error=0

      for /f "tokens=1,2,3,4,5,6 delims=:,() " %%a in ("%%a:%%b:%%c") do (
        if "%%e" == "error" (
          set is-error=1
          set has-errors=1
        )

        if "!is-error!" == "1" (
          if "!has-errors!" == "1" (
            >&2 echo.
          )

          >&2 echo %%a:%%b:%%c:%%d: %%e %%f:
        )
      )

      for /f "tokens=*" %%a in ("%%d") do (
        if "!is-error!" == "1" (
          set message=%%a

          rem Unescaping.
          set message=!message:^<quoted-colon^>=":"!
          set message=!message:^<quoted-bracket^>="["!

         >&2 echo !message!
        )
      )
    )
  )

  endlocal
  exit /b %has-errors%
)

:option-error (
  >&2 echo %~2
  >&2 echo See '%~n1 /? ^| more'.
  exit /b 0
)

:lookup-ip-config (
  set no-ip=1
  for /f "tokens=3,4,5,6 delims=.: " %%a in (
    'ipconfig^
      ^| findstr "IPv4"^
      ^| findstr /n ".*"^
      ^| findstr "^%~1"'
  ) do (
    set host=%%a.%%b.%%c.%%d
    set no-ip=0
  )
  
  exit /b %no-ip%
)
