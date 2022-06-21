﻿function Use-PipeScript
{
    <#
    .Synopsis
        Uses PipeScript Transpilers    
    .Description
        Runs an individual PipeScript Transpiler.
        This command must be used by it's smart aliases (for example ```.>PipeScript```).
    .Example
        { "Hello World" } | .>PipeScript # Returns an unchanged ScriptBlock, because there was nothing to run.
    .LINK
        Get-Transpiler
    #>
    [CmdletBinding()]
    param()

    dynamicParam {
        # If we didn't have a Converter library, create one.
        if (-not $PipeScriptConverters) { $script:PipeScriptConverters = @{} }

        $myInv = $MyInvocation
        # Then, determine what the name of the pattern in the library would be.
        $NameRegex = '[=\.\<\>@\$\!\*]+(?<Name>[\p{L}\p{N}\-\.\+]+)[=\.\<\>@\$\!\*]{0,}'

        $mySafeName =
            if ('.', '&' -contains $myInv.InvocationName -and
                (
                    $myInv.Line.Substring($MyInvocation.OffsetInLine) -match
                    "^\s{0,}$NameRegex"
                ) -or (
                    $myInv.Line.Substring($MyInvocation.OffsetInLine) -match
                    "^\s{0,}\$\{$NameRegex}"
                )
            )
            {
                $matches.Name
            }
            else
            {
                $myInv.InvocationName -replace $NameRegex, '${Name}'
            }

        # Find the Converter in the library.
        $converter = Get-Transpiler | Where-Object DisplayName -eq $mySafeName 
        $converter.GetDynamicParameters()
        # return $Converter.GetDynamicParameters()        
    }

    begin {
        $steppablePipelines = 
            @(if (-not $mySafeName -and $psBoundParameters['Name']) {
                $names = $psBoundParameters['Name']
                $null  = $psBoundParameters.Remove('Name')
                foreach ($cmd in $script:PipeScriptConverters[$names]) {
                    $steppablePipeline = {& $cmd @PSBoundParameters }.GetSteppablePipeline($MyInvocation.CommandOrigin)
                    $null = $steppablePipeline.Begin($PSCmdlet)
                    $steppablePipeline
                }
                $psBoundParameters['Name'] = $names
            })
    }

    process {
        if (-not $mySafeName -and -not $steppablePipelines) {            
            Write-Error "Must call Use-Pipescript with one of it's aliases."
            return
        } 
        elseif ($steppablePipelines) {
            $in = $_
            foreach ($sp in $steppablePipelines) {
                $sp.Process($in)
            }
            return
        }
        $paramCopy = [Ordered]@{} + $psBoundParameters
        & $Converter @paramCopy
    }

    end {
        foreach ($sp in $steppablePipelines) {
            $sp.End()
        }
    }
}
