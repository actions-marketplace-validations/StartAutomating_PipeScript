CSharp.Template
---------------
### Synopsis
C# Template Transpiler.

---
### Description

Allows PipeScript to Generate C#.

Multiline comments with /*{}*/ will be treated as blocks of PipeScript.

Multiline comments can be preceeded or followed by 'empty' syntax, which will be ignored.

This for Inline PipeScript to be used with operators, and still be valid C# syntax. 

The C# Inline Transpiler will consider the following syntax to be empty:

* ```String.Empty```
* ```null```
* ```""```
* ```''```

---
### Examples
#### EXAMPLE 1
```PowerShell
{
    $CSharpLiteral = @'
namespace TestProgram/*{Get-Random}*/ {
public static class Program {
    public static void Main(string[] args) {
        string helloMessage = /*{
            '"hello"', '"hello world"', '"hey there"', '"howdy"' | Get-Random
        }*/ string.Empty; 
        System.Console.WriteLine(helloMessage);
    }
}
}    
'@
```
[OutputFile(".\HelloWorld.ps1.cs")]$CSharpLiteral
}

$AddedFile = .> .\HelloWorld.ps1.cs
$addedType = Add-Type -TypeDefinition (Get-Content $addedFile.FullName -Raw) -PassThru
$addedType::Main(@())
#### EXAMPLE 2
```PowerShell
// HelloWorld.ps1.cs
namespace TestProgram {
    public static class Program {
        public static void Main(string[] args) {
            string helloMessage = /*{
                '"hello"', '"hello world"', '"hey there"', '"howdy"' | Get-Random
            }*/ string.Empty; 
            System.Console.WriteLine(helloMessage);
        }
    }
}
```

---
### Parameters
#### **CommandInfo**

The command information.  This will include the path to the file.



> **Type**: ```[CommandInfo]```

> **Required**: true

> **Position**: named

> **PipelineInput**:true (ByValue)



---
#### **AsTemplateObject**

If set, will return the information required to dynamically apply this template to any text.



> **Type**: ```[Switch]```

> **Required**: true

> **Position**: named

> **PipelineInput**:false



---
#### **Parameter**

A dictionary of parameters.



> **Type**: ```[IDictionary]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
#### **ArgumentList**

A list of arguments.



> **Type**: ```[PSObject[]]```

> **Required**: false

> **Position**: named

> **PipelineInput**:false



---
### Syntax
```PowerShell
CSharp.Template -CommandInfo <CommandInfo> [-Parameter <IDictionary>] [-ArgumentList <PSObject[]>] [<CommonParameters>]
```
```PowerShell
CSharp.Template -AsTemplateObject [-Parameter <IDictionary>] [-ArgumentList <PSObject[]>] [<CommonParameters>]
```
---

