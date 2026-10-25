# Org notes system: design notes

Last updated 2026-10-25. Consolidated from the design discussion with Tim
in Claude Chat (the original working doc, with round-by-round history:
https://claude.ai/artifact/4JmVXL9vudaSeydRmS1iJ5). The decisions below are
**proposed**: PLAN.md item 3 grills them into `CONTEXT.md` and ADRs. Items,
status, and open questions live in `PLAN.md`; the Emacs build is in
`docs/emacs-build.md`.

## Contents

- [Context](#context)
- [Decisions](#decisions)
- [Notes layout (draft)](#notes-layout-draft)
- [org-node notes](#org-node-notes)
- [Journal options](#journal-options)
- [Calendar and tasks (org-gcal)](#calendar-and-tasks-org-gcal)
- [Sync options considered](#sync-options-considered)
- [Media plan](#media-plan)
- [Python environments (direnv)](#python-environments-direnv)
- [Coding stack (PLAN item 9)](#coding-stack-plan-item-9)

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
| Emacs | Accepted: [ADR 0001](adr/0001-build-emacs-31-from-source-into-opt.md). Build 31.1 from source into `/opt`, registered with `alternatives`; switch to Fedora's package once it ships 31. |
| Config | Accepted: [ADR 0002](adr/0002-xdg-layout-state-outside-the-repo.md) (`~/.config/emacs`, State outside the repo) and [ADR 0003](adr/0003-literate-config-with-untracked-tangle.md) (literate `config.org`, tangled file untracked). One top-level section per build step. |
| Notes engine | Settled (no ADR; see "org-node notes"): **org-node** with org-mem. Notes use `:ID:` properties and `id:` links. org-roam-ui (the graph) is optional, in Extras. |
| Layout | Settled (no ADR): **hybrid**, like OneNote notebooks: topic files whose headings are nodes, plus the Journal. Split a heading into its own file only when it grows (`org-node-extract-subtree`). |
| Journal | Settled (no ADR): **one file per year with a date tree** (`journal/2026.org`, `file+olp+datetree`). The phone may edit it; a day's heading gets an `:ID:` only when first linked to. |
| Tasks | Settled (no ADR): Org TODOs in `projects.org` and inside notes. Orgzly shows and reminds about them on the phone; no push to a Google calendar (revisit if missed). |
| Calendar | Settled (no ADR): **org-gcal** for one Google account, events two-way, one file per calendar. One sync host: glacier now, the baby-log VM later. OAuth client set to "In production". |
| Sync | Accepted: [ADR 0004](adr/0004-sync-and-backup.md). Syncthing (glacier, phone, later the VM as a trusted peer), one Inbox per device, git history pushed to GitHub, nightly plaintext `rclone sync` to Drive with dated archives. `global-auto-revert-mode` on. The work machine never syncs notes. |
| Media | All media in `~/org/attachments/<note>/`, linked with **relative `file:` links** (not `attachment:`, which other devices can't resolve). HEIC photos from the phone: see "HEIC photos" below (open). |
| Python envs | **direnv** with the `envrc` package: a `.envrc` per repo activates the uv, pixi or conda environment, and eglot, ruff and Babel use it. |
| Coding | eglot, tree-sitter `*-ts-mode`s, flymake + ruff, apheleia, dape, project.el. Drop lsp-mode, lsp-ui, flycheck, origami, smartparens, lispy and projectile. |
| Completion | Settled (no ADR): Vertico + **vertico-posframe**, Orderless, Marginalia, Consult, Embark, Corfu (still better than the built-ins), which-key, helpful, and **casual** menus (Agenda and Dired first). |
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

**Why org-node (settled 2026-10-26, no ADR):** notes are plain Org with
`:ID:` properties and `id:` links, a format org-roam and plain Org read
too, so switching engines means reinstalling packages, not converting
notes. That's also why no ADR: it's cheap to reverse. Chosen over org-roam
for speed and no SQLite database, and over Denote because Denote works on
files only and the layout is hybrid. The main risk is org-node's single
author; if it stalls, move to org-roam unchanged.


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
| Syncthing | **Chosen** for live sync ([ADR 0004](adr/0004-sync-and-backup.md)). Syncs over the internet through relays, not only on a LAN. Peer-to-peer, near-instant, no storage limits, good Android app (Syncthing-Fork); the VPS can join as an always-on peer. Downsides: `.sync-conflict` files if two devices edit the same file before syncing; devices must be online together (the VPS fixes this). |
| Google Drive + rclone | Backup only: nightly `rclone sync` with `--backup-dir` dated archives. `rclone bisync` isn't live and handles conflicts poorly. |
| Dropbox | Not chosen: the free tier allows only 3 devices, and Orgzly's Dropbox sync covers notes but not attachments. |
| git + GitHub | History only, via an hourly auto-commit and push (attachments included). Not used for live sync: not live, and needs SSH keys on the phone. |

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

### HEIC photos (open, discussed 2026-10-25)

Tim keeps the S24 Ultra's camera on HEIF for quality and storage, and
doesn't want to convert photos by hand.

- **Proposed:** keep HEIC in the phone's gallery, and convert once,
  automatically, where an image enters the notes. Use WebP (about 30%
  smaller than JPEG at the same quality, and read natively by Emacs,
  Android, and browsers) or JPEG at quality 85.
  - On glacier: a hook on `org-attach` and `org-download` converts `.heic`
    to `.webp` with `magick` and links the converted file.
  - On the phone: Samsung Gallery may have a "convert HEIF when sharing"
    setting (unverified), so photos shared to Orgzly or the notes folder
    arrive as JPEG.
  - Safety net: `(setq image-use-external-converter t)`, so Emacs displays
    any HEIC that slips through by calling ImageMagick in a separate
    process. Emacs 31.1 calls the deprecated `convert` command, which
    ImageMagick 7 prints a warning for; test it once.
- **Why not keep HEIC everywhere:** it works in Emacs (through the
  converter) and probably in Orgzly (Android decodes HEIC itself), but
  browsers, GitHub, HTML export, and machines without RPM Fusion's
  `libheif-freeworld` can't show it. The converter also appears to
  re-convert on every display, so image-heavy notes would open slowly.
- **Why not build Emacs `--with-imagemagick`:** it puts ImageMagick's large,
  bug-prone parsers inside the long-running Emacs daemon, which also
  displays untrusted images (email in Gnus, pages in eww). Emacs made it
  opt-in in version 27 for this reason. The ImageMagick command-line tool
  is fine.
- **glacier already has** ImageMagick 7.1.2 and `libheif-freeworld`, and
  `magick -list format` shows HEIC and AVIF as read-write.
- **Blocking question:** can Orgzly Revived attach or show images, and
  where does it save them? Its F-Droid listing doesn't say, and image
  attachment is a long-standing Orgzly feature request (orgzly-android
  issue #1). Test before choosing the phone-side step.

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

## Coding stack (PLAN item 9)

| Need | Package | Tools |
| --- | --- | --- |
| Language server | eglot (built in) | basedpyright or pyright, clangd, typescript-language-server, bash-language-server, vscode-json-languageserver, texlab |
| Linting | flymake + ruff | |
| Formatting | apheleia | ruff format, prettier, clang-format, shfmt |
| Syntax | `*-ts-mode` | python, c, bash, js, ts, tsx, html, css, json, yaml, markdown; Emacs 31 can auto-install grammars (`treesit-auto-install-grammar`) |
| Debugging | dape | debugpy, gdb |
| LaTeX | AUCTeX + texlab + pdf-tools | |
