# Review: item 5 diff (Org basics)

- **Target:** diff of item 5, base `eb8b2bc`, head `afed512`
- **Route:** Automated (`review-auto`)
- **Reviewer:** claude-sonnet-5-5, effort high (second run: gemini-3.8-flash found nothing, [record](2026-10-30-item-5-diff-r4.md))
- **Round:** 4, after [2026-10-30-item-5-diff-r3](2026-10-30-item-5-diff-r3.md)
- **Date:** 31 Oct 2026
- **Result:** 5 Findings; 4 accepted, 0 partly rejected, 1 rejected. Claude had missed 4. Not comparable with Gemini's missed rate (same model family).
- **Raw answer:** [2026-10-30-item-5-diff-second-r4.findings.json](2026-10-30-item-5-diff-second-r4.findings.json); run details in [2026-10-30-item-5-diff-second-r4.meta.json](2026-10-30-item-5-diff-second-r4.meta.json) (2 min; 151k prompt, 10k thinking, 2k answer tokens; 1 attempt); every run, skips included, in [2026-10-30-item-5-diff-second-r4.runs.json](2026-10-30-item-5-diff-second-r4.runs.json)

Run on a copy of round 4's workspace with the Gemini results cleared.
A Manual run (Antigravity) on another copy is recorded as `-manual-r4`.

## Verdicts

| ID | Severity | Category | Location | Claim | Verdict | Missed by Claude | Repeat of |
|---|---|---|---|---|---|---|---|
| F1 | minor | bug | `test/gui-ert:17-19` | No checks on the test file or checkout, so it can run the wrong config | Accept | yes | — |
| F2 | minor | design | `config.org:Theme` | Each new frame replaces a theme chosen by hand | Accept | yes | — |
| F3 | nit | test-gap | `test/org-behaviour-test.el:55-62` | Tests pin the tag count, Emacs 31.1, and a running daemon | Reject | — | — |
| F4 | nit | bug | `bin/start-check:92-96` | `--daemon` calls `emacsclient` with no timeout | Accept | yes | — |
| F5 | nit | bug | `bin/screenshot:7-10` | Header says the frame is set to 1600x900; it's a new frame, padded | Accept | yes | — |

## Triage notes

- **F1:** reproduced. An empty `--init-directory` means the current
  folder (from `/tmp`, `user-emacs-directory` was `"/tmp/"`), so a
  mistyped checkout runs the tests against whatever config the shell
  is in, and can pass. With no arguments, `$1: unbound variable` ends
  only the command substitution; Emacs then starts and the run fails
  after the 120 s timeout. A sibling of r2 F1 (`bin/start-check`).
  Fixed in `fe0b7ff` (shared `bin/checkout.sh`), red test `510cf0c`
  (new `test/gui-ert-test`); the mistyped case passed (exit 0) before.
- **F2:** confirmed from r3 F8 (each new pgtk frame runs the hook). To
  fix: the hook remembers the mode it last applied and does nothing
  when the mode is unchanged, so a hand-picked theme lasts until the
  desktop actually switches mode. Fixed in `24a309a`, red test
  `fa22d88`.
- **F3:** the claims are true, but each pin is deliberate. The count
  of 10 checks that every table row, and not the header, reaches
  `org-tag-persistent-alist`; adding a tag edits the test in the same
  commit. On 31.2, the daemon case failing is the prompt to update the
  script and docs. `--daemon` only reads a running daemon, so its tests
  need one. Rejected by Tim.
- **F4:** fixed in `fe0b7ff` (`timeout 10`, which is ample for a local
  `emacsclient -e`), red test `510cf0c` (a hanging stub emacsclient).
- **F5:** fixed in `fe0b7ff`: the header says a new frame of whole
  columns and lines opens, and each shot is padded to 1600x900.
