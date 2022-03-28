Import and Use Statements
=========================

Additional spec files can be imported using the `import` command.

```{todo}
This feature is currently undocumented.
```


```
import ::= "import" string

use ::= "use" "rule" id
        [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
      | "use" "builtin" "rule" id
      | "use" "invariant" id [ "{" { preserved_block } "}" ]

```

