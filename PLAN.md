# PLAN

Rebuild Tim's Emacs config as an Org notes system plus light IDE-style
coding, on Emacs 31.1 (pgtk) on glacier (Fedora 44, KDE Plasma, Wayland).

## Contents

- [Context](#context)
- [Roadmap](#roadmap)
- [Items](#items)

## Context

- Design research, option comparisons, and proposed decisions:
  [docs/design-notes.md](docs/design-notes.md). These came from a Claude
  Chat session and haven't been grilled yet; item 3 does that.
- Glossary: `CONTEXT.md` (to be written in item 3).
- Accepted decisions: [docs/adr/](docs/adr/).
- Emacs build and install: [docs/emacs-build.md](docs/emacs-build.md).
- Repo conventions and how to test a change: [AGENTS.md](AGENTS.md).
- The old config (forked from SophieBosio/.emacs.d) is in git history at
  `b0cee10`.

## Roadmap

Build Emacs first, then challenge the Chat design before writing more
config. After that, each `init.org` build step is one item, in this order:
Org basics, notes, tasks and calendar, coding, references, extras. Android
is a separate project once the desktop setup is stable.

## Items

- [x] 1. Config skeleton
- [ ] 2. Build and install Emacs 31.1
- [ ] 3. Grill the design
- [ ] 4. Org basics
- [ ] 5. Notes: org-node, journal, capture
- [ ] 6. Tasks, agenda, and org-gcal
- [ ] 7. Coding
- [ ] 8. References
- [ ] 9. Extras

### 1. Config skeleton

**Goals:** a small literate `init.org` with start-up, packages,
housekeeping, look, completion, and git.

**Acceptance tests:** tangles and loads in batch without errors.

**Handoff:** Done in commit `3b9eb1b` (draft PR #1), tested on Emacs 29.3
in a cloud sandbox only. Not yet loaded on Emacs 31.1 on glacier: do that
first when item 4 starts.

### 2. Build and install Emacs 31.1

**Goals:** Emacs 31.1 built from source and installed per
[ADR 0001](docs/adr/0001-build-emacs-31-from-source-into-opt.md), running
as a user daemon, with Fedora's 30.2 left installed as a fallback.

**Acceptance tests:** the checks in
[docs/emacs-build.md](docs/emacs-build.md#checks-after-installing) all pass.

**Handoff:** Installed on 2026-10-25. Passed: version, PATH, tree-sitter,
native compilation, pgtk, SELinux contexts, and the daemon (31.1 from
`/opt`, unit loaded from `/usr/local/lib/systemd/user`). Pending: the KDE
menu check (launch Emacs from the menu and confirm it's 31.1); tick this
item once Tim confirms it. Two install fixes went into the recipe: create
the `/usr/local` folders before `alternatives`, and install the systemd
unit as a plain file instead of an alternatives follower (see Gotchas in
`docs/emacs-build.md`). The daemon currently loads the **old** config from
`main`, which errors on 31.1 (stale Emacs 30 bytecode in `elpa/`); item 4
switches to the new config. Later, optional: cross-check the signing key
against the release announcement, and report the SELinux configure bug
upstream.

### 3. Grill the design

**Goals:** Challenge the decisions proposed in
[docs/design-notes.md](docs/design-notes.md) with `/grill-with-docs`, then
record the glossary in `CONTEXT.md` and each settled decision as an ADR.

**Acceptance tests:** every row of the design notes' Decisions table is
either an ADR or marked as still open; the open questions below each have
an answer or an owner; the items below have agreed goals and tests.

**Handoff:** Not started. Questions to settle:
- Journal: one file per year with a date tree (proposed), or one per day?
- Is `~/org/` the final notes location (it becomes the Syncthing folder)?
- Zotero, or a hand-kept `.bib` file for citar?
- Which Google account and calendars should sync? Is Tim OK creating the
  Google Cloud OAuth client?
- Will the work machine sync these personal notes?
- Capture templates: inbox, journal entry, note, code snippet, web link
  (org-protocol), meeting linked to a calendar event.
- HEIC photos from the phone: convert on the way in, or keep HEIC (see
  "HEIC photos" in the design notes). Needs a test of whether Orgzly
  Revived can attach and show images first.
- Workflow: step 1 was done on one long branch with draft PR #1. Should the
  remaining items each get their own branch and worktree off `main`?
- Emacs versions: re-explain why `systemctl --user enable` bypassed the
  alternatives (Gotchas in `docs/emacs-build.md`), then decide how to
  switch between builds until Fedora ships 31: keep `alternatives`, or
  something simpler such as a `current` symlink in `/opt/emacs`.
- Moving to the new config: `~/.emacs.d` links to this repo's `main`
  checkout. Decide how the new config and a fresh `elpa/` replace the old
  ones (merge order, and whether to keep the old packages folder as a
  fallback).

### 4. Org basics

**Goals:** directories, org-modern, mixed-pitch, the sub/superscript fix,
LaTeX previews with org-fragtog, images (org-download, relative links, HEIC
handling per item 3), Babel for Python and shell, tags vocabulary, and
LOGBOOK settings (`org-log-into-drawer t`).

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started; waits on item 3.

### 5. Notes: org-node, journal, capture

**Goals:** org-node and org-mem, the journal, capture templates designed
with Tim, and org-roam-ui through `org-mem-roamy-db`.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started. `org-mem-roamy-db` driving org-roam-ui is
untested; the fallback is org-roam's own indexer just for the graph.

### 6. Tasks, agenda, and org-gcal

**Goals:** agenda, org-gcal with the "Org" calendar for dated TODOs, and a
sync-host guard so only one machine fetches.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started. Choose between kidd/org-gcal.el and the
martianh fork by which installs cleanly.

### 7. Coding

**Goals:** eglot, tree-sitter modes, flymake with ruff, apheleia, dape,
and envrc.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started.

### 8. References

**Goals:** citar, citar-org-node, and org-noter with pdf-tools.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started.

### 9. Extras

**Goals:** a KDE global shortcut for an emacsclient capture frame,
org-protocol from the browser, gptel, the voice-clip command, the
auto-commit timer, and Syncthing setup.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started.
