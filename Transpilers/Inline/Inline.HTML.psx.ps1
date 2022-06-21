<#
.SYNOPSIS
    HTML PipeScript Transpiler.
.DESCRIPTION
    Transpiles HTML with Inline PipeScript into HTML.

    Multiline comments blocks like this ```<!--{}-->``` will be treated as blocks of PipeScript.

    JavaScript/CSS comment blocks like ```/*{}*/``` will also be treated as blocks of PipeScript.
.Example
    .> {
        $HtmlWithInlinePipeScript = @'
<html>
    <head>        
        <title>
            Joke of the Day
        </title>
        <style>
            .Joke {
                font-size: 1.5em;
                width: 100%;
            }
            .JokeSetup {
                font-size: 1.1em;
                text-align: center;
            }
            .JokePunchLine {
                font-size: 1.25em;
                text-align: center;
            }
            .Datestamp {
                position:fixed;
                bottom: 0;
                left: 0;                
            }
        </style>
    </head>
    <body>
        <!--{
            "<div class='Joke'>" + $(
                Invoke-RestMethod -Uri 'https://v2.jokeapi.dev/joke/Any' | 
                    Foreach-Object {
                        if ($_.Joke) { $_.Joke}
                        elseif ($_.Setup -and $_.Delivery) {
                            "<div class='JokeSetup'>" + $_.Setup + "</div>"
                            "<div class='JokePunchline'>" + $_.Delivery + "</div>"
                        }
                    }
            ) + "</div>"

            "<div class='Datestamp'>" + 
                "Last Updated:" +
                (Get-Date | Out-String) +
                "</div>"
        }-->
    </body>
</html>

'@

        [OutputFile(".\Index.ps.html")]$HtmlWithInlinePipeScript
    }

    $htmlFile = .> .\Index.ps.html
#>
[ValidateScript({
    $cmdInfo = $_
    if ($cmdInfo.Source -match '\.(?>html{0,1}|xml)$') {
        return $true
    }
    return $false    
})]
param(
# The command information.  This will include the path to the file.
[Parameter(Mandatory,ValueFromPipeline)]
$CommandInfo
)

begin {
    # We start off by declaring a number of regular expressions:
    $startComment = '(?><\!--|/\*)' # * Start Comments ```<!--```
    $endComment   = '(?>-->|\*/)'   # * End Comments   ```-->```
    $Whitespace   = '[\s\n\r]{0,}'
    # * StartRegex     ```$StartComment + '{' + $Whitespace```
    $startRegex = "(?<PSStart>${startComment}\{$Whitespace)"
    # * EndRegex       ```$whitespace + '}' + $EndComment```
    $endRegex   = "(?<PSEnd>$Whitespace\}${endComment}\s{0,})"

    $sourcePattern  = [Regex]::New("(?>$(
        $startRegex, $endRegex -join ([Environment]::NewLine + '|' + [Environment]::NewLine)
    ))", "IgnoreCase, IgnorePatternWhitespace", "00:00:05")
}

process {
    
    $fileInfo = $commandInfo.Source -as [IO.FileInfo]
    $fileText      = [IO.File]::ReadAllText($fileInfo.Fullname)

    .>PipeScript.Inline -SourceFile $CommandInfo.Source -SourceText $fileText -SourcePattern $sourcePattern
}