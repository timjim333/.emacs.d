# CLAUDE.md

Tim's Emacs config, being rebuilt from scratch as an Org mode notes system plus
light IDE-style coding. Full design, decisions and reasoning:
`docs/design-notes.md` (read it before starting work).

## How this repo works

- `init.org` is the source of truth. It is a literate config: code blocks
  tangle to `early-init.el` and `init.el`. Never edit the `.el` files by hand.
- Saving `init.org` inside Emacs re-tangles it (`tim/tangle-init`). From a
  shell: `emacs --batch --eval '(progn (require (quote org)) (org-babel-tangle-file "init.org"))'`.
- Commit `init.org`, `init.el` and `early-init.el` together.
- `.gitignore` is a whitelist (`/*` then `!/file`). Add a `!/path` line for any
  new top-level file or folder you want tracked.
- `custom.el` and `private.el` (secrets: OAuth IDs, calendar IDs) are never
  committed. `var/` and `etc/` are created by no-littering and ignored.

## Conventions

- Target Emacs 31.1, pgtk build, Fedora 44 KDE Plasma (Wayland).
- Packages via `use-package` with `use-package-always-ensure t`; archives
  GNU ELPA > NonGNU ELPA > MELPA. Built-in packages use `:ensure nil`.
- Personal function prefix: `tim/`.
- Each top-level heading in `init.org` is one build step; keep prose short,
  one short paragraph per block saying why.
- Prefer built-ins (eglot, flymake, project.el, treesit, which-key) over
  bigger third-party equivalents.
- Tim's preferences: plain Emacs keybindings, dark theme (doom-nord),
  surgical changes, no speculative features, explain trade-offs and ask
  before big direction changes.

## Status

- Branch `claude/project-thread-t4i08u`, draft PR #1 (into `main`).
- Step 1 (skeleton) is done. Next: step 2, Org basics. See the build order
  and open questions in `docs/design-notes.md`.

## Testing a change

1. Tangle (above), then load in batch to catch errors:
   `emacs --batch -l early-init.el -l init.el --eval '(message "ok")'`
2. Then start the real Emacs (`emacs --init-directory ~/.emacs.d` or restart
   the daemon: `systemctl --user restart emacs`) and check `*Messages*` and
   `*Warnings*`.
