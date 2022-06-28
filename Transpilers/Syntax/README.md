This directory and it's subdirectories contain syntax changes that enable common programming scenarios in PowerShell and PipeScript.


|DisplayName                         |Synopsis                                        |
|------------------------------------|------------------------------------------------|
|[RegexLiteral](RegexLiteral.psx.ps1)|[Regex Literal Transpiler](RegexLiteral.psx.ps1)|




## RegexLiteral Example 1


~~~PowerShell
    {
        '/[a|b]/'
    } | .>PipeScript
~~~

## RegexLiteral Example 2


~~~PowerShell
    {
        "/[$a|$b]/"
    } | .>PipeScript
~~~

## RegexLiteral Example 3


~~~PowerShell
    {@'
/
# Heredocs Regex literals will have IgnorePatternWhitespace by default, which allows comments
^ # Match the string start
(?<indent>\s{0,1})
/
'@
    } | .>PipeScript
~~~

## RegexLiteral Example 4


~~~PowerShell
    {
        $Keywords = "looking", "for", "these", "words"
        @"
/
# Double quoted heredocs can still contain variables
[\s\p{P}]{0,1}         # Whitespace or punctuation
$($Keywords -join '|') # followed by keywords
[\s\p{P}]{0,1}         # followed by whitespace or punctuation
/
"@
    } | .>PipeScript
~~~
