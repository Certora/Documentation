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
sys.path.insert(0, os.path.abspath('./util'))

# -- Project information -----------------------------------------------------

project = 'Certora Prover Documentation'
copyright = '2022, Certora, Inc'
author = 'Certora, Inc'

# The full version, including alpha/beta/rc tags
release = '0.0'


# -- General configuration ---------------------------------------------------

import sphinx_rtd_theme

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'myst_parser',
    'sphinx_rtd_theme',
    'sphinx.ext.todo',
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = [
    '_build',
    'templates',
    'Thumbs.db',
    '.DS_Store',
    'old',
    'README.md',
    'EVMVerifier',
    'docs/cvl/Test/*',
    'docs/user-guide/multicontract/LiquidityPoolExample',
    'docs/cvl/cvl2/CVL2Examples',
    'docs/cvl/cvl2/cvl1',
    'docs/cvl/cvl2/cvl2',
    'docs/user-guide/ConstantProductExample',
    '.github'
    ]


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'sphinx_rtd_theme'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['static']

# -- Custom setup ------------------------------------------------------------

todo_include_todos = True

def setup(sphinx):
    sphinx.add_css_file('custom.css')
    from highlight import CVLLexer
    sphinx.add_lexer("cvl", CVLLexer)
    from pygments_lexer_solidity import SolidityLexer
    sphinx.add_lexer("solidity", SolidityLexer)

