# Review: item 5 diff (Org basics)

- **Target:** diff of item 5, base `eb8b2bc`, head `afed512`
- **Route:** Manual (Antigravity extension, Reviewer profile)
- **Reviewer:** gemini-4-argon, thinking high (second run: gemini-3.8-flash found nothing, [record](2026-10-30-item-5-diff-r4.md))
- **Round:** 4, after [2026-10-30-item-5-diff-r3](2026-10-30-item-5-diff-r3.md)
- **Date:** 31 Oct 2026
- **Result:** 10 Findings; 8 accepted, 1 partly rejected, 1 rejected. Claude had missed 9.
- **Raw answer:** [2026-10-30-item-5-diff-manual-r4.findings.json](2026-10-30-item-5-diff-manual-r4.findings.json); run details in [2026-10-30-item-5-diff-manual-r4.meta.json](2026-10-30-item-5-diff-manual-r4.meta.json)

Run on a copy of round 4's workspace with the Gemini results cleared,
in parallel with Sonnet's
[second run](2026-10-30-item-5-diff-second-r4.md). The prompt asked it
to read the whole packet in parts and to end with a count; it reported
10 Findings and 33 Target files read. F7 is the same problem as
Sonnet's F1, found independently; one fix covers both.

## Verdicts

| ID | Severity | Category | Location | Claim | Verdict | Missed by Claude | Repeat of |
|---|---|---|---|---|---|---|---|
| F1 | major | bug | `bin/screenshot:44` | A load error in the shot script is hidden; partial shots exit 0 | Accept | yes | — |
| F2 | minor | bug | `bin/screenshot:29` | Accepts a non-checkout and ignores `init-file-had-error` | Accept | yes | — |
| F3 | minor | bug | `bin/screenshot.el:35` | Reusing a `SCREENSHOT_ELPA` folder breaks | Reject | — | — |
| F4 | minor | bug | `bin/screenshot:61` | Padding crops oversized shots and ignores `magick` failures | Accept | yes | — |
| F5 | minor | bug | `bin/start-check:84` | `--daemon` checks neither the checkout nor the daemon's directory | Accept | yes | — |
| F6 | minor | bug | `bin/start-check:41` | `judge` greps the whole report, not the header | Accept | yes | — |
| F7 | minor | bug | `test/gui-ert:18` | A mistyped checkout runs the tests on the current folder | Accept | yes | — |
| F8 | minor | bug | `test/gui-ert:22` | A test file's load error hangs for 120 s and is hidden | Accept | yes | — |
| F9 | minor | bug | `config.org:332` | Theme redraw of LaTeX previews misses narrowed-away text | Partly rejected | yes | — |
| F10 | minor | bug | `config.org:449` | Attachment folder not updated after `C-x C-w` or with no file | Accept | yes | — |

## Triage notes

- **F1:** reproduced: a script that adds one shot, then signals an
  error, gave `one.png` and exit 0, with no error printed. Fixed in
  `fe0b7ff`: the runner loads the script (`SCREENSHOT_SCRIPT`) inside
  its `condition-case`; red test `510cf0c`.
- **F2:** true by reading. Fixed in `fe0b7ff`: `bin/checkout.sh`
  requires a git checkout with `early-init.el`, and the runner fails on
  `init-file-had-error`; red tests `510cf0c`.
- **F3:** the mechanism is right (`package-installed-p` doesn't see the
  earlier run's packages, so they install again), but the outcome isn't
  a break: `package-unpack` runs `make-directory … t` and unpacks over
  the old copy, so the install works after a fresh download. A test of
  the install path needs the network. Rejected by Tim.
- **F4:** fixed in `fe0b7ff`: fails on a shot larger than 1600x900, a
  failed `magick`, or no PNGs (`nullglob`); red tests `510cf0c`.
- **F5:** fixed in `fe0b7ff`: `require_checkout` in the `--daemon`
  branch, and the report's new `user-emacs-directory-truename` line
  must be the checkout (GUI starts too); red tests `510cf0c`.
- **F6:** fixed in `fe0b7ff`: only the header is grepped; red tests
  `510cf0c` (fake reports whose *Messages* hold the passing lines).
- **F7:** reproduced in Sonnet's run (empty `--init-directory` is the
  current folder). Fixed with that F1 in `fe0b7ff`; red test `510cf0c`.
- **F8:** reproduced: a test file signalling an error on load hung
  2m0s, then "no results written", exit 124, with the error hidden.
  Fixed in `fe0b7ff`: `tim/gui-ert-run` loads the file
  (`GUI_ERT_TESTS`) and writes any error to the report; red test
  `510cf0c`.
- **F9:** main claim confirmed: `org-latex-preview '(16)` and
  `org-clear-latex-preview` use `point-min`/`point-max`
  (`lisp/org/org.el` in 31.1), which respect narrowing. To fix: redraw
  in `org-with-wide-buffer`; test with the buffer narrowed. Side point
  rejected by Tim: a fragment being edited under org-fragtog shows as
  an image after a redraw until the cursor re-enters it; rare, and the
  fix would lean on org-fragtog's internals. Fixed in `24a309a`, red
  test `fa22d88`.
- **F10:** confirmed in `files.el`: `set-visited-file-name` calls
  `(set-auto-mode t)`, which keeps the mode and skips `org-mode-hook`;
  org-download falls back to `.` when its folder is nil. To fix: also
  run on `after-set-visited-file-name-hook`, and make `C-c i` refuse in
  a buffer with no file. Capture buffers (indirect, no file name) are
  item 6's: take the folder from the base buffer. Changed with Tim on
  31 Oct: rather than refusing, a buffer with no file stages images
  under `var/org-download-staging/`, moves them to the note's folder on
  the first save, and deletes them if the buffer is killed unsaved or
  Emacs quits, as its text is discarded too. `~/.cache` was rejected:
  staged images are the only copy, so they aren't cache. Indirect
  buffers take the base buffer's folder now (two lines). Fixed in
  `24a309a`, red test `fa22d88`.
