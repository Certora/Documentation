```

import ::= "import" string

use ::= "use" "rule" id
        [ "filtered" "{" id "->" expression { "," id "->" expression } "}" ]
      | "use" "builtin" "rule" id
      | "use" "invariant" id [ "{" { preserved_block } "}" ]

```
