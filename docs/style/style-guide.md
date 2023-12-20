Certora Documentation Style Guide
=================================

```{contents}
```

Process
-------

This section outlines the steps you should take before submitting a PR. 

```{contents}
:local:

```

### Make the documentation build

When you create a documentation PR, Read the Docs will automatically attempt to
compile it to generate the HTML documentation.  You can see generated
documentation at the bottom of the PR:

![screenshot of PR section that says "Readthedocs build failed!"](ci-build.png)

If the documentation didn't build successfully, the "details" link to the right
will point you to the error messages.  You will need to log in to
readthedocs.com with your Certora Google credentials in order to see the error
messages (otherwise you will get a **404 Not Found** page).

The error messages can be hard to find because they usually go past the end of
the window:

![top of the readthedocs error messages](rtd-errors-head.png)

You need to scroll down to find the long lines:

![left side of the actual error messages](rtd-errors-left.png)

and then scroll to the right:

![readthedocs error messages](rtd-errors-right.png)

Ask in #documentation if you need help fixing the errors.

### Make the spell checker pass

The other CI check that must pass before a PR can be merged is the spell check.

![screenshot of PR section that says "spell and link check ... failing"](ci-spelling.png)



### Read the generated documentation

### Link to the generated documentation in the PR

### Include a Jira ticket number in the PR header

### Don't add "prover" to the dictionary

### Don't add code to dictionary

### Check external links

Structure
---------

### User guide should be task-oriented

### User guide should include advice

### User guide should avoid extraneous detail

### Reference manual should be feature-oriented

### Reference manual should include complete details

### Reference manual should avoid advice

### Reference manual information should be compact

### Use title case for page headers

### Use sentence case for section headers

### Check the navigation bar

### Add contents blocks where appropriate

### Start every section with an introduction

CVL Manual Pages
----------------

### Use the standard CVL page structure

### Update the syntax section

Linking
-------

### Link to terms when they are first used

### Always link to command-line options

### Cross-link between user guide and reference manual

### Include links in sentences where possible

### Use reference-style link syntax

### Add glossary entries where appropriate

### Link glossary entries to the documentation

### Reference Jira tickets in TODO comments

### TODO: label format

### TODO: github links

Audience and content
--------------------

### Assume the reader is familiar with Solidity

### Assume the reader is familiar with basic DeFi

### Assume the reader is familiar with CVL

### Assume the reader is not familiar with Prover internals

 - SMT
 - TAC
 - Verification condition
 - SAT / UNSAT
 - `assume`

### Add a caution box when discussing an unsound feature

Examples
--------

### Use ERC20 or ERC4626 wherever possible

### Use DeFi examples wherever possible

### Link to the `Examples` repository

### Include descriptive text

### Include relevant snippets

### Elide irrelevant details

### Use CVLDoc comments

### (User guide) introduce running examples

### (Reference manual) use simple examples

### Don't rely on examples alone

### TODO: snake case for examples?

### Include assert messages

Grammar, style, phrasing
------------------------

### Hyphenation

### Avoid passive voice

### Use complete sentences

### Address the reader

### Avoid long bullets

### Capitalize and punctuate bullets correctly

### Use a new paragraph when starting a new idea

### Mirror language from an introductory paragraph

### Use Oxford commas

### Use footnotes for important but uncommonly needed information

### Be consistent in parallel constructions

### Prefer brevity

### Use "the Prover" or "the Certora Prover"

Images
------

### Include screenshots where appropriate

### Ensure screenshot text is legible

### Add captions for images

Common non-English idioms
-------------------------

### Avoid "it is recommended that"

Formatting
----------

### Wrap lines at 80 characters

### Use 4 spaces for indentation

### Include the language for code blocks

### Avoid bold and italic markup

### Use code font for things the user would type

### Prefer bulleted lists over numbered lists

