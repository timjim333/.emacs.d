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
  error, gave `one.png` and exit 0, with no error printed. To fix: load
  the script inside the runner's `condition-case`; test that case.
- **F2:** true by reading. To fix: require `early-init.el` in the
  checkout, and fail when `init-file-had-error` is set.
- **F3:** the mechanism is right (`package-installed-p` doesn't see the
  earlier run's packages, so they install again), but the outcome isn't
  a break: `package-unpack` runs `make-directory … t` and unpacks over
  the old copy, so the install works after a fresh download. A test of
  the install path needs the network. Rejected by Tim.
- **F4:** to fix: fail on a shot larger than 1600x900 or a failed
  `magick`, and use `nullglob`.
- **F5:** to fix: `require_checkout` in the `--daemon` branch, and fail
  if the report's `user-emacs-directory` isn't the checkout.
- **F6:** to fix: grep only the header lines.
- **F7:** reproduced in Sonnet's run (empty `--init-directory` is the
  current folder). To fix with that F1: check the arguments and the `cd`.
- **F8:** reproduced: a test file signalling an error on load hung
  2m0s, then "no results written", exit 124, with the error hidden. To
  fix: load the test file inside `tim/gui-ert-run` and write any error
  to the report.
- **F9:** main claim confirmed: `org-latex-preview '(16)` and
  `org-clear-latex-preview` use `point-min`/`point-max`
  (`lisp/org/org.el` in 31.1), which respect narrowing. To fix: redraw
  in `org-with-wide-buffer`; test with the buffer narrowed. Side point
  rejected by Tim: a fragment being edited under org-fragtog shows as
  an image after a redraw until the cursor re-enters it; rare, and the
  fix would lean on org-fragtog's internals.
- **F10:** confirmed in `files.el`: `set-visited-file-name` calls
  `(set-auto-mode t)`, which keeps the mode and skips `org-mode-hook`;
  org-download falls back to `.` when its folder is nil. To fix: also
  run on `after-set-visited-file-name-hook`, and make `C-c i` refuse in
  a buffer with no file. Capture buffers (indirect, no file name) are
  item 6's: take the folder from the base buffer.
