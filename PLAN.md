# PLAN

Rebuild Tim's Emacs config as an Org notes system plus light IDE-style
coding, on Emacs 31.1 (pgtk) on glacier (Fedora 44, KDE Plasma, Wayland).

## Contents

- [Context](#context)
- [Roadmap](#roadmap)
- [Items](#items)

## Context

- Design research, option comparisons, and proposed decisions:
  [docs/design-notes.md](docs/design-notes.md), grilled in item 3.
- Glossary: [GLOSSARY.md](GLOSSARY.md).
- Accepted decisions: [docs/adr/](docs/adr/).
- Emacs build and install: [docs/emacs-build.md](docs/emacs-build.md).
- Repo conventions and how to test a change: [AGENTS.md](AGENTS.md).
- The Old config is at the `old-config` tag; a runnable copy lives in
  `~/repos/emacs-old-config` (see AGENTS.md).

## Roadmap

Build Emacs first, then challenge the Chat design before writing more
config, then cut the daemon over to the new config. After that, each
`config.org` build step is one item, in this order: Org basics, notes,
sync and backup, tasks and calendar, coding, references, extras. From item 5 on, each item
gets its own worktree and branch off `main`. Android
is a separate project once the desktop setup is stable.

## Items

- [x] 1. Config skeleton
- [x] 2. Build and install Emacs 31.1
- [x] 3. Grill the design
- [x] 4. Cutover
- [ ] 5. Org basics
- [ ] 6. Notes: org-node, journal, capture
- [ ] 7. Sync and backup
- [ ] 8. Tasks, agenda, and org-gcal
- [ ] 9. Editing and coding
- [ ] 10. References
- [ ] 11. Extras

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
record the glossary in `GLOSSARY.md` and each settled decision as an ADR.

**Acceptance tests:** every row of the design notes' Decisions table is
an ADR, marked settled, or marked open; the questions below each have an
answer or an owner; each later item gets goals and tests as its topic is
grilled, so they can change with the direction.

**Handoff:** Done on 2026-10-26. Every row of the design notes'
Decisions table is an ADR (0001–0004) or marked settled; every question
here was answered; items 5–8 have agreed tests, and items 9–11 get theirs
when each starts. Settled:
- Version switching: keep `alternatives` with the plain systemd unit;
  `/opt/emacs/README.md` is the reminder.
- [ADR 0002](docs/adr/0002-xdg-layout-state-outside-the-repo.md): XDG
  layout, State outside the repo, repo renamed to `~/repos/emacs-config`.
- [ADR 0003](docs/adr/0003-literate-config-with-untracked-tangle.md):
  literate `config.org`, `init.el` stub, `config.el` untracked.
- [ADR 0004](docs/adr/0004-sync-and-backup.md): Syncthing, git pushed to
  GitHub, plaintext Drive mirror with dated archives, `~/org-calendar/`
  Receive Only on the phone; the work machine never syncs notes.
- Workflow: item 4 (Cutover), then one worktree and branch per item.
- Notes: org-node (reasoning in design notes), hybrid layout, yearly
  Journal, one Inbox per Device, Log entries linked from the Journal.
- Packages from the Old config reviewed (design notes, "Package review").
- XDG for other configs, and where shared VM config lives: proposed in
  agent-env's `global/rule-ideas.md` for an agent-env session.
Not merged: this branch still carries the untested skeleton; item 4
merges it.

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
5. Fedora's `/usr/bin/emacs-pgtk --init-directory` on an `old-config`
   checkout still starts the Old config with the old `elpa/`, and leaves
   no `~/.emacs.d` behind.

**Handoff:** Done on 2026-10-27; tests 1–5 pass. The daemon runs 31.1
with the new config from `~/.config/emacs`, a link to
`~/repos/emacs-config`, with State in `~/.local/share/emacs/` and
`~/.cache/emacs/`. `custom.el` is State (reason in ADR 0002). Round 3
(Tim's terminal) renamed the repo, relinked `~/.config/emacs`, and
repaired the worktree links; the `project-thread` worktree and branch
are deleted (the branch's GitHub copy may remain; everything on it is in
`main`). The Old config is tagged `old-config` and lives in the
`~/repos/emacs-old-config` worktree on branch `old-config-fallback`.
Gotchas, also in AGENTS.md and `docs/emacs-build.md`: `/usr/bin/emacs`
breaks while 31.1 is first in PATH (use `/usr/bin/emacs-pgtk`); the tag
hard-coded `~/.emacs.d`, which the fallback branch fixes; the first start
after installing packages logs native-compiler warnings once. Rounds 1
and 2 went straight to `main`, because the daemon's checkout had to hold
the new config, and the item had no end-of-item review.

### 5. Org basics

**Goals:** directories, org-modern, mixed-pitch, the sub/superscript fix,
LaTeX previews with org-fragtog, images (org-download, relative links, and
a hook converting `.heic` to `.webp`), Babel for Python and shell, tags
vocabulary, LOGBOOK settings (`org-log-into-drawer t`), jinx with `en_GB`
(`hunspell-en-GB`), `global-auto-revert-mode`, `casual` (Agenda and Dired),
org-appear, olivetti, `visual-wrap-prefix-mode`, org-present, focus, and
ligature, and auto-dark with a light theme to pick.

**Acceptance tests:**
1. In a scratch Org file, `x_{i}` renders as a subscript; `snake_case`
   and `~code_here~` stay plain.
2. `$E=mc^2$` shows a rendered preview when the cursor leaves it and the
   source when it enters.
3. Pasting a screenshot with org-download saves it under
   `attachments/<note>/` and inserts a relative `file:` link shown inline.
4. Attaching a `.heic` leaves a `.webp`, and the link points at it.
5. `C-c C-c` on a Python block and on a shell block prints `#+RESULTS:`.
6. Changing a TODO's state writes the note into a `:LOGBOOK:` drawer.
7. With the file open and unmodified, `echo "* test" >> file.org` from a
   shell shows the new heading in the buffer within about 5 seconds.
8. jinx doesn't flag `colour` and does flag `color`.
9. `*bold*` hides its asterisks until the cursor is inside it.
10. `bin/start-check` passes on the finished item (round 1).

**Rounds:**
1. Start check (below).
2. Rendering: directories, org-modern, org-appear, the sub/superscript
   fix, mixed-pitch, olivetti, `visual-wrap-prefix-mode`, and LaTeX
   previews with org-fragtog (tests 1, 2, and 9).
3. Behaviour: Babel, LOGBOOK, tags, auto-revert, and jinx (tests 5–8).
4. Images: org-download, relative links, and HEIC to `.webp` (tests 3
   and 4).
5. Presentation and look: org-present, focus, ligature, casual, and
   auto-dark (tests to agree before the round).

**Round 1, start check.** Goals: a script, `bin/start-check
<checkout>`, that does item 4's "no warnings after a GUI start" check
without Tim at the screen, so items 5–11 can script part of their UI
tests. Not a skill or hook: two GUI starts of about 25 s each are too
slow for a hook (agreed in an agent-env session, 2026-10-27). It runs
`timeout 120 emacs --init-directory <checkout>` with a timer that,
after 25 s, writes a report and calls `kill-emacs`. The report holds
`emacs-version`, `user-emacs-directory`, `package-user-dir`,
`init-file-had-error`, the `*Warnings*` buffer (or "NO WARNINGS
BUFFER"), and `*Messages*`. It starts twice and judges only the second
start, because the first start after a package install logs one-off
native-compiler warnings. Then it checks that `git status --ignored`
lists nothing but `config.el` and `private.el`, and that `~/.emacs.d`
doesn't exist. It exits non-zero on any warning, init error, timeout,
or stray file. A `--daemon` variant makes the same reads through
`emacsclient -e` from the running daemon, without starting Emacs.
Acceptance tests:
1. On a clean `main` checkout it exits 0 and prints the report's path.
2. A `(warn "start-check test")` block in `config.org` makes it exit
   non-zero with that line in the report; the reverse edit restores 0.
3. A `(error "x")` in `config.org` makes it exit non-zero and reports
   `init-file-had-error` as non-nil.
4. A stray file in the checkout (`touch stray`) makes it exit non-zero
   and names the file.
5. `--daemon` reports `~/.config/emacs/` and 31.1 from the running
   daemon.
6. The report folder is printed, and recorded in AGENTS.md "Paths
   outside the repo"; AGENTS.md "Testing a change" uses the script.

**Handoff:** All five rounds done, on branch `org-basics` (not merged;
unticked until an Argon review round needs no code change). The branch also
renames `CONTEXT.md` to `GLOSSARY.md` and ticks item 4. Tests 1–10 and
round 5's (a)–(e) pass, as do `bin/start-check`, the three tool suites
(`test/start-check-test`, `test/gui-ert-test`, `test/screenshot-test`),
and all four `test/*-test.el` files. Tim checked at the screen: the theme
following KDE live (both ways), `C-c I`, and dropping an image file.

Adversarial review: round 1 (Gemini) 0 Findings
([record](docs/reviews/2026-10-29-item-5-diff.md)); round 2 (Sonnet,
Tim's request) 9 Findings, 8 fixed test-first, 1 rejected
([record](docs/reviews/2026-10-29-item-5-diff-r2.md)); round 3 (Sonnet
as fallback, Gemini 503) 8 Findings, verdicts agreed with Tim
([record](docs/reviews/2026-10-30-item-5-diff-r3.md)). F1 is fixed,
F2 moved to item 6, and F3–F6 and F8 are fixed (commits in the
record's Fixes). The new tests covered code that already worked, so
each was seen failing against a temporarily broken copy. F8 confirmed
in Emacs's source that each new pgtk frame queues a toolkit-theme
event (`xg_set_initial_dark_mode`, `src/gtkutil.c`). Tim checked a
start-up in light mode on 2026-10-30: both `bin/start-check` windows
opened light, and it passed.

Tools (usage in AGENTS.md, "Testing a change"):
- `bin/start-check [checkout | --daemon]`: two GUI starts, judges the
  second. Its own tests: `test/start-check-test` (about 4 minutes).
- `test/gui-ert <test-file> [checkout]`: ERT in a GUI Emacs with the
  config. One file per round: `test/org-rendering-test.el`,
  `test/org-behaviour-test.el`, `test/org-images-test.el`, and
  `test/org-look-test.el`. Its own tests: `test/gui-ert-test`.
- `bin/screenshot <checkout> <script.el>`: PNGs at 1600x900 for Tim
  or for checking a UI; works with the screen asleep. Look at one for
  any new UI: it caught a bug the tests missed. Its own tests:
  `test/screenshot-test` (about 3 minutes).
- All three share `bin/checkout.sh` and stop on a path that isn't a
  config checkout.

Decisions (Tim agreed):
- Rendering: olivetti in every Org buffer (`C-c o` toggles); previews
  on open, cached in `~/.cache/emacs/org-latex/`; org-appear also
  reveals links, script braces, and entities. Preview `:scale` 1.2,
  with Org's DPI pinned at 96 (overriding the internal
  `org--get-display-dpi`) so equations follow the text on any monitor;
  Org otherwise uses the largest physical DPI connected (109 on the
  AW3425DWM). A test fails if Org renames the function.
- Tags: Karl Voit's rules (few, controlled, singular, defined), three
  Tag types (GLOSSARY). The `tim-tags` table in `config.org` is the
  vocabulary and is read by the code through Babel `:var`. Kind tags
  aren't inherited; one-off tags allowed, promote recurring ones.
- Babel keeps the "evaluate?" prompt. `org-log-into-drawer t`; what
  gets logged waits for item 8's TODO keywords. jinx set to `en_GB`.
- Images: a folder per note file mirroring its path under
  `~/org/attachments/` (outside `~/org`: `attachments/<name>/` beside
  the file); relative `file:` links; inline at 400 px. `C-c i` pastes
  without org-download's `org-id-get-create` (an ID would make the
  heading an org-node note; add one by hand when wanted).
  `#+DOWNLOADED:` only for web images, keeping the source URL. HEIC
  becomes WebP (quality 85, `-auto-orient`) through an `:around`
  advice on `org-download-image`, keeping its metadata, GPS included;
  the source HEIC is left alone.
- LaTeX previews are redrawn in every Org buffer that shows some
  whenever a theme is enabled (`enable-theme-functions`), since Org
  bakes the text colour into each image; found by a `bin/screenshot`
  shot on 2026-10-30.
- Look: Emacs 31's `toolkit-theme-set-functions` replaces auto-dark
  (it reads GNOME's `color-scheme`, which Plasma keeps in step) and
  loads `doom-nord-light` in light mode. Ligatures in `prog-mode`
  only. casual on `C-o` in Dired and the Agenda. org-present enlarges,
  hides the cursor, and is read-only; focus by `M-x focus-mode`. Test
  (a) calls the hook directly; a test can't flip KDE's mode.
- Images and file names (r8 F3, option B, Tim agreed 1 Nov): a
  buffer with a file name, on disk or not, adds images straight to its
  note's folder with relative links; a buffer with no file refuses
  ("Save this buffer to a file before adding an image"), checked
  before a screenshot is taken. This replaced a staging folder (r4
  F10 to r7) that drew most review Findings. `C-x C-w` sends new
  images to the new name's folder and leaves earlier ones; a new note
  never saved leaves its images in its folder. Both wait for item 6's
  "unlinked attachments" question. Indirect buffers (capture, `C-c
  C-x b`) use the base buffer's folder. Links are relative between
  true names, so a symlinked notes root works.
- Drops: org-download loads with Org (`:demand t`), and
  `tim/org-download-dnd` goes ahead of Org 9.7's buffer-local drop
  handler (r7 F4). It sends image files (by extension, HEIC included)
  and web links to org-download and lets its errors show; any other
  file goes to Org's handler ("What to do with file?"). Not
  `org-download-dnd`: it passes errors on through the obsolete
  `dnd-handle-one-url`, which calls Org's list-taking handler with one
  string (`wrong-type-argument listp`, found by Tim's screen check of
  `30b26d0`; red `c01f30f`, fix `6f6acb5`). Tim's recheck passed
  (1 Nov): a drop and `C-c I` in a buffer with no file both refuse
  with the message; a PDF dropped on a new note gets Org's prompt; a
  JPEG gets a relative link into `attachments/scratch-drop/`.
- Left for later: the `attachments/phone/` "move into this note"
  command (item 7); `org-attach` isn't used.

Open: Tim adding `markup`, `checkbox`, and `planform` to jinx's
personal list (`@` in `M-$`); `en_GB` lacks them.

Gotchas:
- Commit before `bin/start-check`, or new files count as stray.
- With the monitor asleep, its DRM output reads "disconnected" and
  Emacs sees no monitors; GTK floods stderr, so scripts send it to a
  file. `display-pixel-width` is then 0, so `text-scale-increase`
  refuses every change; `test/org-look-test.el` lifts the limit then.
- Some packages update from `post-command-hook` (Org's LOGBOOK note,
  focus); tests run the hook by hand.
- use-package's `:custom` silently does nothing for a plain `defvar`
  (`org-download-annotate-function`); use `setq` in `:config`.
- Python blocks in value mode need `return`; use `:results output`.
- The GUI tests use real State, so temp files land in `recentf`.
- Global auto-revert watches a file (inotify, about 0.1 s) only from
  its next 5 s tick after opening; until then it polls. Test 7 waits
  for the watch.
- `C-c i` gives a `user-error` unless the clipboard offers
  `image/png`. The image tests save and restore Tim's clipboard.
- A test written after its code is run once with the code disabled to
  see it fail.
- The worktree sandbox refuses Bash with `$VAR` paths, or inline
  scripts whose text names a VCS command or Emacs; write a scratchpad
  script and run it with `bash` or `python3`, or use Edit. A refused
  compound command runs none of its parts: a `chmod +x` lost that way
  left `test/gui-ert-test` committed non-executable (exit 126).
- The tool suites run `bin/` and `test/` scripts from the worktree, so
  don't edit those while a suite runs in the background.
- `shellcheck -x` on the scripts: the remaining `~` in quotes are
  display text, on purpose.

Round 5 tests (agreed 2026-10-29): (a) switching KDE to light switches
the theme to `doom-nord-light` within about 5 s; (b) `->` and `!=` show
as ligatures in Python; (c) casual's menu opens from Agenda and Dired;
(d) `org-present` steps through headings; (e) `focus-mode` dims all but
the current paragraph.

Review round 4 (head `afed512`): Gemini 3.8 Flash returned 0
Findings with a 9-token answer
([record](docs/reviews/2026-10-30-item-5-diff-r4.md)), so two more
runs: Sonnet, 5 Findings, 4 accepted
([record](docs/reviews/2026-10-30-item-5-diff-second-r4.md)); and a
Manual run with Gemini 4 Argon on high, 10 Findings, 8 accepted
([record](docs/reviews/2026-10-30-item-5-diff-manual-r4.md)). Fixed
in two rounds: test tools (red `510cf0c`, fixes `fe0b7ff`) and config
(red `fa22d88`, fixes `24a309a`).

Review round 5 (head `df51861`), Argon Manual run: 9 Findings, 8
accepted, F2 rejected, plus a worse sibling of F3 found in triage
([record](docs/reviews/2026-10-31-item-5-diff-r5.md)). Red tests
`8a1f38f`, fixes `6c4d7ca`. Manual-run prompt: read the whole packet
in parts, then end with the count of Findings and of Target files read
(46 here); reuse it. Its exact text is in `~/.claude/skill-ideas.md`
("a Manual run alongside an Automated one").

Review round 6 (head `98d0757`), Argon: 3 Findings, all accepted
([record](docs/reviews/2026-11-01-item-5-diff-r6.md)). Red tests
`a63cb67`, fixes `e31ce6c`: F1 a prefix test on true names, F2 a
`:before` advice on `org-download-image` plus the base buffer's
folder in `tim/org-link-path`, F3 `${1-…}` and an empty-path check in
`bin/checkout.sh` (covers `bin/screenshot` too).

Flaky `test/screenshot-test` "two shots give two PNGs" (twice on
31 Oct and once on 1 Nov, passing on re-runs; the 1 Nov detail
wasn't kept): captured once as `light.png is 688x680`,
the config's start-up frame size, while `dark.png` from the same run
was right. On 1 Nov evening it was `dark.png` instead, the first
shot (log kept: `/tmp/screenshot-test.FV4pbV`,
`/tmp/emacs-screenshot.EdJrUN`), so it isn't specific to the second
frame. Later the same evening a different case failed: "a shot
larger than 1600x900 fails" passed its oversized shot (kept:
`/tmp/screenshot-test.xkVFcR`, `/tmp/emacs-screenshot.U25YVe`), so
frames also get pulled to the usual size. Both passed on a re-run.
The frame size isn't what Emacs asked for; not the 5 s wait. Hypothesis, unproven: PlasmaZones
restoring its remembered geometry late. Next: loop the test with
PlasmaZones stopped (Tim, at the screen) to confirm, then check the
frame size before each shot.

Review round 7 (head `84a2057`), Argon: 5 Findings, all accepted
([record](docs/reviews/2026-11-01-item-5-diff-r7.md)); fixes `14e5a46`
and `039462c`. Tim's screen check of a drop passed after the second.
Its staging fixes (F1–F3, F5) were removed in round 8.

Review round 8 (head `bda9ed9`), Sonnet, standing in for Argon (16% of
its weekly quota left, resetting about 6 Nov): 4 Findings, all
accepted ([record](docs/reviews/2026-11-01-item-5-diff-r8.md)). F1
(quit deletes staging an auto-save links) and F2 (unlinked staged
images kept) went with the staging, per F3's option B; F4 `test/gui-ert`
now fails a file with no tests. Red tests `9d89028`, fix `30b26d0`.
After it, every suite and all four `test/*-test.el` files passed
(1 Nov), screenshot-test on a re-run (below).

Next: review round 9 with Argon (Manual run) once its quota resets.
Item 5 merges only after a clean Argon round. When a round needs no
code change: tick the item and merge to `main` from Tim's terminal
(this worktree session can't touch the main checkout): `git merge
--no-ff org-basics`, run the tests on `main`, restart the daemon
(`systemctl --user restart emacs`), and run `bin/start-check
--daemon`. Then remove the worktree and branch. Tim's Dired and Agenda
walkthrough is in item 8's handoff.

### 6. Notes: org-node, journal, capture

**Goals:** org-node and org-mem (why: design notes, "org-node notes"),
the yearly Journal, the hybrid layout in `~/org/`, and four capture
templates: `t` TODO, `j` journal entry, `w` web link (org-protocol), and
`s` code snippet, all to `inbox.org` except `j`. New notes come from
`org-node-find`; `C-c C-w` in a capture refiles it straight to a heading.
org-protocol registered with the desktop so the browser can call `w`.
toc-org for topic files read on GitHub away from home. An `l` capture
for Log entries (prompts for a project, files a dated heading with an
`:ID:` under its `Log` heading, and adds a linked headline to today's
Journal), and a "refile as log entry" command for phone captures.

**Acceptance tests:**
1. `org-node-find` with part of an existing title lists that note;
   confirming new text creates a note with an `:ID:`.
2. `org-node-insert-link` inserts an `id:` link, and the target's
   backlinks panel lists the source.
3. Two `j` captures on one day add two entries under one heading for
   today in `journal/2026.org`, creating year, month, and day headings
   if missing.
4. `t` and `s` captures land in `inbox.org` with `C-c C-c`, and under the
   chosen heading with `C-c C-w`.
5. The browser bookmarklet creates a `w` entry with the page title and
   URL in `inbox.org`.
6. Indexing `~/org` leaves no errors in `*Messages*`.
7. Saving a topic file with a `:TOC:` heading refreshes its table of
   contents.
8. One `l` capture creates an entry under the chosen project's `Log`
   heading and a Journal line whose link opens that entry.

**Handoff:** Not started. Tim wants to save as he types (likely
`auto-save-visited-mode`, which saves on idle): measure a save's cost
once org-node re-indexes on save.
First settle how image links survive a move (item 5 review r3 F2),
and whether one "unlinked attachments" command also covers images a
never-saved new note leaves behind (item 5 r8 F3). Saving as (`C-x C-w`) into another
folder breaks them the same way. Links are relative to the note, so
refiling a heading from `inbox.org` into `notes/coding.org` leaves
`[[file:attachments/inbox/x.png]]` pointing at a missing file. Verify
in Org's source that refile doesn't rewrite them, then choose: a
refile or extract hook that rewrites links, or links that don't depend
on the note's location. org-roam-ui moved to item 11 (optional).
About three months into daily use, review the tags (`org-tags-view`):
drop unused ones, merge near-duplicates, and promote recurring one-offs
into the `tim-tags` table in `config.org`.
When this item is in daily use, remove the `~/repos/emacs-old-config`
worktree and its `old-config-fallback` branch (the tag stays).

### 7. Sync and backup

**Goals:** per [ADR 0004](docs/adr/0004-sync-and-backup.md): Syncthing on
glacier and the phone, `.stignore` for `.git`, staggered versioning on
glacier, `tim/resolve-sync-conflicts` (ediff), the hourly auto-commit and
push to a private GitHub repo, and the nightly `rclone sync` to Drive with
`--backup-dir` (90 days) and `--max-delete 50`. Start by testing Orgzly
Revived on Waydroid: can it attach and show images, where does it save
them, and does its agenda show org-gcal's plain timestamps (if not, the
phone ignores `~/org-calendar/` instead)? Then a job on glacier converts any `.heic` arriving in
`~/org/attachments` to `.webp`, rewrites the links, and removes the HEIC
(git keeps it). A later round moves the jobs to the baby-log OCI VM as a
trusted peer.

**Acceptance tests:**
1. A note created in Orgzly appears on glacier within 1 minute while both
   are online.
2. Editing one file on both devices with the phone in airplane mode gives
   a Conflict copy; `tim/resolve-sync-conflicts` opens it in ediff, and
   the copy is gone after merging.
3. The phone's copy of `~/org` has no `.git` folder.
4. The hourly job commits and pushes; the commit shows on GitHub.
5. After deleting a file locally and running the backup, it's gone from
   Drive's `current/` and present in `archive/<date>/`.
6. With the limit set to 2, deleting 3 files makes the backup refuse and
   leaves Drive unchanged.
7. A HEIC attached on the phone ends up as `.webp` on glacier with the
   link rewritten, after the job runs.
8. The Orgzly test results (images, agenda) are recorded in the design
   notes.

**Handoff:** Not started. The VM round waits on baby-log's VM item. Open,
for an agent-env session: whether VM-level config shared by two projects
moves to its own repo. Tune `--max-delete` once there's data on normal
weekly deletions.

### 8. Tasks, agenda, and org-gcal

**Goals:** agenda, and org-gcal for one Google account (primary
calendar first; Tim to name any others), one file per calendar in
`~/org-calendar/` (a separate Syncthing folder, Receive Only on the
phone), events two-way. No push of dated TODOs to a calendar:
Orgzly reminds about TODOs. A sync-host guard so only one machine fetches
(glacier now, the VM later). The meeting capture template.

**Acceptance tests:**
1. `org-gcal-fetch` fills `~/org-calendar/<name>.org` with this week's events,
   and they show in the agenda.
2. Moving an event's time in Org and syncing changes it in Google
   Calendar, and the reverse.
3. The meeting capture creates an event that appears in Google Calendar.
4. On a host other than the sync host, `org-gcal-fetch` refuses with a
   message.
5. Eight days after first login, sync still works without logging in
   again ("In production" status).
6. Editing a calendar file in Orgzly leaves glacier's copy unchanged, and
   Syncthing on the phone offers "Revert local changes".

**Handoff:** Not started. Tim hasn't used Dired or the Agenda: start
with a walkthrough of their ideas and concepts (marks, flags, and
`wdired`; agenda files, views, and dispatch), using casual's `C-o`
menus (item 5). Choose between kidd/org-gcal.el and the
martianh fork by which installs cleanly. Set the OAuth client to "In
production", or refresh tokens expire after 7 days; ID and secret go in
`private.el`.

### 9. Editing and coding

**Goals:** eglot with basedpyright (`typeCheckingMode = "standard"`
globally, so it matches Pylance and the `pyright` CLI), tree-sitter
modes, flymake with ruff, apheleia, dape, and envrc. Editing: expreg,
multiple-cursors, vundo, `electric-pair-mode`, `auto-save-visited-mode`,
a `C-a` toggle between indentation and line start, eros, built-in
editorconfig, verb, windmove, wgrep, git-timemachine, git-link,
rainbow-delimiters, hl-todo, and forge (token in `~/.authinfo.gpg`).

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started.

### 10. References

**Goals:** optional; start when Tim wants citations. Zotero (import the
Mendeley library first) with Better BibTeX exporting `~/org/refs.bib`,
citar, citar-org-node, and org-noter with pdf-tools and pdf-view-restore.

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started. Hobby scale: tracking papers and ideas.

### 11. Extras

**Goals:** a KDE global shortcut for an emacsclient capture frame,
gptel, the voice-clip command, nov (EPUB), elfeed (RSS), and,
optionally, org-roam-ui through `org-mem-roamy-db` (try at about 100
linked notes; untested, fallback is org-roam's own indexer).

**Acceptance tests:** to agree when the item starts.

**Handoff:** Not started.
