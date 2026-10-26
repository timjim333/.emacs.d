# 2. XDG layout: config in ~/.config/emacs, State outside the repo

Date: 2026-10-25. Status: accepted.

`~/.config/emacs` links to this repo, which holds only Config. All State
lives outside it: packages and other data in `~/.local/share/emacs/`,
native-comp and other caches in `~/.cache/emacs/`. `early-init.el` sets
`package-user-dir`, no-littering's folders, the native-comp cache, and the
tree-sitter grammar path to match. Before this, `~/.emacs.d` linked to the
repo and 112 MB of packages, caches, and history sat in the checkout,
hidden by a whitelist `.gitignore`. That made worktrees unusable without a
full reinstall, mixed Emacs 30 bytecode into the 31.1 switch, and made
`git clean` near the repo risky.

## Consequences

- Emacs reads `~/.config/emacs` only if `~/.emacs.d` and `~/.emacs` don't
  exist; the Cutover removes the old link.
- Rolling back to an old commit restores Config but not packages, because
  ELPA and MELPA serve only current versions.
- The `.gitignore` whitelist stays as a safety net for `private.el`.
- `custom.el` is State, because Emacs writes it (Customize, and
  `package-selected-packages`), so it lives in `~/.local/share/emacs/`.
  `private.el` is Config that Tim writes, so it stays in the repo folder,
  gitignored. Look in the data folder before assuming a Customize change
  was lost.
- The repo is renamed from `~/repos/.emacs.d` to `~/repos/emacs-config` at
  the end of the Cutover.
