# Emacs config

Tim's Emacs config: an Org mode notes system plus light IDE-style coding,
on Emacs 31.1.

- `config.org`: the config, as a literate Org file.
- `init.el`: a stub that tangles `config.org` to `config.el` (not in git)
  and loads it.
- `early-init.el`: puts packages and other State in `~/.local/share/emacs/`
  and caches in `~/.cache/emacs/`, outside this repo.

To use it, link `~/.config/emacs` to this repo, with no `~/.emacs.d` or
`~/.emacs` present. To try a checkout without installing it:
`emacs --init-directory <path>`.

The previous config is at the `old-config` tag. Plans and decisions are in
`PLAN.md` and `docs/adr/`.
