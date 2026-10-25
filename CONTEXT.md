# Emacs config

Tim's Emacs setup: an Org notes system plus light IDE-style coding, on
glacier.

## Setup

**Config**:
The files Tim writes to set Emacs up, kept in this repo.
_Avoid_: dotfiles, init files (for the whole set)

**State**:
Everything Emacs or its packages write while running: installed packages,
compiled code, caches, and history. Never kept in the repo.
_Avoid_: runtime files, junk

**Old config**:
The config forked from SophieBosio/.emacs.d, used until the Cutover.
_Avoid_: legacy config, previous setup

**Cutover**:
The one-off switch of the daemon from the Old config to the new one.
_Avoid_: migration, switchover

**Build**:
One Emacs release compiled from source into its own prefix under
`/opt/emacs`.
_Avoid_: install, version (when the folder is meant)

## Notes

**Notes folder**:
`~/org/`, the one folder holding every note, the journal, and the inboxes;
synced to every device.
_Avoid_: vault, org directory

**Inbox**:
The file where a device's captures land before Tim refiles them. Each
device has its own.
_Avoid_: scratch, quick notes

**Journal**:
Dated entries, one file per year with a heading per day.
_Avoid_: diary, daily notes
