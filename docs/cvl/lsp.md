(lsp)=
LSP Extension for VSCode
========================

If you're using VSCode to edit your CVL code, consider installing the
[Certora Verification Language LSP extension](https://marketplace.visualstudio.com/items?itemName=Certora.evmspec-lsp).
This extension contains several features to make editing CVL code easier,
such as syntax highlighting, automatic syntax checking and code formatting.

(formatter)=
CVL Formatter
-------------

CVL ships with an automatic tool for formatting CVL source code to
match a standard coding style. This allows users to have uniform-looking
CVL source code files.

The formatter is "opinionated" - it formats according to a strict set of
predefined rules and does not currently support customization. This is
a deliberate decision made for the sake of uniformity across different projects.

```{warning}
The formatter only works with CVL files that are syntactically-correct: 
if the CVL compiler rejects the code, the formatter may also reject it,
and formatting will fail. Notably, this means that trivial syntax errors
such as unclosed braces, will make the formatter fail.
```
```{note}
Occasionally you may find files that are not valid CVL code, such as some
files that don't pass typechecking, but are still formattable.
You shouldn't rely on this: instead, make sure your code compiles without errors,
and only then run the formatter.
```

The formatter uses spaces for indentation. It discards whitespace and line breaks
beyond what is considered necessary, as well as redundant parentheses. It may
also insert line breaks or whitespace, or make other style changes.

```{note}
The intent is to achieve a style that most people will find acceptable,
since it's understandable that no single style can satisfy everyone.
```

If you have installed the LSP Extension, you can run the formatter directly from
VSCode by using the `Format Document` feature from the [VSCode Command Palette](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette). Alternatively, you can manually run the formatter
from a shell, using the standalone script `certoraCVLFormatter.py`, and passing it
the name of the file you would like to format. See the documentation of that script
for more information.