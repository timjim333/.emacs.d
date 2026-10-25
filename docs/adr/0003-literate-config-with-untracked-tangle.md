# 3. Literate config, with the tangled file left out of git

Date: 2026-10-25. Status: accepted.

Config is written in `config.org`. A hand-written `init.el` stub tangles
it to `config.el` when the Org file is newer, then loads `config.el`, which
is gitignored. `early-init.el` stays hand-written, because it runs before
anything could tangle it. Tim likes reading the config as prose; leaving
the tangled file out of git removes the double diffs that committing it
caused.

## Considered options

- **Plain Elisp modules in `lisp/`:** errors, `xref`, and byte-compile
  warnings point straight at the source, but the config no longer reads
  as one document.
- **Literate with the tangled `init.el` committed** (the Old config's way):
  every change shows up twice in diffs, and the two can drift.

## Consequences

- Errors and `xref` point at `config.el`; find the matching block in
  `config.org`.
- Tangling uses the built-in Org. Don't install Org from ELPA, or two Org
  versions mix.
