<#
.SYNOPSIS
    Generates PowerShell to talk to a REST api.
.DESCRIPTION
    Generates PowerShell that communicates with a REST api.
.EXAMPLE
    {
        function Get-Sentiment {
            [Rest("http://text-processing.com/api/sentiment/",
                ContentType="application/x-www-form-urlencoded",
                Method = "POST",
                BodyParameter="Text",
                ForeachOutput = {
                    $_ | Select-Object -ExpandProperty Probability -Property Label
                }
            )]
            param()
        } 
    } | .>PipeScript | Set-Content .\Get-Sentiment.ps1
.EXAMPLE
    Invoke-PipeScript {
        [Rest("http://text-processing.com/api/sentiment/",
            ContentType="application/x-www-form-urlencoded",
            Method = "POST",
            BodyParameter="Text",
            ForeachOutput = {
                $_ | Select-Object -ExpandProperty Probability -Property Label
            }
        )]
        param()
    } -Parameter @{Text='wow!'}
.EXAMPLE
    {
        [Rest("https://api.github.com/users/{username}/repos",
            QueryParameter={"type", "sort", "direction", "page", "per_page"}
        )]
        param()
    } | .>PipeScript
.EXAMPLE
    Invoke-PipeScript {
        [Rest("https://api.github.com/users/{username}/repos",
            QueryParameter={"type", "sort", "direction", "page", "per_page"}
        )]
        param()
    } -UserName StartAutomating
.EXAMPLE
    {
        [Rest("http://text-processing.com/api/sentiment/",
            ContentType="application/x-www-form-urlencoded",
            Method = "POST",
            BodyParameter={@{
                Text = '
                    [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
                    [string]
                    $Text
                '
            }})]
        param()
    } | .>PipeScript
#>
param(
# The ScriptBlock.
# If not empty, the contents of this ScriptBlock will preceed the REST api call. 
[Parameter(ValueFromPipeline)]
[scriptblock]
$ScriptBlock = {},

# One or more REST endpoints.  This endpoint will be parsed for REST variables.
[Parameter(Mandatory,Position=0)]
[string[]]
$RESTEndpoint,

# The content type.  If provided, this parameter will be passed to the -InvokeCommand.
[string]
$ContentType,

# The method.  If provided, this parameter will be passed to the -InvokeCommand.
[string]
$Method,

# The invoke command.  This command _must_ have a parameter -URI.
[Alias('Invoker')]
[string]
$InvokeCommand = 'Invoke-RestMethod',

# The name of a variable containing additional invoke parameters.
# By default, this is 'InvokeParams'
[Alias('InvokerParameters','InvokerParameter')]
[string]
$InvokeParameterVariable = 'InvokeParams',

# A dictionary of help for uri parameters.
[Alias('UrlParameterHelp')]
[Collections.IDictionary]
$UriParameterHelp,

# A dictionary of URI parameter types.
[Alias('UrlParameterType')]
[Collections.IDictionary]
$UriParameterType,

# A dictionary or list of parameters for the body.
[PSObject]
$BodyParameter,

# A dictionary or list of query parameters.
[PSObject]
$QueryParameter,

# A script block to be run on each output.
[ScriptBlock]
$ForEachOutput
)

begin {
    # Declare a Regular Expression to match URL variables. 
    $RestVariable = [Regex]::new(@'
# Matches URL segments and query strings containing variables.
# Variables can be enclosed in brackets or curly braces, or preceeded by a $ or :
(?>                           # A variable can be in a URL segment or subdomain
    (?<Start>[/\.])           # Match the <Start>ing slash|dot ...
    (?<IsOptional>\?)?        # ... an optional ? (to indicate optional) ...
    (?:
        \{(?<Variable>\w+)\}| # ... A <Variable> name in {} OR
        \[(?<Variable>\w+)\]| #     A <Variable> name in [] OR
        \<(?<Variable>\w+)\>| #     A <Variable> name in <> OR
        \:(?<Variable>\w+)    #     A : followed by a <Variable>
    )
|
    (?<IsOptional>            # If it's optional it can also be
        [{\[](?<Start>/)      # a bracket or brace, followed by a slash
    )
    (?<Variable>\w+)[}\]]     # then a <Variable> name followed by } or ]
|                             # OR it can be in a query parameter:
    (?<Start>[?&])            # Match The <Start>ing ? or & ...
    (?<Query>[\w\-]+)         # ... the <Query> parameter name ...
    =                         # ... an equals ...
    (?<IsOptional>\?)?        # ... an optional ? (to indicate optional) ...
    (?:
        \{(?<Variable>\w+)\}| # ... A <Variable> name in {} OR
        \[(?<Variable>\w+)\]| #     A <Variable> name in [] OR
        \<(?<Variable>\w+)\>| #     A <Variable> name in <> OR
        \:(?<Variable>\w+)    #     A : followed by a <Variable>
    )
)
'@, 'IgnoreCase,IgnorePatternWhitespace')

    
    # Next declare a script block that will replace the rest variable.
    $ReplaceRestVariable = {
        param($match)

        if ($uriParameter -and $uriParameter[$match.Groups["Variable"].Value]) {
            return $match.Groups["Start"].Value + $(
                    if ($match.Groups["Query"].Success) { $match.Groups["Query"].Value + '=' }
                ) +
                ([Web.HttpUtility]::UrlEncode(
                    $uriParameter[$match.Groups["Variable"].Value]
                ))
        } else {
            return ''
        }
    }

    $myCmd = $MyInvocation.MyCommand
}

process {
    # First, create a collection of URI parameters.
    $uriParameters = [Ordered]@{}
    # Then, walk over each potential endpoint 
    foreach ($endpoint in $RESTEndpoint) {
        # and each match of a $RestVariable
        foreach ($match in $RestVariable.Matches($endpoint)) {
            # The name of the parameter will be in the named capture ${Variable}.
            $parameterName = $match.Groups["Variable"].Value
            # The parameter type will be a string
            $parameterType = if ($UriParameterType.$parameterName) {
                if ($UriParameterType.$parameterName -as [type]) {
                    $UriParameterType.$parameterName
                }
            } else {
                '[string]'
            }
            # and we'll need to put it in the proper parameter set.
            $parameterAttribute = "[Parameter($(                
                if (-not $match.Groups["IsOptional"].Value) {'Mandatory'}
            ),ValueFromPipelineByPropertyName,ParameterSetName='$endpoint')]"
            # Combine these three pieces to create the parameter attribute.
            $uriParameters[$parameterName] = @(
                if ($UriParameterHelp -and $UriParameterHelp.$parameterName) {
                    if ($UriParameterHelp.$parameterName -notmatch '^\<{0,1}\#' ) {
                        if ($UriParameterHelp.$parameterName -match '[\r\n]') {
                            "<# " + $UriParameterHelp.$parameterName + "#>" 
                        } else {
                            "# " + $UriParameterHelp.$parameterName
                        }
                    } else {
                        $UriParameterHelp.$parameterName
                    }
                }
                $parameterAttribute
                $parameterType
                '$' + $parameterName
            ) -join [Environment]::Newline
        }        
    }

    # Create a parameter block out of the uri parameters.
    $uriParamBlock  = 
        New-PipeScript -Parameter $uriParameters
    
    # Next, create a parameter block out of any of the body parameters.
    $bodyParamBlock = 
        if ($BodyParameter) {
            New-PipeScript -Parameter $BodyParameter
        } else { {} }
    
    # And one for each of the query parameters.
    $QueryParamblock =
        if ($QueryParameter) {
            New-PipeScript -Parameter $QueryParameter
        } else { {} }
        
    $myBeginBlock = 
        # If we used any URI parameters
        if ($uriParamBlock.Ast.ParamBlock.Parameters) {
            # Carry on the begin block from this command (this is a neat trick)
            [scriptblock]::Create($myCmd.ScriptBlock.Ast.BeginBlock.Extent.ToString())
        } else { { begin { $myCmd = $MyInvocation.MyCommand }} }
        
    # Next, collect the names of bodyParameters, queryParameters, and uriParameters.
    $bodyParameterNames  = 
        foreach ($param in $bodyParamBlock.Ast.ParamBlock.Parameters) { $param.Name -replace '^\$' }
    $queryParameterNames =
        foreach ($param in $QueryParamblock.Ast.ParamBlock.Parameters) { $param.Name -replace '^\$' }
    $uriParameterNames   =
        foreach ($param in $uriParamBlock.Ast.ParamBlock.Parameters)   { $param.Name -replace '^\$' }
    
    
    # Collect all of the parts of the script
    $RestScript = @(
        # Start with the underlying script block
        $ScriptBlock

        # Then include the begin block from this command (or declare myCmd)
        $myBeginBlock

        # Then declare the initial variables.
        [scriptblock]::Create((@"
process {
    `$InvokeCommand       = '$InvokeCommand'
    `$invokerCommandinfo  = 
        `$ExecutionContext.SessionState.InvokeCommand.GetCommand('$InvokeCommand', 'All')
    `$method              = '$Method'
    `$contentType         = '$contentType'
    `$bodyParameterNames  = @('$($bodyParameterNames -join "','")')
    `$queryParameterNames = @('$($queryParameterNames -join "','")')
    `$uriParameterNames   = @('$($uriParameterNames -join "','")')
    `$endpoints           = @("$($endpoint -join "','")")
    `$ForEachOutput = {
        $(if ($foreachOutput) { $ForEachOutput | .>Pipescript })
    }
    if (`$ForEachOutput -match '^\s{0,}$') {
        `$ForEachOutput = `$null
    }    
}
"@))
    # Next, add some boilerplate code for error handling and setting defaults
{
process {
    if (-not $invokerCommandinfo) {
        Write-Error "Unable to find invoker '$InvokeCommand'"
        return        
    }
    if (-not $psParameterSet) { $psParameterSet = $psCmdlet.ParameterSetName}
    if ($psParameterSet -eq '__AllParameterSets') { $psParameterSet = $endpoints[0]}    
}
}
    # If we had any uri parameters
    if ($uriParameters.Count) {
        # Add the uri parameter block
        $uriParamBlock                
        # Then add a bit to process {} to extract out the URL
{
process {
    $originalUri = "$psParameterSet"
    if (-not $PSBoundParameters.ContainsKey('UriParameter')) {
        $uriParameter = [Ordered]@{}
    }
    foreach ($uriParameterName in $uriParameterNames) {
        if ($psBoundParameters.ContainsKey($uriParameterName)) {
            $uriParameter[$uriParameterName] = $psBoundParameters[$uriParameterName]
        }
    }

    $uri = $RestVariable.Replace($originalUri, $ReplaceRestVariable)
}
}            
    } else {
        # If uri parameters were not supplied, default to the first endpoint.
{
    process {
        $uri = $endpoints[0]
    }
}
    }
    # Now create the invoke splat and populate it.
{
process {
    $invokeSplat = @{}
    $invokeSplat.Uri = $uri
    if ($method) {
        $invokeSplat.Method = $method
    }
    if ($ContentType) {
        $invokeSplat.ContentType = $ContentType
    }
}
}

    # If we have an InvokeParameterVariable
    if ($InvokeParameterVariable) {
        # Create the code that looks for it and joins it with the splat.
        $InvokeParameterVariable = $InvokeParameterVariable -replace '^\$'
[scriptblock]::Create("
process {
    if (`$$InvokeParameterVariable -and `$$InvokeParameterVariable -is [Collections.IDictionary]) {
        `$invokeSplat += `$$InvokeParameterVariable
    }
}
")

    }

    # If QueryParameter Names were provided
    if ($queryParameterNames) {
        # Include the query parameter block
        $QueryParamblock
        # And a section of process to handle query parameters.
{
process {
    $QueryParams = [Ordered]@{}
    foreach ($QueryParameterName in $QueryParameterNames) {
        if ($PSBoundParameters.ContainsKey($QueryParameterName)) {
            $QueryParams[$QueryParameterName] = $PSBoundParameters[$QueryParameterName]            
        }
    }
}
}    
{
process {
    if ($invokerCommandinfo.Parameters['QueryParameter'] -and 
        $invokerCommandinfo.Parameters['QueryParameter'].ParameterType -eq [Collections.IDictionary]) {
        $invokerCommandinfo.QueryParameter = $QueryParams
    } else {
        $queryParamStr = 
            @(foreach ($qp in $QueryParams.GetEnumerator()) {
                "$($qp.Key)=$([Web.HttpUtility]::UrlEncode($qp.Value).Replace('+', '%20'))"
            }) -join '&'
        if ($invokeSplat.Uri.Contains('?')) {
            $invokeSplat.Uri = "$($invokeSplat.Uri)" + '&' + $queryParamStr
        } else {
            $invokeSplat.Uri = "$($invokeSplat.Uri)" + '?' + $queryParamStr
        }
    }
}
}
    }

    # If any body parameters exist
    if ($bodyParameterNames) {
        # Include the body parameter block
        $bodyParamBlock
        # and a process section to handle the body
{
process {
    $completeBody = [Ordered]@{}
    foreach ($bodyParameterName in $bodyParameterNames) {
        if ($bodyParameterName) {
            if ($PSBoundParameters.ContainsKey($bodyParameterName)) {
                $completeBody[$bodyParameterName] = $PSBoundParameters[$bodyParameterName]
            }
        }
    }

    $bodyContent = 
        if ($ContentType -match 'x-www-form-urlencoded') {
            @(foreach ($bodyPart in $completeBody.GetEnumerator()) {
                "$($bodyPart.Key.ToString().ToLower())=$([Web.HttpUtility]::UrlEncode($bodyPart.Value))"
            }) -join '&'
        } elseif ($ContentType -match 'json') {
            ConvertTo-Json $completeBody
        }

    if ($bodyContent -and $method -ne 'get') {
        $invokeSplat.Body = $bodyContent
    }    
}
}
    }
    
    # Last but not least, include the part of process that calls the REST api.
    {
process {
    Write-Verbose "$($invokeSplat.Uri)"
    if ($ForEachOutput) {
        if ($ForEachOutput.Ast.ProcessBlock) {
            & $invokerCommandinfo @invokeSplat | & $ForEachOutput
        } else {
            & $invokerCommandinfo @invokeSplat | ForEach-Object -Process $ForEachOutput
        }        
    } else {
        & $invokerCommandinfo @invokeSplat
    }
}
    }
    )
    
    # Join all of the parts together and you've got yourself a RESTful function.
    $RestScript | 
        Join-PipeScript
}
