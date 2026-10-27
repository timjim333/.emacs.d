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
`~/org/`, the folder holding every note, the Journal, and the Inboxes;
synced to every Device and kept in git.
_Avoid_: vault, org directory

**Inbox**:
The file where a device's captures land before Tim refiles them. Each
device has its own.
_Avoid_: scratch, quick notes

**Journal**:
The day view: one file per year with a heading per day, holding entries
and linked headlines of Log entries.
_Avoid_: diary, daily notes

**Log entry**:
A dated heading under a project's `Log` heading, recording one piece of
work on it, linked from that day in the Journal.
_Avoid_: logbook note (the LOGBOOK drawer holds state changes and clock
times only)

**Calendar folder**:
`~/org-calendar/`, the Org copies of Google calendars, written only by
org-gcal on the sync host; read-only on the phone.
_Avoid_: agenda files (the agenda also reads the Notes folder)

**Device**:
A machine that holds a synced copy of the Notes folder: glacier, the
phone, and later the always-on VM. The work machine is never one.
_Avoid_: client, node (a node is a note)

**Conflict copy**:
The `.sync-conflict` file Syncthing leaves when two Devices changed the
same file between syncs.
_Avoid_: merge conflict, duplicate
