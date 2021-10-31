# VS-less

Visual Studio eats terabytes of RAM! The repository tries to help you to avoid
opening that beast, provoding some console utilities.

## `asprun`

```console
> asprun /?
Runs an ASP.NET project at the specified port and prints its URL.
The launched process can be stopped via 'taskkill /f /im project.exe',
if its name matched the name of the project.

    asprun project [/?] [/p port] [/c buildconfig] [/s] [/o]      

Options

    project         Path to the project's folder. 

    /p port         Defaulted to 5001.      

    /c buildconfig  Either Debug or Release.
                    Defaulted to Debug.     

    /s              Print URL of Swagger UI.

    /o              Open URL in the browser.

    Options can be placed in any order.
    In case of duplication newer options will override older ones.
    Unknown option will be treated as a project path.

Example

    mkdir WeatherForecast
    dotnet new webapi -o WeatherForecast
    asprun WeatherForecast /s /o
    taskkill /f /im WeatherForecast.exe
```
