Certora public documentation
============================

This repository contains the public documentation for the Certora Prover.

The documentation is hosted by [readthedocs.com](rtd)
at [docs.certora.com](docs).  It is generated using the [Sphinx](sphinx)
documentation system and the [myst markdown parser](myst).

To update the documentation, please submit a PR.  The documentation group will
review and provide feedback.  In order for the PR to be accepted, the
documentation must build without warnings.  To build the documentation locally,
run `make` in the top level directory.

[rtd]: https://readthedocs.com/projects/certora-certora-prover-documentation/
[docs]: https://docs.certora.com/
[sphinx]: https://www.sphinx-doc.org/en/master/
[myst]: https://myst-parser.readthedocs.io/en/latest/sphinx/intro.html

Documentation organization
--------------------------

At the top level, the documentation is currently split into four "books":

 - The Tutorial section is a placeholder; in the future we may want to integrate
   the tutorial more closely to the documentation, but right now it is just a
   link.

 - The User Guide contains information about the Certora Prover and Certora
   Verification Language.  It is intended to explain how to use the Prover to
   verify smart contracts.  It is organized by topic and focuses on the most
   useful features instead of including comprehensive details.
   
   The user guide should contain extended examples, and should be organized
   into chapters that walk users through specific goals, like dealing with
   timeouts, managing multiple contracts, designing specifications, etc.
   Articles about individual features should refer to the Reference Manual for
   complete documentation.

 - The Reference Manual contains detailed and comprehensive information about the
   Certora Prover.  The Reference Manual is intended to describe what the Prover
   does, in contrast to the {doc}`/docs/user-guide/index` which explains how to
   use the Prover to accomplish particular goals.

   The reference manual should contain systematically organized information about
   each individual feature in isolation.  It should clearly describe the syntax
   and semantics, but should refer to the user guide for extended examples and
   advice.

 - The Old Documentation section (in the `confluence` folder) is the
   documentation that was copied from confluence.  As it gets edited and
   organized into the above structure, we will remove the articles that are
   replaced.

File structure
--------------

Most of the documentation is stored in markdown files.  The markdown syntax is
extended with features of ReStructuredText (rst) using the
[Myst Parser](myst).

The root of the document tree is `index.md`; it includes a table of contents that
references the remainder of the documentation (see {ref}`toc` below)

To build the documentation, run `make` in the current directory; this will
generate the html output in `_build/html/index.html`.  `make help` will list
other options for compiling the documentation.

Style guide
-----------

 - Use "Title Case" for document headings (that appear in the TOC on the left)
 - Use "Sentence case" for section headings
 - Run `make spelling` and fix warnings before submitting a PR
 - Use the `term` feature when referring to a new term for the first time, this
   links to the glossary. 
   
 - In the reference manual, prefer descriptions over examples; use examples to
   help when the descriptions are not entirely clear.  Descriptions can outline
   the entire space of correct and incorrect behavior, while it is not always
   clear how to generalize from examples.

   In the future, we should probably prepare copious examples and attach them,
   but our overreliance on examples in earlier docs has left a lot of things
   underspecified.


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

### Other good features to know

 - glossary
 - references to other documents
 - references to labeled sections
 - todo

