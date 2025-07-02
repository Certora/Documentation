(lsp)=
LSP Extension for VSCode
========================

If you're using VSCode to edit your CVL code, consider installing the
[Certora Verification Language LSP extension](https://marketplace.visualstudio.com/items?itemName=Certora.evmspec-lsp).
This extension contains several features to make editing CVL code easier,
such as syntax highlighting, automatic syntax checking and auto-formatting.

More useful features are planned in the near future, so please check back soon.

(formatter)=
CVL Formatter
-------------

CVL ships with an automatic tool for formatting CVL source code to
match a standard coding style. This allows users to have uniform-looking
CVL source code files without having to manually edit their code,
or to spend time debating coding style guidelines.

The formatter is "opinionated" - it formats according to a strict set of
predefined rules and does not currently support customization. This is
a deliberate decision made for the sake of uniformity across different projects.

The formatter uses spaces for indentation. It discards whitespace and line breaks
beyond what is considered necessary.

If you have installed the LSP Extension, you can run the formatter directly from
VSCode by using the `Format Document` feature from the [VSCode Command Palette](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette). Alternatively, you can manually run the formatter
from a shell, using the standalone script `certoraCVLFormatter.py`, and passing it
the name of the file you would like to format. See the documentation of that script
for more information.