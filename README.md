Certora public documentation
============================

This repository contains the public documentation for the Certora Prover.  The
generated documentation is available at [docs.certora.com][docs].

The documentation is hosted by [readthedocs.com][rtd].  It is generated using
the [Sphinx][sphinx] documentation system and the [myst markdown parser][myst].

To update the documentation, please submit a PR.  The documentation group will
review and provide feedback.  In order for the PR to be accepted, the
documentation must build without warnings.  To build the documentation locally,
run `make` in the top level directory.

For new features that are being designed, create an `feature/accepted` branch
and a `feature/proposal` branch.  File a PR from `proposal` to `accepted` so
that stakeholders can be aware of the design; future changes to the design
(before release) should also be reviewed as PRs against the `accepted` branch.
Once the new feature is available, merge the `accepted` branch into `master`.

[rtd]: https://readthedocs.com/projects/certora-certora-prover-documentation/
[docs]: https://docs.certora.com/en/latest/docs/user-guide/intro.html
[sphinx]: https://www.sphinx-doc.org/en/master/
[myst]: https://myst-parser.readthedocs.io/en/latest/sphinx/intro.html

Building the documentation
--------------------------

 - Install `make` (TODO: instructions for windows)
 - Install relevant python packages `pip install -r requirements.txt`
 - Install additional dependencies for `pyenchant` ([instructions](https://pyenchant.github.io/pyenchant/install.html))
 - Run `make` in the top level directory

Documentation organization
--------------------------

At the top level, the documentation is currently split into four "books":

 - The whitepaper is our whitepaper

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

   Note: the reference manual now spans `cvl`, `gambit`, and the `prover`
   subdirectories.

 - The Old Documentation section (in the `confluence` folder) is the
   documentation that was copied from confluence.  As it gets edited and
   organized into the above structure, we will remove the articles that are
   replaced.

File structure
--------------

Most of the documentation is stored in markdown files.  The markdown syntax is
extended with features of ReStructuredText (rst) using the
[Myst Parser][myst].

The root of the document tree is `index.md`; it includes a table of contents
that references the remainder of the documentation (see {ref}`toc` below).  All
of the actual documentation is contained in the `docs` directory.

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

 - Prefer semantic blocks to hand-formatting.  For example, prefer

````
```{note}
This is a note
```
````

to

```
**Note**: _this is a note_.
```

 - Use a line width of 80-characters in the markdown files
   
 - In the reference manual, prefer descriptions over examples; use examples to
   help when the descriptions are not entirely clear.  Descriptions can outline
   the entire space of correct and incorrect behavior, while it is not always
   clear how to generalize from examples.

   In the future, we should probably prepare copious examples and attach them,
   but our overreliance on examples in earlier docs has left a lot of things
   underspecified.

Examples repository
-------------------

Examples in the user guide should have separate repositories containing the
projects, with the standard layout for a project.  Examples should be linked
from the `Examples` repository.

Myst markdown
-------------

The following formatting features are of particular note if you are already
familiar with markdown but not RST.  For full details, see the [Myst documentation][myst].

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

Moving pages and redirects
--------------------------

If you move a page, you should create a redirect for it on
[the readthedocs.com redirects page][redirects].

[redirects]: https://readthedocs.com/dashboard/certora-certora-prover-documentation/redirects/

If the source URL ends with `$rest` then it redirects everything in that
directory.  Be careful: redirects are considered first to last, so if you are
doing whole-directory redirects but want to override it for specific files, the
specific files come first.  Note that when you "edit" a redirect on this page,
it moves it to the top of the list (AFAICT this is the only way to reorder them).

See also [the RTD documentation on redirects][rtd-redirect].

[rtd-redirect]: https://docs.readthedocs.io/en/stable/user-defined-redirects.html

Note: you can get a list of all the files that ever existed using

```
git log --name-only --pretty="format:" docs
```

Documentation versioning
------------------------

Readthedocs supports the following [kinds of versions][rtd-versioning]:

 - A version called "latest" that follows a specific branch (which is `master`
   by default, but can be changed on the admin tab under [advanced settings][rtd-settings]).

 - A version called "stable" that uses the latest non-prerelease tag

 - Any additional branches or tags that we manually activate (in the [versions tab][rtd-versions]), using the
   branch/tag name as the display name

These versions can also be made private or hidden

[rtd-settings]: https://readthedocs.com/dashboard/certora-certora-prover-documentation/advanced/
[rtd-versions]: https://readthedocs.com/projects/certora-certora-prover-documentation/versions/
[rtd-versioning]: https://docs.readthedocs.io/en/stable/versions.html

Currently, the `latest` documentation refers to the `master` branch, and the
`stable` label is hidden

