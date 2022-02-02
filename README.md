Certora public documentation
============================

This repository contains the public documentation for the Certora Prover.

The documentation is hosted by [readthedocs.com]()
at [docs.certora.com]().  It is generated using the Sphinx documentation system.

[rtd]: https://readthedocs.com/projects/certora-certora-prover-documentation/
[docs]: https://docs.certora.com/
[sphinx]: https://www.sphinx-doc.org/en/master/
[myst]: https://myst-parser.readthedocs.io/en/latest/sphinx/intro.html

Documentation organization
--------------------------

Most of the documentation is stored in markdown files.  The markdown syntax is
extended with features of ReStructuredText (rst) using the
[Myst Parser](myst).

The root of the document tree is `index.md`; it includes a table of contents that
references the remainder of the documentation (see {ref}`toc` below)

To build the documentation, run `make` in the current directory; this will
generate the html output in `_build/html/index.html`.  `make help` will list
other options for compiling the documentation.

Myst markdown
-------------

The following formatting features are of particular note if you are already
familiar with markdown but not RST.  For full details, see the [Myst documentation](myst).

(toc)=
### Table of contents tree

The documents are organized into a book using the "toctree directive".  A block
like:

````markdown
```{toctree}
:maxdepth: 2

foo.md
bar.md
````

will instruct the parser to add the documents `foo.md` and `bar.md` from the
current directory into to the table of contents for the documentation.  It will
also put a table containing `foo.md` and `bar.md` including their section headers
and toctrees in the present document.

### Source code in CVL and solidity

Source code blocks in CVL and solidity should be indicated by writing `cvl` or
`solidity` immediately after the triple backtick:

````markdown
```cvl
rule exampleRule() {
    havoc foo assuming foo != 3;
}
```
````

and

````markdown
```solidity
function foo() external returns (uint256) {
    return 0;
}
```
````

