# 4. Sync and backup: Syncthing, git on GitHub, and a plaintext Drive mirror

Date: 2026-10-26. Status: accepted.

The Notes folder has three layers, each with one job:

- **Live sync:** Syncthing between glacier and the phone, later with the
  baby-log OCI VM as a trusted, always-on peer. Each device captures to
  its own Inbox, because Syncthing compares whole files: two devices
  changing one file between syncs gives a `.sync-conflict` file, even if
  they changed different lines. Staggered versioning on glacier, and a
  `tim/resolve-sync-conflicts` command that opens each conflict in ediff.
- **History:** a git repo inside `~/org` (excluded from Syncthing by
  `.stignore`, since a synced `.git` corrupts), auto-committed hourly and
  pushed to a private GitHub repo, attachments included.
- **Offsite backup:** a nightly `rclone sync` to Google Drive in
  plaintext: `current/` is a mirror, and files changed or deleted that
  night move to `archive/<date>/` (`--backup-dir`), kept 90 days.
  `--max-delete 50` stops a run that would delete more, so a wiped folder
  can't empty the backup.

Tim's notes will mention other people, so these are deliberate exceptions
to the rule that only Shareable content goes to third parties. Tim
accepts Drive in plaintext for its web view, and GitHub as one more
access-controlled (not encrypted) copy. Don't "fix" either by encrypting
them without asking.

## Considered options

- **Encrypted backups** (`rclone crypt`, restic, or kopia): private, but
  lose the plaintext web view. restic or kopia would add whole-folder
  point-in-time restores, which git already gives.
- **`rclone copy`:** never deletes, but Drive fills with deliberately
  deleted files. Plain `rclone sync`: copies a wipe to the backup.
- **Git for live sync:** merges line by line, but isn't live, needs SSH
  keys on the phone, and same-line edits still conflict.
- **VPS as an encrypted (untrusted) Syncthing peer:** no exposure, but it
  can't run the jobs below.

## Consequences

- glacier is off most weekdays, so until the VM joins, auto-commit, the
  Drive backup, and org-gcal run only while glacier is on. Once the VM
  joins, it runs all three, pushing with a deploy key scoped to the notes
  repo, in its own containers with only the notes volume.
- If the baby-log server on the same VM is breached, the notes are
  readable there.
- The work machine never syncs the Notes folder.
