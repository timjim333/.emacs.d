# Building Emacs 31.1 on glacier

Last updated 2026-10-25, after the first build. Decision and alternatives:
`docs/adr/0001-build-emacs-31-from-source-into-opt.md`.

Emacs 31.1 was released on 2026-08-24 and bundles Org 9.8; Fedora 44 ships
30.2. pgtk is the right build for KDE Wayland: native Wayland, sharp
fractional scaling, smooth scrolling, and a working clipboard.

## Layout

```
/opt/emacs/README.txt             install notes
/opt/emacs/src/emacs-31.1.tar.xz  source archive (+ .sig)
/opt/emacs/src/emacs-31.1/        unpacked source and build tree
/opt/emacs/emacs-31.1/            installed prefix
```

The archive unpacks to a folder named `emacs-31.1`, so it lives under `src/`
to stay clear of the install prefix of the same name.

## Recipe

```bash
# 1. Build dependencies: Fedora's Emacs build deps minus its pinned
#    tree-sitter, plus tree-sitter 0.26 (see "Gotchas")
mapfile -t deps < <(dnf repoquery --srpm --requires emacs \
  | sed 's/ .*//' | grep -v -e '^rpmlib(' -e tree-sitter | sort -u)
sudo dnf install "${deps[@]}" libtree-sitter-devel

# 2. Own the folder once, so builds and installs need no sudo
sudo mkdir -p /opt/emacs/src && sudo chown -R "$USER": /opt/emacs

# 3. Source, with signature check (see "Verifying the signature")
cd /opt/emacs/src
curl -O https://ftp.gnu.org/gnu/emacs/emacs-31.1.tar.xz
curl -O https://ftp.gnu.org/gnu/emacs/emacs-31.1.tar.xz.sig
gpg --verify emacs-31.1.tar.xz.sig
tar xf emacs-31.1.tar.xz && cd emacs-31.1

# 4. Configure: Wayland, ahead-of-time native compilation, tuned for this CPU
PREFIX=/opt/emacs/emacs-31.1
./configure --prefix="$PREFIX" \
  --with-pgtk --with-native-compilation=aot \
  --with-tree-sitter --with-modules --with-selinux --without-compress-install \
  --with-systemduserunitdir="$PREFIX/lib/systemd/user" \
  CFLAGS="-O2 -march=native -pipe"

# 5. Build and install
make -j"$(nproc)" && make install

# 6. Register with alternatives. /usr/local comes before /usr in PATH and in
#    systemd's and KDE's search paths, so these links win over a dnf Emacs
#    without touching it. "emacs-opt" avoids Fedora's own "emacs" alternative.
#    alternatives doesn't create parent folders, so make them first.
sudo mkdir -p /usr/local/lib/systemd/user /usr/local/share/icons/hicolor/scalable/apps
sudo alternatives --install /usr/local/bin/emacs emacs-opt "$PREFIX/bin/emacs" 3110 \
  --follower /usr/local/bin/emacsclient emacsclient-opt "$PREFIX/bin/emacsclient" \
  --follower /usr/local/lib/systemd/user/emacs.service emacs-service-opt "$PREFIX/lib/systemd/user/emacs.service" \
  --follower /usr/local/share/applications/emacs.desktop emacs-desktop-opt "$PREFIX/share/applications/emacs.desktop" \
  --follower /usr/local/share/applications/emacsclient.desktop emacsclient-desktop-opt "$PREFIX/share/applications/emacsclient.desktop" \
  --follower /usr/local/share/icons/hicolor/scalable/apps/emacs.svg emacs-icon-opt "$PREFIX/share/icons/hicolor/scalable/apps/emacs.svg"
# Priority 3110 = 31.1.0; a later build gets a higher number.
# Switch versions: sudo alternatives --config emacs-opt

# 7. Check, then run as a background daemon
hash -r; emacs --version
systemctl --user daemon-reload && systemctl --user enable --now emacs
```

Why these flags:
- `-march=native` resolves to `znver5` on the 9800X3D; the binary then only
  runs on similar CPUs. `-O2` is the safe default.
- `aot` native-compiles all bundled Lisp up front.
- `--with-modules` is needed by jinx and vterm.
- `--with-selinux` must be explicit in 31.1 (see "Gotchas").

## Checks after installing

- `emacs --version` prints 31.1, and `command -v emacs` is
  `/usr/local/bin/emacs`.
- In Emacs, each of these returns `t`: `(treesit-available-p)`,
  `(native-comp-available-p)`, `(featurep 'pgtk)`.
- `(file-selinux-context "~/.bashrc")` returns a list of four strings, not
  `(nil nil nil nil)`.
- `systemctl --user is-active emacs` prints `active`, and `emacsclient -c`
  opens a frame at once.

## Gotchas found on the first build

- **`dnf builddep emacs` fails with tree-sitter conflicts.** Fedora's 30.2
  source package asks for both `libtree-sitter-devel` and
  `pkgconfig(tree-sitter) < 0.26`. Since tree-sitter 0.26 reached Fedora 44
  updates, no package satisfies both. Don't use `--allowerasing`: it
  downgrades tree-sitter system-wide. Step 1 installs the same list without
  the tree-sitter entries, then the 0.26 headers. Emacs 31.1 builds against
  0.26, and the installed grammar packages still load.
- **The package is `libtree-sitter-devel`**; `tree-sitter-devel` doesn't
  exist. `libgccjit-devel` is already in Fedora's build deps.
- **SELinux is off unless `--with-selinux` is passed.** The option defaults
  to `maybe`; gnulib's check only ever turns that into `no`, and Emacs's own
  check (`configure.ac:7446`) runs only for `yes`. No upstream bug report was
  found as of 2026-10-25; consider reporting it with `M-x report-emacs-bug`.
- **alternatives failed** with `failed to link ... No such file or directory`
  for the service and icon, because `/usr/local/lib/systemd/user` and
  `/usr/local/share/icons/hicolor/scalable/apps` didn't exist. Step 6 now
  creates them; re-running `--install` repairs a half-made registration.

## Configure summary: the expected "no"s

- GNU malloc, relocating allocator, mmap: unused with glibc's malloc.
- Xaw3d, X double buffer, Xpm, XInput2, Xft, m17n-flt: X11-only or
  superseded by pgtk, Cairo, and HarfBuzz.
- ImageMagick: opt-in since Emacs 27 because of its security record; leave
  off (HEIC handling is in `docs/design-notes.md`).
- Native image APIs: Windows and macOS only.
- `movemail` POP3 warning: only matters for reading POP3 mail in Emacs.

## Verifying the signature

The 31.1 tarball is signed by subkey `9B91 7007 AE03 0E36 E4FC 248B 695B 7AE4
BF06 6240` of Sean Whitton's key `8DC2 487E 51AB DD90 B5C4 753F 0F56 D055
3B6D 411B`, which is in https://ftp.gnu.org/gnu/gnu-keyring.gpg.
`gpgv --keyring gnu-keyring.gpg emacs-31.1.tar.xz.sig emacs-31.1.tar.xz`
reported a good signature on 2026-10-25. Still to do: cross-check that
fingerprint against the 31.1 release announcement (info-gnu or emacs-devel
archive), since the keyring and tarball came from the same server.

For a later release, download a fresh GNU keyring and repeat with `gpgv`. A
different signing key is normal, but confirm it through a second channel.
