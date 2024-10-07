# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.

import os
import sys

from docsinfra.sphinx_utils import TAGS, CVL2Lexer

sys.path.insert(0, os.path.abspath("./util"))


# -- Project information -----------------------------------------------------

project = "Certora Prover Documentation"
copyright = "2024, Certora, Inc"
author = "Certora, Inc"

# The full version, including alpha/beta/rc tags
release = "0.0"


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    "myst_parser",
    "sphinx.ext.todo",
    "sphinx_rtd_theme",
    "sphinx_design",
    "docsinfra.sphinx_utils.codelink_extension",
    "docsinfra.sphinx_utils.includecvl",
    "sphinx_copybutton"
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ["templates"]

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = [
    "_build",
    "templates",
    "Thumbs.db",
    ".DS_Store",
    "old",
    "README.md",
    "EVMVerifier",
    "docs/cvl/Test/*",
    "docs/user-guide/multicontract/LiquidityPoolExample",
    "docs/cvl/cvl2/CVL2Examples",
    "docs/cvl/cvl2/cvl1",
    "docs/cvl/cvl2/cvl2",
    ".github",
    "Examples/*",
]


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ["static"]

# The Certora logo
html_logo = "static/Certora_Logo_Black.svg"


# -- codelink_extension configuration ----------------------------------------
code_path_override = "Examples/"
link_to_github = True


# -- prologue and epilog -------------------------------------------------------
# A string of reStructuredText that will be included at the beginning of every source
# file that is read.
# Here we use the prologue to add inline cvl code and solidity code.
rst_prolog = """
.. role:: cvl(code)
   :language: cvl

.. role:: solidity(code)
   :language: solidity
"""


# -- Custom setup ------------------------------------------------------------

# Do not show todo list unless in dev build
todo_include_todos = tags.has(TAGS.is_dev_build)  # noqa: F821


def setup(sphinx):
    sphinx.add_css_file("custom.css")
    sphinx.add_lexer("cvl", CVL2Lexer)
