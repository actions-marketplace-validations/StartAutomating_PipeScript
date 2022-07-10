
Inline.CPlusPlus
----------------
### Synopsis
C/C++ PipeScript Transpiler.

---
### Description

Transpiles C/C++ with Inline PipeScript into C++.

Multiline comments with /*{}*/ will be treated as blocks of PipeScript.

Multiline comments can be preceeded or followed by 'empty' syntax, which will be ignored.

This for Inline PipeScript to be used with operators, and still be valid C/C++ syntax. 

The C++ Inline Transpiler will consider the following syntax to be empty:

* ```null```
* ```""```
* ```''```

---
### Parameters
#### **CommandInfo**

The command information.  This will include the path to the file.



|Type          |Requried|Postion|PipelineInput |
|--------------|--------|-------|--------------|
|```[Object]```|true    |1      |true (ByValue)|
---
### Syntax
```PowerShell
Inline.CPlusPlus [-CommandInfo] <Object> [<CommonParameters>]
```
---

