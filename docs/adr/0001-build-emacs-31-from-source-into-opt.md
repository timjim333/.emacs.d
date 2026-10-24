# 1. Build Emacs 31.1 from source into /opt, registered with alternatives

Date: 2026-10-25. Status: accepted.

## Context

The new config targets Emacs 31.1 (Org 9.8, tree-sitter grammar
auto-install, and pgtk improvements). Fedora 44 ships 30.2. glacier runs
KDE Plasma on Wayland.

## Decision

Build the stable 31.1 release with pgtk, AOT native compilation,
tree-sitter, modules, and SELinux, into `/opt/emacs/emacs-31.1`. Put links
in `/usr/local` through an `emacs-opt` alternative, which leaves Fedora's
`emacs` package installed and untouched as a fallback. The recipe is in
`docs/emacs-build.md`.

## Alternatives considered

- **Fedora's package (30.2):** no build work, but it's a version behind the
  config's target. Switch to it once Fedora ships 31.
- **COPR (alternateved/bleeding-emacs):** packaged, but tracks development
  snapshots rather than the stable release, and adds a third-party repo.
- **`make install` straight into `/usr/local`:** simplest, but no clean way
  to keep two builds side by side or to uninstall.

## Consequences

- Each new release means a rebuild (AOT makes the first build slow) and a new
  alternatives entry with a higher priority; the old prefix stays available
  until deleted.
- The systemd user unit can't be an alternatives link (`enable` resolves
  the link and pins one version), so it's a plain file in `/usr/local`
  that runs `/usr/local/bin/emacs`. How to switch versions is up for review
  in PLAN.md item 3.
- `-march=native` ties the binary to Zen 5-class CPUs; don't copy it to
  another machine.
- Fedora's tree-sitter packaging can drift from what Emacs expects, as it
  did on the first build; the workarounds are in `docs/emacs-build.md`.
