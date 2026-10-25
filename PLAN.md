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
- Glossary: [CONTEXT.md](CONTEXT.md).
- Accepted decisions: [docs/adr/](docs/adr/).
- Emacs build and install: [docs/emacs-build.md](docs/emacs-build.md).
- Repo conventions and how to test a change: [AGENTS.md](AGENTS.md).
- The old config (forked from SophieBosio/.emacs.d) is in git history at
  `b0cee10`.

## Roadmap

Build Emacs first, then challenge the Chat design before writing more
config, then cut the daemon over to the new config. After that, each
`config.org` build step is one item, in this order: Org basics, notes,
tasks and calendar, coding, references, extras. From item 5 on, each item
gets its own worktree and branch off `main`. Android
is a separate project once the desktop setup is stable.

## Items

- [x] 1. Config skeleton
- [x] 2. Build and install Emacs 31.1
- [ ] 3. Grill the design
- [ ] 4. Cutover
- [ ] 5. Org basics
- [ ] 6. Notes: org-node, journal, capture
- [ ] 7. Tasks, agenda, and org-gcal
- [ ] 8. Coding
- [ ] 9. References
- [ ] 10. Extras

### 1. Config skeleton

**Goals:** a small literate `init.org` with start-up, packages,
housekeeping, look, completion, and git.

**Acceptance tests:** tangles and loads in batch without errors.

**Handoff:** Done in commit `3b9eb1b` (draft PR #1), tested on Emacs 29.3
in a cloud sandbox only. Not yet loaded on Emacs 31.1 on glacier: item 4
does that.

### 2. Build and install Emacs 31.1

**Goals:** Emacs 31.1 built from source and installed per
[ADR 0001](docs/adr/0001-build-emacs-31-from-source-into-opt.md), running
as a user daemon, with Fedora's 30.2 left installed as a fallback.

**Acceptance tests:** the checks in
[docs/emacs-build.md](docs/emacs-build.md#checks-after-installing) all pass.

**Handoff:** Done on 2026-10-25. All checks passed: version and PATH,
tree-sitter, native compilation, pgtk, SELinux contexts, the daemon (31.1
from `/opt`, unit loaded from `/usr/local/lib/systemd/user`), and the KDE
menu (launches 31.1). The recipe in `docs/emacs-build.md` is the one that
actually worked, including two install fixes: create the `/usr/local`
folders before `alternatives`, and install the systemd unit as a plain file
rather than an alternatives follower. Fedora's 30.2 is still installed as a
fallback. Gotchas: the daemon loads the **old** config from `main`, which
errors on 31.1 because of stale Emacs 30 bytecode in `elpa/`; item 4
replaces it. Optional loose ends: cross-check
the signing key against the 31.1 release announcement, and report the
SELinux configure bug upstream. Not merged: this branch also carries the
untested new config (item 1); item 4 merges it.

### 3. Grill the design

**Goals:** Challenge the decisions proposed in
[docs/design-notes.md](docs/design-notes.md) with `/grill-with-docs`, then
record the glossary in `CONTEXT.md` and each settled decision as an ADR.

**Acceptance tests:** every row of the design notes' Decisions table is
an ADR, marked settled, or marked open; the questions below each have an
answer or an owner; each later item gets goals and tests as its topic is
grilled, so they can change with the direction.

**Handoff:** In progress (round 1 committed 2026-10-25). Settled so far:
- Version switching: keep `alternatives` with the plain systemd unit (see
  `docs/emacs-build.md`); `/opt/emacs/README.md` written as a reminder.
- [ADR 0002](docs/adr/0002-xdg-layout-state-outside-the-repo.md): XDG
  layout, State outside the repo, repo renamed to `~/repos/emacs-config`.
- [ADR 0003](docs/adr/0003-literate-config-with-untracked-tangle.md):
  literate `config.org`, `init.el` stub, `config.el` untracked.
- Workflow: new item 4 (Cutover), then one worktree and branch per item.
- Fork leftovers (`images/`, `snippets/`, `README.org`) go in item 4.
- Completion: current set plus `casual`; Corfu stays.
- Notes in `~/org/`; one Inbox per device; yearly Journal, phone may edit.
- Keep the old `elpa/` until item 6 is in daily use, then delete it.
- XDG for other configs: proposed in agent-env's `global/rule-ideas.md`.

Still to grill, in order:
- Notes layout, org-node, and capture templates (inbox, journal entry,
  note, code snippet, web link via org-protocol, meeting linked to a
  calendar event).
- Sync: Syncthing, VPS, auto-commit, rclone; will the work machine sync
  these personal notes?
- Google Calendar: which account and calendars; is Tim OK creating the
  Google Cloud OAuth client?
- References: Zotero, or a hand-kept `.bib` file for citar?
- HEIC photos: test whether Orgzly Revived attaches and shows images
  first, on Waydroid (`waydroid-drive` skill) or the phone.
- Quick checks on coding, look, equations, and spelling.

### 4. Cutover

**Goals:** switch the daemon to the new config per ADRs 0002 and 0003:
tag `b0cee10` as `old-config`; convert `init.org` to `config.org` with an
`init.el` stub and a hand-written `early-init.el` that sets the State
paths; delete `images/`, `snippets/`, and `README.org`, and add a short
`README.md`; test with `emacs --init-directory <worktree>`; merge to
`main`; replace `~/.emacs.d` with `~/.config/emacs`; restart the daemon;
finally rename the repo to `~/repos/emacs-config`.

**Acceptance tests:**
1. `emacs --batch` loading the config prints no errors.
2. `*Warnings*` is empty after a GUI start on 31.1.
3. `emacsclient -e user-emacs-directory` shows `~/.config/emacs/`, and
   packages are under `~/.local/share/emacs/`.
4. `git status` in the repo is clean after a start: no State in it.
5. Fedora's `/usr/bin/emacs --init-directory` on an `old-config` checkout
   still starts the Old config with the old `elpa/`.

**Handoff:** Not started. Old `elpa/` stays in the main checkout (untracked)
until item 6 is in daily use. Paths outside the repo go in `AGENTS.md`.
Claude's project memory and worktrees are keyed to the old repo path, so
rename last.

### 5. Org basics

**Goals:** directories, org-modern, mixed-pitch, the sub/superscript fix,
LaTeX previews with org-fragtog, images (org-download, relative links, HEIC
handling per item 3), Babel for Python and shell, tags vocabulary, and
LOGBOOK settings (`org-log-into-drawer t`).

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started; waits on items 3 and 4. Add `global-auto-revert-mode`
and `casual` (Agenda and Dired menus).

### 6. Notes: org-node, journal, capture

**Goals:** org-node and org-mem, the journal, capture templates designed
with Tim, and org-roam-ui through `org-mem-roamy-db`.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started. `org-mem-roamy-db` driving org-roam-ui is
untested; the fallback is org-roam's own indexer just for the graph.

### 7. Tasks, agenda, and org-gcal

**Goals:** agenda, org-gcal with the "Org" calendar for dated TODOs, and a
sync-host guard so only one machine fetches.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started. Choose between kidd/org-gcal.el and the
martianh fork by which installs cleanly.

### 8. Coding

**Goals:** eglot, tree-sitter modes, flymake with ruff, apheleia, dape,
and envrc.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started.

### 9. References

**Goals:** citar, citar-org-node, and org-noter with pdf-tools.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started.

### 10. Extras

**Goals:** a KDE global shortcut for an emacsclient capture frame,
org-protocol from the browser, gptel, the voice-clip command, the
auto-commit timer, and Syncthing setup.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started.
