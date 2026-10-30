# CLAUDE.md

Dotfiles for one Arch Linux + Hyprland desktop (AMD), Linux only. The repo is the desired state
of the machine; `dots` (one bash script at the root, linked to `~/.local/bin/dots`) installs it and
keeps the machine in sync. The repo must be cloned to `~/.dotfiles`. `dots --help` lists the commands.

## Verify

- `./dots lint`: `bash -n`, shellcheck (skipped when not installed), the house rules for `dots`
  (listed in its header comment), a description on every Hyprland bind, `Hyprland --verify-config`,
  `desktop-file-validate`. There is no test suite.
- `./dots install --dry-run` and `./dots status` are read-only and safe on the real machine. Never
  run `install`, `update` or `prune` without `--dry-run` as a test: they change the system.
- How the pstack skills apply here (visual-parity loop, reload-and-prove rule, package pruning): .claude/pstack-notes.md. Read the section for the skill you use.

## Layout and the rules that span files

- `Configs/` mirrors `$HOME`. `REAL_DIRS` (top of `dots`) stay real directories because other
  programs write into them; their children are linked one by one, and **every other entry is linked
  as a whole**, so new files inside `~/.config/hypr` land in the repo. A new top-level config needs
  `dots link`. A directory that apps or `dots` itself write into must be added to `REAL_DIRS`, or
  those writes end up in the repo. `dots adopt` only takes direct children of `$HOME` or of a
  `REAL_DIRS` entry for the same reason.
- `Extras/packages/*.txt`: one package per line, `#` comments, repo and AUR names mixed. Every file
  counts as "listed" for `status` and `prune`; `--groups` only narrows what `install` installs.
  `base.txt` holds the installer's packages so `prune` never removes them.
- Pin virtual-dependency providers by listing them (`core.txt` has `tesseract-data-eng`/`por`):
  with `--noconfirm` pacman silently picks option 1 (`tessdata` -> Afrikaans).
- `Extras/system/` is copied (not linked) into `/`; the first overwrite keeps `<file>.dots-orig`.
- `Extras/migrations/*.sh`: one-off changes a list can't express (package swaps, leftovers). Each
  runs once per machine, in name order, as `bash -euo pipefail` from the repo root with stdin
  closed; a failure stops `dots`. Make them safe to run twice. Create one with `dots new-migration`.
- Themes come from a separate repo (`alancunha26/Themes`), cloned to `~/.local/share/dotfiles-themes`;
  the GTK theme name is read from `Configs/.config/gtk-4.0/settings.ini`.
- Some tracked files are rewritten by apps (`~/.claude/settings.json`, nvim's `lazy-lock.json`,
  `mimeapps.list`): expect diffs. An app that replaces a symlink with a file shows up in
  `dots status`, and the next `dots link` backs it up and relinks the repo version.

### Hyprland (Lua config)

- `hypr/hyprland.lua` requires `hypr/hyprland/*.lua`. Hyprland only watches `hyprland.lua`, so after
  editing the others run `hyprctl reload`. A running Hyprland picks its config format at startup:
  removing the file it loaded makes it reload a generated stub, so switch formats with a re-login.
- `hyprctl dispatch` takes Lua (`hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'`) and
  `hyprctl keyword` doesn't work; use rules in the config or `hyprctl eval`.
- Window-rule sizes and positions are math expressions (`monitor_w*0.5 monitor_h*0.5`; variables
  monitor_w/h, window_w/h/x/y, cursor_x/y). `"50% 50%"` passes `--verify-config` but is silently
  ignored at runtime.
- hypridle, hyprlock and hyprpaper still use their own `.conf` files.

## Working on `dots`

- Comments are allowed here, and wanted: they carry the facts that used to live in this file (why a
  package is `-git`, why a directory is in `REAL_DIRS`, quirks of a config). Update the comment with the code.
- The conventions (named locals in `apply ... eval`, no `cond && action` last statement, `run`/
  `srun`/`apply` for every change, per-step subshells, the fd 9 lock) are in the comment at the top
  of `dots`; `dots lint` enforces the lintable ones.
- Settings live at the top (`REAL_DIRS`, services, `STEPS`, ...). Facts about the update check,
  providers and runtimes sit in the comments next to the code they describe.
