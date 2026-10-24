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
[docs/emacs-build.md](docs/emacs-build.md#checks-after-installing) all pass,
and KDE's launcher shows Emacs with its icon.

**Handoff:** Built and `make install`ed on 2026-10-25, configured with
`--with-selinux` (configure summary: SELinux, tree-sitter, and native
compilation all `yes`). The first `alternatives --install` linked the
binaries and `.desktop` files but not the service or icon, because their
parent folders were missing; the fix is to create them and re-run step 6.
Next: re-run step 6, then run the checks and steps 7 onwards. Still to do
later: cross-check the signing key against the release announcement, and
consider reporting the SELinux configure bug upstream (both in
`docs/emacs-build.md`).

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
