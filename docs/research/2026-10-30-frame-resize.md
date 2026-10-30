# Frames don't resize once shown: PlasmaZones (30 Oct 2026)

Backs the frame sizing in `bin/screenshot.el`.

## Finding

On glacier, while `plasmazones.service` (PlasmaZones 3.5.3) runs, a
pgtk Emacs frame ignores every resize request once it is shown:
`set-frame-size` in pixels or characters, and `fullscreen` set to
`maximized`. A new frame does get the size `make-frame` asks for.
With the service stopped, the same request works.

The block isn't tied to PlasmaZones' remembered geometry: a frame
under a class it had never seen (`emacs --name screenshot-probe`) was
blocked too, and both Emacs classes are recorded as `floating`, not
snapped, with tiling off.

## Evidence

[2026-10-30-frame-resize-probe.el](2026-10-30-frame-resize-probe.el),
run as `PROBE_OUT=<file> emacs -Q -l <probe>`:

| PlasmaZones | Initial (outer, text) | After asking 1200x600 |
|---|---|---|
| running | 672x648, 640x648 | 672x648, 640x648 |
| stopped (Tim, at the screen) | 672x648, 640x648 | 1232x594, 1200x594 |

594 is 600 rounded down to whole 18 px lines.

## Also found

- A new frame converts `(text-pixels . N)` to columns with the 8x18
  fallback font, before the config's 9x21 JetBrains Mono applies, so
  it comes out 9/8 too wide. Asking for whole columns and lines works.
- The config's first frame starts at 688x680: 80x36 characters at
  8x18, kept at that pixel size when the font changes, because of
  `frame-inhibit-implied-resize t`.

## Consequences

`bin/screenshot` opens a new frame in whole columns and lines and pads
the PNG to 1600x900, so it needs neither a resize nor PlasmaZones
stopped. Anything else that resizes a shown frame (a command, a test)
will silently do nothing while PlasmaZones runs.
