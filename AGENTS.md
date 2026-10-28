# AGENTS.md

Tim's Emacs config, being rebuilt from scratch as an Org mode notes system
plus light IDE-style coding. Read these before starting work:

- `PLAN.md`: roadmap, items, and handoff notes. Start from the next item.
- `GLOSSARY.md`: the glossary. Use its terms.
- `docs/design-notes.md`: the Decisions table (each row settled or an
  ADR), option comparisons, and the reasons behind settled choices.
- `docs/emacs-build.md`: how Emacs 31.1 is built and installed on glacier.
- `docs/adr/`: accepted decisions.

## How this repo works

The layout follows ADRs 0002 and 0003. `~/.config/emacs` links to this
repo, which holds only Config.

- `config.org` is the source of truth. `init.el` is a hand-written stub
  that tangles it to `config.el` when the Org file is newer, then loads
  that. `config.el` is gitignored; never edit it by hand.
- `early-init.el` is hand-written (it runs before anything could tangle).
  It sets every State path; change it when adding a package that writes
  somewhere no-littering doesn't cover.
- Saving `config.org` inside Emacs re-tangles it (`tim/tangle-config`).
- `.gitignore` is a whitelist (`/*` then `!/file`). Add a `!/path` line for any
  new top-level file or folder you want tracked.
- `private.el` (secrets: OAuth IDs, calendar IDs) sits in the repo folder
  and is never committed.

## Paths outside the repo

- `~/.config/emacs`: link to this repo, read by Emacs.
- `~/.local/share/emacs/`: State. `elpa/` (packages), `var/` and `etc/`
  (no-littering), `tree-sitter/` (grammars), and `custom.el`.
- `~/.cache/emacs/eln-cache/`: native-compiled code; safe to delete.
- `~/.cache/emacs/org-latex/`: LaTeX preview images (set in
  `early-init.el`, so no `ltximg/` lands in `~/org`); safe to delete.
- `~/.config/enchant/en_GB.dic`: jinx's personal word list (enchant
  writes it when `@` is chosen in `M-$`); not in the repo.
- `~/repos/emacs-old-config/`: a worktree on branch `old-config-fallback`
  (the `old-config` tag plus one fix so it never writes to `~/.emacs.d`),
  holding the Old config's `elpa/` and other State. Start it with
  `/usr/bin/emacs-pgtk --init-directory ~/repos/emacs-old-config`, not
  `/usr/bin/emacs` (see `docs/emacs-build.md`, "Gotchas"). Remove it once
  item 6 is in daily use.
- `~/.emacs.d` must not exist: if it does, Emacs reads it instead of
  `~/.config/emacs`.
- `/opt/emacs/`: Emacs source, build tree, and install prefix; see
  `docs/emacs-build.md`. Links in `/usr/local` are managed by the
  `emacs-opt` alternative.
- `~/org/`: the Notes folder (planned; Syncthing, git, Drive backup).
- `~/org-calendar/`: org-gcal's calendar files (planned; Syncthing only).
- `/tmp/emacs-start-check.*/`: one folder of reports per
  `bin/start-check` run, printed by the script; nothing cleans them up
  except the reboot that clears `/tmp`.

## Conventions

- Target Emacs 31.1, pgtk build, Fedora 44 KDE Plasma (Wayland).
- Packages via `use-package` with `use-package-always-ensure t`; archives
  GNU ELPA > NonGNU ELPA > MELPA. Built-in packages use `:ensure nil`.
- Personal function prefix: `tim/`.
- Each top-level heading in `config.org` is one build step; keep prose short,
  one short paragraph per block saying why.
- Prefer built-ins (eglot, flymake, project.el, treesit, which-key) over
  bigger third-party equivalents.
- Tim's preferences: plain Emacs keybindings, dark theme (doom-nord),
  surgical changes, no speculative features, explain trade-offs and ask
  before big direction changes.

## Testing a change

1. Load a checkout in batch to catch errors (this tangles first):
   `emacs --batch --init-directory <checkout> -l <checkout>/early-init.el -l <checkout>/init.el --eval '(message "ok")'`
2. Run `bin/start-check <checkout>` (about 50 s, opens two Emacs
   windows). It starts Emacs twice and fails on any warning or init
   error at the second start, on a stray file in the checkout (anything
   untracked or ignored but `config.el`, `private.el`, and `.claude/`),
   or if `~/.emacs.d` exists. Commit first, or new files count as stray.
   `bin/start-check --daemon` reads the running daemon instead; its
   `*Warnings*` covers the daemon's whole run, not just its start.
3. For changes to the script itself, run `test/start-check-test`
   (about 3.5 minutes, on throwaway clones of HEAD).
4. Behaviour that needs a frame (rendering, images, cursor movement)
   is tested in ERT files run by `test/gui-ert test/<file>.el
   [checkout]`, which starts a GUI Emacs with the config. Run every
   `test/*-test.el` file before merging.
