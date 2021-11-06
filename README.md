# `asprun`

Download the script with:

```console
powershell -c "Invoke-WebRequest -Outfile asprun.bat -Uri https://raw.githubusercontent.com/abvalatouski/vsless/master/asprun.bat"
```

Shortened help message:

```text
Runs the ASP.NET project at the specified port and prints its URL.
The launched process can be stopped via 'taskkill /f /im project.exe',
if its name matches name of the project.

    asprun project [/?] [/c build-configuration] [/h host] [/i] [/o] [/p port]
        [/q] [/s] [/w]

Options

    project                 Path to the project's folder.

    /c build-configuration  Either Debug or Release.
                            Defaulted to "Debug".

    /h host                 Can be either host name, host IP, or '%%n',
                            where number 'n' refers to nth IPv4 from 'ipconfig'.
                            See 'ipconfig | findstr "IPv4" | findstr /n ".*"'.
                            Defaulted to "localhost" (same as "127.0.0.1").

    /i                      Use HTTP instead of HTTPS.
                            ===================
                            Mnemonic: insecure.

    /o                      Open URL in the browser.

    /p port                 Defaulted to "5001".

    /q                      Disable URL printing.
                            ================
                            Mnemonic: quiet.

    /s                      Print URL of Swagger UI.

    /w                      Wait pressing any key to stop the project.

    Options can be placed in any order.
    In case of duplication newer options will override older ones.
    Unknown option will be treated as a project path.

Examples

    > dotnet new mvc -o SimpleMvc
    > asprun SimpleMvc /o /q
    > taskkill /f /im SimpleMvc.exe

    > dotnet new webapi -o WeatherForecast
    > asprun WeatherForecast /o /q /s /w
    Press any key to stop the execution...
    >

    > dotnet new webapi -o WeatherForecast
    > rem See 'ipconfig' to find IP of your local network.
    > asprun WeatherForecast /h %2 /i /p 80 /s
    http://192.168.x.x:80/swagger
    > rem Connect another device to the local network an try to open that
    > rem link.
    > taskkill /f /im WeatherForecast.exe
```
