# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Dotfiles for one Arch Linux + Hyprland desktop (AMD CPU/GPU), Linux only. The repo is the
desired state of the machine, and `dots` (a single bash script at the root, also linked to
`~/.local/bin/dots`) installs it on a fresh system and keeps the machine in sync. The repo must
be cloned to `~/.dotfiles`.

## Commands

```shell
./dots install --dry-run          # full plan against the real machine: read-only, no sudo
./dots status                     # drift: packages, links, /etc files, providers, migrations
./dots install --only link,themes # run some steps (see STEPS in dots); --skip works the same way
./dots update                     # git pull, re-exec the new dots, upgrade, re-apply everything
./dots link                       # re-create symlinks after adding something to Configs/
./dots add PKG -g GROUP           # install + append to Extras/packages/GROUP.txt
./dots remove PKG                 # uninstall + drop from every list
./dots prune                      # uninstall explicit packages no list mentions (asks first)
./dots new-migration "text"       # create Extras/migrations/<epoch>-<slug>.sh
```

There is no test suite. Verify changes with:
- `bash -n dots` and `shellcheck -x dots`. shellcheck isn't in the package lists; the file
  disables SC2016, SC2064 and SC2088 on purpose (comment at the top).
- `./dots install --dry-run` and `./dots status`. Both are safe to run on the real machine.
  Never run `install`/`update`/`prune` without `--dry-run` as a test: they change the system.
- `desktop-file-validate` for launchers in `Configs/.local/share/applications/`.

## Layout and the rules that span files

- `Configs/` mirrors `$HOME`. `REAL_DIRS` (top of `dots`) lists the directories that stay real
  directories because other programs write into them (`.config`, `.local/bin`, `.local/share`,
  `.local/share/applications`, `.config/gtk-4.0`, `.claude`, ...). Their children are linked one
  by one; **every other entry is linked as a whole**, so new files inside, e.g., `~/.config/hypr`
  land in the repo. Adding a new top-level config (a new `Configs/.config/foo`) needs
  `dots link`. If you add a directory that apps or `dots` itself write into (like
  `.local/share/icons`, where the themes step puts links), add it to `REAL_DIRS`, or those writes
  end up inside the repo. `dots adopt` only accepts direct children of `$HOME` or of a `REAL_DIRS`
  entry for the same reason.
- `Extras/packages/*.txt`: one package per line, `#` comments, repo and AUR names mixed (`dots`
  classifies them with `pacman -Sl` and the AUR RPC). Every file counts as "listed" for `status`
  and `prune`; `--groups` only narrows what `install` installs. `base.txt` holds the
  installer's packages (kernel, firmware, bootloader, zram) so `prune` never removes them.
  `hardware.txt` is AMD-specific.
- Provider pinning: with `--noconfirm` pacman silently picks option 1 for a virtual dependency
  (`tessdata` -> Afrikaans). Listing the wanted provider pins it, which is why `core.txt` has
  `tesseract-data-eng`/`por`. `dots` warns about unpinned ones before installing and in `status`.
- `Extras/system/` is copied (not linked) into `/`. The first overwrite keeps the original as
  `<file>.dots-orig`.
- `Extras/migrations/*.sh`: one-off changes a list can't express (package swaps, deleting
  leftovers). Each runs once per machine, in name order, as `bash -euo pipefail` from the repo
  root with stdin closed; markers live in `~/.local/state/dots/migrations/`. A fresh install
  marks all existing migrations as done. A failure stops `dots`. Make them safe to run twice.
- Themes come from a separate repo (github.com/alancunha26/Themes), cloned to
  `~/.local/share/dotfiles-themes` and linked into `~/.local/share/{themes,icons}` and
  `~/.config/gtk-4.0`. The GTK theme name is read from `Configs/.config/gtk-4.0/settings.ini`.
- Session environment: `Configs/.config/uwsm/env` (PATH incl. asdf shims, cursor themes, Qt/GTK
  backends); uwsm loads it before Hyprland starts.
- Hyprland uses the Lua config: `hypr/hyprland.lua` requires `hypr/hyprland/*.lua`. Validate with
  `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua` (strict: unknown keys, rule fields and
  dispatcher args all fail). Under Lua, `hyprctl dispatch` takes Lua
  (`hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'`) and `hyprctl keyword` doesn't work; use
  rules in the config or `hyprctl eval`. A running Hyprland picks its config format at startup:
  removing the file it loaded makes it reload a generated stub, so switch formats with a re-login.
  hypridle/hyprlock/hyprpaper still use their own `.conf` files.
- Runtimes (node, java, uv, protonge) come from asdf, pinned in `Configs/.tool-versions`. Proton
  GE only installs after Steam has run once (it needs `~/.steam/root`).
- `Configs/.config/pacman/makepkg.conf` disables `-debug` split packages for AUR builds; that's
  why the `link` step runs before `packages`. `migrations` runs before `packages` so swaps can
  remove a conflicting package first.
- Some tracked files are rewritten by apps: `~/.claude/settings.json`, nvim's `lazy-lock.json`,
  `mimeapps.list`. Expect diffs. An app that replaces a symlink with a regular file shows up in
  `dots status`, and the next `dots link` moves the file to a backup and relinks the repo version.

## Working on `dots`

- Settings live at the top: `REAL_DIRS`, services, `ZSH_PLUGINS`, `NPM_GLOBALS`,
  `ASDF_PLUGIN_URLS`, `STEPS`. A new install step is a `step_<name>` function plus entries in
  `STEPS` and `STEP_TITLES`.
- Every command that changes the machine must go through `run`/`srun` (print the command in
  `--dry-run`) or `apply "description" cmd...` (print the description). Read-only checks run in
  both modes, so the dry run reflects real state.
- Each step runs in a subshell with its own `set -e` (bash silently ignores `set -e` inside
  `func || ...`). So warnings and notes go through files in `$RUN_DIR` (`warn`/`note`), not
  arrays, and variables set in a step don't survive it. `pacman` and `migrations` failures are
  fatal; other steps fail on their own and the run continues.
- Strings passed to `apply ... eval '...'` must use the caller's named locals, never `$1`
  (inside `apply`, `$1` is `eval`).
- An `ERR` trap prints the failing command, so helpers used in `< <(...)` (`orphans`, `as_deps`,
  `pacnew_files`, ...) must return 0 when they simply find nothing.
- A function's last statement must not be `cond && action`: with `set -e`, it returns 1 when
  `cond` is false.
- `dots` takes a lock on fd 9; background jobs must close it (`9>&-`, see `sudo_keepalive`).
- State: `~/.local/state/dots/` holds `backups/<timestamp>/` (anything moved out of the way),
  `logs/` (on a TTY, `install`/`update`/`add`/`remove`/`prune` re-exec under `script`),
  `migrations/` and `lock`.

## Not automated

See the README: Godot editor settings for Neovim integration, Steam/gamescope launch options,
an SSH key for pushing (the bootstrap clones over HTTPS and sets an SSH push URL).
