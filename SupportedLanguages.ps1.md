These are all of the transpilers currently included in PipeScript:


~~~PipeScript{
    [PSCustomObject]@{
        Table = Get-Transpiler |
            Where-Object {
                $_.Parameters.Values |
                    Where-Object { $_.ParameterType -eq [Management.Automation.CommandInfo] }
            } |
            Sort-Object Name |
            Select-Object @{
                Name='Language'
                Expression= {
                    "[$($_.DisplayName -replace '^Inline\.')]($($_.Source -replace '^.+(?=Transpilers)'))"
                }
            }, @{
                Name='Synopsis'
                Expression= { $_.Synopsis -replace '[\s\r\n]+$' }
            }, @{
                Name='Pattern'
                Expression = { '```' + "$($_.ScriptBlock.Attributes.RegexPattern -replace '\|','\|')" + '```'}
            }
    }
}
~~~
