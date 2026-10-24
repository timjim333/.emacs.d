# Org notes system: design notes and handoff

Last updated 2026-10-24. Consolidated from the design discussion with Tim
(the original working doc, with round-by-round history:
https://claude.ai/artifact/4JmVXL9vudaSeydRmS1iJ5). This file reflects the
current decisions, not the history.

## Context

- Fedora 44, KDE Plasma (Wayland). Ryzen 7 9800X3D, 64 GB RAM, Radeon 9070 XT.
- Notes used to live in OneNote. At work Tim uses one big Org file with a
  level-1 heading per date, and has found that doesn't scale well.
- Personal notes will cover: hobby projects, coding notes, holiday planning,
  upcoming tasks, research papers (PDFs) and ideas about them. These include
  diagrams, screenshots and equations.
- Uses Google Calendar today and wants it integrated, ideally two-way.
- Codes mainly in Python, sometimes C and bash, plus JS/TS/HTML for side
  projects (baby-log, flight-tracker). Also works with JSON, Markdown and
  LaTeX. Has used PyCharm and VSCodium, and will keep VSCodium for heavy
  debugging and refactoring.
- Wants to learn Org properly: tags (currently poorly maintained), LOGBOOK,
  images, code blocks, capture templates.
- Android access is planned as a separate piece of work; the design keeps
  it easy.
- The old config (forked from SophieBosio/.emacs.d) is in git history at
  `b0cee10` ("Tim's current customisations").

## Decisions

| Area | Decision |
| --- | --- |
| Emacs | Build 31.1 from source with pgtk, AOT native-comp and tree-sitter, into `/opt/emacs/emacs-31.1`, registered with `alternatives` (recipe below). Switch to Fedora's package once it ships 31. |
| Config | Fresh literate `init.org`, one top-level section per build step. |
| Notes engine | **org-node** (with org-mem) as the main tool. org-roam is installed only to drive **org-roam-ui** for the graph, through `org-mem-roamy-db` (still to be tested; fallback is running org-roam's own indexer just for the graph). Notes use `:ID:` properties and `id:` links, a format shared by org-node, org-roam and plain Org. |
| Layout | **Hybrid**: a few topic files whose headings are nodes, plus a journal. Split a heading into its own file only when it grows (`org-node-extract-subtree`). |
| Journal | Proposed: **one file per year with a date tree** (`journal/2026.org`, built by `org-capture` `file+olp+datetree`). Tim is still weighing this against one file per day; see open questions. |
| Tasks | Org TODOs in `projects.org` and inside notes. Dated TODOs (SCHEDULED or DEADLINE) are pushed to a dedicated Google calendar called "Org". |
| Calendar | **org-gcal**, two-way, one Org file per Google calendar. Only one machine syncs (desktop for now, maybe a VPS later) to avoid duplicate IDs. On the phone, use the Google Calendar app. |
| Sync | **Syncthing** for live sync (desktop, phone, later an Oracle free-tier VPS as an always-on peer). Hourly **auto-commit to a private GitHub repo** from the desktop for history. Nightly **rclone copy to Google Drive** as offsite backup. |
| Media | All media in `~/org/attachments/<note>/`, linked with **relative `file:` links** (not `attachment:`, which other devices can't resolve). |
| Python envs | **direnv** with the `envrc` package: a `.envrc` per repo activates the uv, pixi or conda environment, and eglot, ruff and Babel use it. |
| Coding | eglot, tree-sitter `*-ts-mode`s, flymake + ruff, apheleia, dape, project.el. Drop lsp-mode, lsp-ui, flycheck, origami, smartparens, lispy and projectile. |
| Completion | Vertico + **vertico-posframe** (centred pop-up; Tim likes it), Orderless, Marginalia, Consult, Embark, Corfu. |
| Look | **doom-nord** (Tim likes Nord's blues; `doom-nord-aurora` is an alternative), `org-modern`, Inter for prose, JetBrains Mono for code. |
| Equations | `org-use-sub-superscripts '{}` (and the same for export), so only `x_{i}` and `e^{2}` turn into sub/superscripts and `~code_here~` or snake_case stay plain. LaTeX fragment previews with `org-fragtog`. |
| References | Web: `org-insert-link`. Papers: one `.bib` (Zotero + Better BibTeX if Tim uses Zotero), built-in `org-cite`, **citar** + **citar-org-node** (https://github.com/krisbalintona/citar-org-node), **org-noter** + pdf-tools. |
| Spelling | jinx (needs `enchant2-devel` and Emacs built with modules). |

## Notes layout (draft)

```
~/org/                    the synced folder (Syncthing)
  inbox.org               quick captures, processed weekly
  inbox-phone.org         captures made on the phone (avoids sync conflicts)
  projects.org            active projects and their TODOs
  journal/2026.org        date tree: 2026 > 2026-10 October > 2026-10-24 Saturday
  notes/                  topic files (e.g. coding.org, hobbies.org, travel.org,
                          research.org) whose headings are org-node nodes
  calendar/               org-gcal files, one per Google calendar (desktop syncs)
  attachments/<note>/     images, audio, diagrams; relative file: links
  attachments/phone/      drop folder for phone photos/recordings
  refs.bib                bibliography
```

## org-node notes

- Speed: the author measured indexing 3,000 nodes in about 2 s with org-node,
  against about 3 min with org-roam. It is very actively developed, mostly by
  one author (meedstrom), and has a smaller community.
- Built-in equivalents of consult-org-roam: `org-node-find`,
  `org-node-insert-link`, `org-node-complete-at-point-mode` (turns a word into
  a link as you complete it), `org-node-grep` (Consult + ripgrep over all
  notes), and a backlinks panel (org-node-context).
- Not built in, and small to write if Tim wants them: a list of a note's
  outgoing links, and a Consult buffer source for narrowing to notes.
- Missing compared with org-roam: `roam:` links, org-roam-protocol (use plain
  org-protocol capture instead).
- Mobile: neither org-node nor org-roam runs on Android; the phone sees plain
  Org files. Whether Orgzly Revived follows `id:` links is still unverified.

## Journal options

| Layout | Pros | Cons |
| --- | --- | --- |
| One file per day | Native to org-node daily notes; each day is a graph node; tiny files that never conflict | Many files; empty days still create one; harder to scroll a week |
| One file per year with a date tree (proposed) | Close to Tim's dated-headings habit; few files; `org-capture` builds the tree | Phone and desktop editing the same day can conflict; a day is only a graph node if it gets an ID (a capture template can add one) |
| One file for everything | Simplest | Grows forever, slower on the phone, most conflict-prone |

## Calendar and tasks (org-gcal)

- Package: kidd/org-gcal.el. An actively updated fork exists
  (martianh/org-gcal.el, last commit May 2026, adds attendance status).
  Check which one installs cleanly before choosing.
- Setup: a Google Cloud project with the Calendar API enabled, an external
  consent screen, and a "Desktop" OAuth client. Set `org-gcal-client-id`,
  `org-gcal-client-secret` and `org-gcal-fetch-file-alist` in `private.el`.
  Tokens go through oauth2-auto into an encrypted plstore; set
  `epg-pinentry-mode` to `'loopback`.
- Behaviour: `org-gcal-fetch` pulls; `org-gcal-sync` pulls and pushes edits
  to existing events; new events need `org-gcal-post-at-point` (or a capture
  template that posts on finish). On conflict, the server's version wins.
- Duplicate IDs happen when two machines both fetch. Make the sync host a
  single setting (a hostname check) so only one machine runs it. Later, a
  VPS can run a headless Emacs to sync around the clock.
- Google Tasks has no maintained Emacs integration, hence the "Org"
  calendar for dated TODOs.
- Limits: one Google account (share other calendars to it); recurring events
  need care. If the experience disappoints, fall back to read-only display.

## Sync options considered

| Option | Verdict |
| --- | --- |
| Syncthing | **Chosen** for live sync. Peer-to-peer, near-instant, no storage limits, good Android app (Syncthing-Fork); the VPS can join as an always-on peer. Downsides: `.sync-conflict` files if two devices edit the same file before syncing; devices must be online together (the VPS fixes this). |
| Google Drive + rclone | Backup only. `rclone bisync` isn't live and handles conflicts poorly. |
| Dropbox | Not chosen: the free tier allows only 3 devices, and Orgzly's Dropbox sync covers notes but not attachments. |
| git + GitHub | History only, via an hourly systemd-timer auto-commit from the desktop. Not used for live sync. |

## Media plan

- Images: `org-download` pastes from the clipboard or takes a Spectacle
  screenshot, then saves the file and links it. Shown inline at a set width
  (`#+attr_org: :width 400`).
- Markup: open the image in Spectacle's annotator, Krita or ksnip with one
  key, save, then refresh the image in Emacs.
- Diagrams: draw.io or Excalidraw exported to SVG/PNG, or PlantUML, Mermaid
  or Graphviz Babel blocks that render inline.
- Voice clips: a small custom command records with `pw-record` into the
  attachments folder and inserts a link; clips play in mpv. `org-media-note`
  adds timestamped notes on audio and video.
- Video and PDFs: linked and opened externally (mpv) or in pdf-tools.
- From the phone: media dropped in `attachments/phone/`, then a command
  moves it into the current note.

## Python environments (direnv)

direnv loads and unloads environment variables per directory. A shell hook
(`eval "$(direnv hook bash)"` in `~/.bashrc`) runs a folder's `.envrc` when you
`cd` into it and undoes it when you leave. A new or changed `.envrc` only runs
after `direnv allow`. The `envrc` Emacs package does the same per buffer.

```bash
# uv project (.venv created by `uv sync`)
source .venv/bin/activate

# pixi project
watch_file pixi.lock
eval "$(pixi shell-hook)"

# conda / miniforge env
eval "$(conda shell.bash hook)"
conda activate myenv
```

## Coding stack (step 5)

| Need | Package | Tools |
| --- | --- | --- |
| Language server | eglot (built in) | basedpyright or pyright, clangd, typescript-language-server, bash-language-server, vscode-json-languageserver, texlab |
| Linting | flymake + ruff | |
| Formatting | apheleia | ruff format, prettier, clang-format, shfmt |
| Syntax | `*-ts-mode` | python, c, bash, js, ts, tsx, html, css, json, yaml, markdown; Emacs 31 can auto-install grammars (`treesit-auto-install-grammar`) |
| Debugging | dape | debugpy, gdb |
| LaTeX | AUCTeX + texlab + pdf-tools | |

## Building Emacs 31.1

Emacs 31.1 was released on 2026-08-24 and bundles Org 9.8; Fedora 44 ships
30.2. pgtk is the right build for KDE Wayland: native Wayland, sharp
fractional scaling, smooth scrolling and a working clipboard. A COPR build
(alternateved/bleeding-emacs) was considered; building the stable release
into `/opt` was preferred.

```bash
# Layout:
#   /opt/emacs/README.txt             install notes
#   /opt/emacs/src/emacs-31.1.tar.xz  source archive (+ .sig)
#   /opt/emacs/src/emacs-31.1/        unpacked source and build tree
#   /opt/emacs/emacs-31.1/            installed prefix
# The archive unpacks to a folder named emacs-31.1, so it lives under src/
# to stay clear of the install prefix of the same name.

# 1. Build dependencies
sudo dnf builddep emacs
sudo dnf install libgccjit-devel tree-sitter-devel

# 2. Own the folder once, so builds and installs need no sudo
sudo mkdir -p /opt/emacs/src && sudo chown -R "$USER": /opt/emacs

# 3. Source, with signature check
cd /opt/emacs/src
curl -O https://ftp.gnu.org/gnu/emacs/emacs-31.1.tar.xz
curl -O https://ftp.gnu.org/gnu/emacs/emacs-31.1.tar.xz.sig
gpg --verify emacs-31.1.tar.xz.sig   # import the key named in the release mail first
tar xf emacs-31.1.tar.xz && cd emacs-31.1

# 4. Configure
PREFIX=/opt/emacs/emacs-31.1
./configure --prefix="$PREFIX" \
  --with-pgtk --with-native-compilation=aot \
  --with-tree-sitter --with-modules --without-compress-install \
  --with-systemduserunitdir="$PREFIX/lib/systemd/user" \
  CFLAGS="-O2 -march=native -pipe"

# 5. Build and install
make -j"$(nproc)" && make install

# 6. Register with alternatives (name "emacs-opt" avoids Fedora's own "emacs")
sudo alternatives --install /usr/local/bin/emacs emacs-opt "$PREFIX/bin/emacs" 3110 \
  --follower /usr/local/bin/emacsclient emacsclient-opt "$PREFIX/bin/emacsclient" \
  --follower /usr/local/lib/systemd/user/emacs.service emacs-service-opt "$PREFIX/lib/systemd/user/emacs.service" \
  --follower /usr/local/share/applications/emacs.desktop emacs-desktop-opt "$PREFIX/share/applications/emacs.desktop" \
  --follower /usr/local/share/applications/emacsclient.desktop emacsclient-desktop-opt "$PREFIX/share/applications/emacsclient.desktop" \
  --follower /usr/local/share/icons/hicolor/scalable/apps/emacs.svg emacs-icon-opt "$PREFIX/share/icons/hicolor/scalable/apps/emacs.svg"
# Priority 3110 = 31.1.0. Switch versions: sudo alternatives --config emacs-opt

# 7. Check, then run as a daemon
hash -r; emacs --version
systemctl --user daemon-reload && systemctl --user enable --now emacs
```

Why these flags:
- `-march=native` resolves to `znver5` on the 9800X3D; the binary then only
  runs on similar CPUs. `-O2` is the safe default.
- `aot` native-compiles all bundled Lisp up front.
- `--with-modules` is needed by jinx and vterm.

Check after building: `M-x emacs-version`, `(treesit-available-p)`,
`(native-comp-available-p)`, and `(featurep 'pgtk)`.

## Build order and status

1. [x] Skeleton: early-init, packages, housekeeping, look, completion, git
   (commit `3b9eb1b`, draft PR #1).
2. [ ] Org basics: directories, org-modern, mixed-pitch, the sub/superscript
   fix, LaTeX previews + org-fragtog, images (org-download, relative links),
   Babel for python and shell, tags vocabulary, LOGBOOK settings
   (`org-log-into-drawer t`).
3. [ ] Notes: org-node + org-mem, journal, capture templates (designed with
   Tim), org-roam-ui through `org-mem-roamy-db`.
4. [ ] Tasks, agenda and org-gcal with the "Org" calendar and a sync-host
   guard.
5. [ ] Coding: eglot, tree-sitter, ruff, apheleia, dape, envrc.
6. [ ] References: citar, citar-org-node, org-noter.
7. [ ] Extras: a KDE global shortcut for an emacsclient capture frame,
   org-protocol from the browser, gptel, the voice-clip command, auto-commit
   timer, Syncthing setup. Then Android (separate piece of work).

## Open questions for Tim

- Journal: one file per year (proposed) or one file per day?
- Is `~/org/` the final notes location (it becomes the Syncthing folder)?
- Does Tim use Zotero, or should citar read a hand-kept `.bib` file?
- Which Google account and calendars should sync? Is Tim OK creating the
  Google Cloud OAuth client?
- Will the work machine sync these personal notes too?
- Capture templates still to design together: inbox, journal entry, note,
  code snippet, web link (org-protocol), meeting linked to a calendar event.

## Environment notes for Claude sessions

- The cloud sandbox used so far couldn't reach ELPA or MELPA (proxy refused
  the connection). The skeleton was tested on Emacs 29.3 by cloning packages
  from GitHub and generating autoloads. On Tim's machine, test with the real
  Emacs 31.1 instead.
