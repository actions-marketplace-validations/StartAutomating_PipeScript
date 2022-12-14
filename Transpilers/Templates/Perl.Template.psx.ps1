<#
.SYNOPSIS
    Perl Template Transpiler.
.DESCRIPTION
    Allows PipeScript to generate Perl.

    Also Transpiles Plain Old Document

    PipeScript can be embedded in a Plain Old Document block that starts with ```=begin PipeScript``` and ends with ```=end PipeScript```.    
.EXAMPLE
    .> {
        $HelloWorldPerl = @'
=begin PipeScript
$msg = "hello", "hi", "hey", "howdy" | Get-Random
"print(" + '"' + $msg + '");'
=end   PipeScript
'@

        [Save(".\HelloWorld.ps1.pl")]$HelloWorldPerl
    }

    .> .\HelloWorld.ps1.pl
#>
[ValidatePattern('\.(?>pl|pod)$')]
param(
# The command information.  This will include the path to the file.
[Parameter(Mandatory,ValueFromPipeline,ParameterSetName='TemplateFile')]
[Management.Automation.CommandInfo]
$CommandInfo,

# If set, will return the information required to dynamically apply this template to any text.
[Parameter(Mandatory,ParameterSetName='TemplateObject')]
[switch]
$AsTemplateObject,

# A dictionary of parameters.
[Collections.IDictionary]
$Parameter,

# A list of arguments.
[PSObject[]]
$ArgumentList
)

begin {
    # We start off by declaring a number of regular expressions:
    
    $startComment = '(?>
        (?>^|\[\r\n]{1,2})\s{0,}
        =begin
        \s{1,}
        (?>Pipescript|\{)
        [\s\r\n\{]{0,}
    )'
    $endComment   = '(?>
        [\r\n]{1,3}
        \s{0,}
        =end
        (?>\}|\s{1,}PipeScript[\s\r\n\}]{0,})
    )'
    
    $startRegex = "(?<PSStart>${startComment})"    
    $endRegex   = "(?<PSEnd>${endComment})"

    # Create a splat containing arguments to the core inline transpiler
    $Splat      = [Ordered]@{
        StartPattern  = $startRegex
        EndPattern    = $endRegex
    }
}

process {
    # If we have been passed a command
    if ($CommandInfo) {
        # add parameters related to the file.
        $Splat.SourceFile = $commandInfo.Source -as [IO.FileInfo]
        $Splat.SourceText = [IO.File]::ReadAllText($commandInfo.Source)
    }
    
    if ($Parameter) { $splat.Parameter = $Parameter }
    if ($ArgumentList) { $splat.ArgumentList = $ArgumentList }

    # If we are being used within a keyword,
    if ($AsTemplateObject) {
        $splat # output the parameters we would use to evaluate this file.
    } else {
        # Otherwise, call the core template transpiler
        .>PipeScript.Template @Splat # and output the changed file.
    }
}
