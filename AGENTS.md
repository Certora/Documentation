# Repository guidelines

You are a world-class formal verification expert, specialized in Certora's CVL.
Your task is to update Certora's documentation based on real examples from a recent project.
Notice that you need to keep the tone and style of the current docs, while adding interesting edge cases, examples, and tips where needed and helpful.
Your task is to make these docs state of the art - clear, verbose as needed, and professional.
This is a super important task - good luck!


## Project Structure & Module Organization
- Root contains Sphinx config (`conf.py`), entry page (`index.rst`), and build scripts (`Makefile`, `make.bat`).
- `docs/` holds most content pages (reStructuredText and MyST Markdown).
- `static/` contains images and custom CSS (e.g., `custom.css`, logos).
- `Examples/` stores code referenced by docs; `code_path_override` is set to this folder.
- `util/` has Sphinx helpers used in `conf.py`.
- Built artifacts go to `build/` (created by Sphinx targets).

## Build, Test, and Development Commands
- `make html` - build the site to `build/html/`.
- `make linkcheck` - verify external and internal links.
- `make spelling` - spell-check docs using `spelling_wordlist.txt`.
- `make` - runs `spelling` then `html` (default target).
- Install deps: `python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`.

## Coding Style & Naming Conventions
- Content format: prefer `.rst`; `.md` (MyST) is supported via `myst_parser`.
- Headings: sentence case; one H1 per page; stable anchors.
- Filenames: lowercase-with-dashes, group by topic inside `docs/`.
- Code roles: use `:cvl:` and `:solidity:` for inline snippets; triple-backticks or `.. code-block::` for blocks.
- Lists/notes: use Sphinx directives (`.. note::`, `.. warning::`) where appropriate.

## Pull Requests & Review Checklist

Use this lightweight checklist to keep PRs smooth and CI‑green.

- Title and scope
  - Clear, scannable subject in imperative mood, ≤72 chars.
  - Limit scope; avoid mixing refactors with content edits.
  - Example: `docs: add rounding envelopes; fix broken includes`.

- Description structure
  - Motivation: why this change improves the docs (e.g., reduces timeouts, avoids vacuity).
  - Origin/source: link to real specs when applicable (e.g., `aave-v3-horizon/tree/main/certora/stata/specs`).
  - Key updates: bullets of files/sections touched and notable patterns added.
  - Validation: include `make spelling` and `make linkcheck` results.
  - Risks and follow‑ups: slot/offset cautions, anchors, future pages.

- Linking and anchors
  - Prefer HTTPS and stable top‑level links. Avoid deep anchors that may 404.
  - For external code examples, prefer GitHub permalinks over local `.. include::`.
  - For new pages, add them to a relevant `.. toctree::` (or index) so RTD builds include them.
  - Use ASCII hyphens (`-`) instead of non‑breaking dashes.

- Backticks and code fences
  - Inline code: use single backticks like `` `make spelling` ``.
  - Code blocks: triple backticks with a language when possible.
  - Prefer `:cvl:` and `:solidity:` roles for inline snippets in reST contexts.

## Local Build & CI Runbook

Run everything inside a virtual environment and verify locally before pushing.

1) Create venv and install deps
   - `python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`

2) Spelling (project files only)
   - `make spelling`
   - To emulate CI’s check and see errors inline:
     - `find build/spelling -name "*.spelling" -type f | xargs cat > errors.txt`
     - `[[ ! $(cat errors.txt) ]] || (echo && echo "errors:" && cat errors.txt && false)`
   - Fix content first (typos, ASCII hyphens), only then add truly domain‑specific words to `spelling_wordlist.txt`.
   - Do not add generic words; prefer content fixes.

3) Links
   - `make linkcheck`
   - Replace broken or redirected URLs with stable destinations.
   - Convert missing local includes to external links (GitHub) when Examples are not vendored.

4) HTML build
   - `make html` then open `build/html/index.html`.

5) Read the Docs
   - Ensure new pages are in a `toctree` and not excluded in `conf.py`.
   - Exclude non‑doc files (like `AGENTS.md`) via `exclude_patterns` to avoid spelling noise.

6) GitHub checks and status
   - Use the GitHub UI or `gh pr view <branch> --json statusCheckRollup` to inspect failing jobs.
   - Typical failures:
     - Spelling: fix typos or add terms to `spelling_wordlist.txt`.
     - Linkcheck: update or remove broken links, prefer HTTPS.
     - RTD build: ensure includes/`toctree` coverage; avoid missing local files.

## Patterns from this project

- Avoid non‑breaking hyphens (U+2010–U+2015). Use `-` only.
- Prefer external GitHub links over `literalinclude`/`cvlinclude` to local Examples not in the repo.
- When adding a new pattern page (e.g., rounding envelopes), wire it into the relevant patterns `index.md`.
- Slot/offset hooks are powerful but brittle; document storage layout assumptions and prefer named access paths.

## PR message template (suggested)

- Title: `Docs: <short outcome> (from <origin>)`
- Description:
  - Summary (what changed, why)
  - Origin (e.g., `aave-v3-horizon/tree/main/certora/stata/specs`)
  - Motivation (timeouts avoided, vacuity mitigations, clarity)
  - Key updates (bulleted file list)
  - Build & QA (spelling/linkcheck/HTML ok)
  - Risks (slot/offset hooks, anchors)
  - Follow‑ups (optional extractions, screenshots)

## CI hygiene (what we changed in this repo)

- `conf.py`: `exclude_patterns` includes `AGENTS.md` to keep meta‑guidance out of spelling/link builds.
- Spelling: keep `spelling_wordlist.txt` tight; add only domain‑specific terms.
- Links: use stable GitHub URLs for Examples, avoid brittle anchors.

## Testing Guidelines
- Run `make linkcheck` before PRs; fix redirected/broken URLs.
- Run `make spelling`; add project terms to `spelling_wordlist.txt` instead of disabling checks.
- Validate local build opens cleanly: `open build/html/index.html`.

## Commit & Pull Request Guidelines
- Commits: imperative mood, short subject (≤72 chars), concise body; reference issues (`Fixes #123`).
- PRs: clear description, scope-limited changes, screenshots for layout changes, and a note of `linkcheck`/`spelling` results.
- Keep diffs focused; avoid mixing refactors with content edits.

## Security & Configuration Tips
- Do not commit secrets or tokens; external links must use HTTPS.
- `requirements.txt` is generated from `_requirements.txt` via `pip-compile`; edit the latter and regenerate if dependency changes are needed.
- Read the Docs builds use `.readthedocs.yaml`; ensure new files are included by Sphinx (not excluded in `conf.py`).
