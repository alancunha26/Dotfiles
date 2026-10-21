# Welcome to my Dotfiles

Hi! These are the dotfiles for my [Arch Linux](https://archlinux.org/) desktop, built on the
[Hyprland](https://hypr.land/) Wayland compositor. A single script, [`dots`](dots), installs
everything on a fresh machine and keeps it in sync with this repo afterwards.

## Gallery

![img](Extras/previews/01.png)

![img](Extras/previews/02.png)

![img](Extras/previews/03.png)

![img](Extras/previews/04.png)

![img](Extras/previews/05.png)

![img](Extras/previews/06.png)

## Installation

On a fresh Arch install, log in as your user (from a TTY is fine) and run:

```shell
bash <(curl -fsSL https://raw.githubusercontent.com/alancunha26/Dotfiles/main/dots) install
```

It clones this repo to `~/.dotfiles` and runs `~/.dotfiles/dots install`, which asks for your
password once and then does everything below. To see what it would do first, without changing
anything:

```shell
bash <(curl -fsSL https://raw.githubusercontent.com/alancunha26/Dotfiles/main/dots) install --dry-run
```

`dots install` is safe to run again: every step checks what is already there and skips it.
These are the steps, in order (run a subset with `--only` / `--skip`):

| Step         | What it does                                                                                    |
| ------------ | ----------------------------------------------------------------------------------------------- |
| `pacman`     | Enables `[multilib]`, refreshes the keyring, upgrades the system                                |
| `aur`        | Installs `git`, `base-devel` and builds `yay`                                                   |
| `migrations` | Runs pending [migrations](Extras/migrations) (on a fresh machine: marks them all done)          |
| `link`       | Symlinks [Configs](Configs) into `$HOME`, backing up anything in the way                        |
| `packages`   | Installs every package in [Extras/packages](Extras/packages) that isn't installed yet           |
| `system`     | Copies [Extras/system](Extras/system) into `/` (console and X11 keyboard layout)                |
| `shell`      | Oh My Zsh with zsh-autosuggestions and zsh-vi-mode, and zsh as the login shell                  |
| `runtimes`   | asdf plugins and the versions pinned in [.tool-versions](Configs/.tool-versions), npm globals   |
| `themes`     | Clones my [Themes](https://github.com/alancunha26/Themes) and links GTK, icon and cursor themes |
| `apps`       | Claude Code                                                                                     |
| `services`   | Enables NetworkManager, LACT, fstrim, ly and the Hyprland user services                         |

Afterwards, reboot. A few things can't be automated:

- **Proton GE** installs into Steam's folder, so open Steam once and then run `dots update`.
- **Pushing**: the clone uses HTTPS, with pushes going over SSH. Add an SSH key to GitHub first.
- **Godot** and **Steam** settings: see [Godot with Neovim](#godot-with-neovim) and
  [Gaming](#gaming).

## Keeping the machine in sync

The repo is the source of truth. Change it, then let `dots` apply the change:

```shell
dots update                   # pull the repo, upgrade everything (AUR and nightlies too), re-apply
dots status                   # what differs between this machine and the repo (read-only)
dots add obs-studio -g extras # install a package and record it in Extras/packages/extras.txt
dots remove obs-studio        # uninstall it and drop it from the lists
dots prune                    # uninstall packages installed by hand that no list mentions
dots link                     # re-create the symlinks (e.g. after adding a file to Configs/)
dots adopt ~/.config/foo      # move an existing config into Configs/ and link it back
```

Every command accepts `--dry-run`. `dots update` and `dots install` write a full log to
`~/.local/state/dots/logs/`.

**Removing packages safely.** `dots prune` lists packages that are explicitly installed but in
no list, then marks them as dependencies and removes only what nothing else needs, repeating
until no orphans are left. It asks before doing anything. The installer's own packages (kernel,
firmware, bootloader) are in [base.txt](Extras/packages/base.txt), so prune never touches them.

**Provider choices.** Some dependencies can be met by several packages (`tesseract` needs one
of 128 `tesseract-data-*` language packs). Unattended, pacman silently takes option 1, which
is Afrikaans in that case. Listing the provider you want avoids that: `core.txt` pins English and
Portuguese. `dots` warns before installing anything that would get a default pick, and
`dots status` lists the ones already on the machine.

**Changes that a list can't express.** Swapping a package for a conflicting one, deleting a
file left behind by an old config, renaming a service: write a migration with
`dots new-migration "replace foo with bar"`. Each migration runs exactly once per machine on
`dots update`. See [Extras/migrations](Extras/migrations).

### Layout

| Path                    | What                                                                      |
| ----------------------- | ------------------------------------------------------------------------- |
| `dots`                  | The install/update script (also linked to `~/.local/bin/dots`)            |
| `Configs/`              | Mirrors `$HOME`; every entry is symlinked into place                      |
| `Extras/packages/*.txt` | Package lists, one group per file: base, core, hardware, extras, gaming   |
| `Extras/system/`        | Files copied (not linked) into `/`                                        |
| `Extras/migrations/`    | One-off scripts, run once per machine                                     |

Inside `Configs/`, the shared directories (`~/.config`, `~/.local/bin`, `~/.local/share`,
`~/.local/share/applications`, `~/.config/gtk-4.0`, `~/.claude`) stay real directories and their
contents are linked one by one. Everything else is linked as a whole, so files an app creates
in, say, `~/.config/hypr` land in the repo. The list is `REAL_DIRS` at the top of `dots`.

AUR packages are built without `-debug` split packages (see
[makepkg.conf](Configs/.config/pacman/makepkg.conf)). The package lists are plain text, one package per line, with `#` comments. Repo and AUR
packages can be mixed; `dots` works out which is which. `hardware.txt` is specific to my AMD
CPU and GPU, so swap it out on different hardware, or install a subset with
`dots install --groups base,core`.

## Setup notes

### Gaming

Run games on steam with gamescope by pasting this on Steam launch options:

```shell
gamescope -w 1920 -h 1080 -r 240.0 -b -e --backend=sdl --adaptive-sync --force-grab-cursor -- %command%
```

### Godot with Neovim

The Neovim side comes with the dotfiles: [godotdev.nvim](https://github.com/Mathijs-Bakker/godotdev.nvim)
(GDScript LSP, DAP debugging, docs viewer, scene tree, `:GodotRun*`
commands, `gdformat` on save) plus treesitter parsers and the
`server.pipe` listener. On a fresh Godot install the editor must be
configured manually under `Editor > Editor Settings`:

1. **Text Editor > External**:
   - `Use External Editor`: **on**
   - `Exec Path`: `/usr/bin/nvim`
   - `Exec Flags`:

     ```
     --server {project}/server.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line}+1,{col})<CR>"
     ```

2. **Network > Language Server**:
   - `Use Thread`: **on**
   - `Show Native Symbols in Editor`: **on** — go-to-declaration (`gD`) on a
     built-in class/method then opens its docs in the Godot editor
     (`:GodotDocsCursor` shows docs inside Neovim instead).
   - Leave the port at the default `6005` (what Neovim connects to).

These settings are global (stored in `~/.config/godot/editor_settings-*.tres`),
so this is a once-per-machine setup, not per project.

Usage: open the Godot editor and launch `nvim` from anywhere inside the
project (it creates `<project>/server.pipe` on startup). Double-clicking a
script in Godot then opens it in the running Neovim at the right line, and
the `gdscript` LSP attaches through the editor. Add `server.pipe` to the
project's `.gitignore`. If scripts stop opening in Neovim after a crash,
delete the stale `server.pipe` and restart Neovim.

Node-path (`$Node`) completions come from the scene file on disk, and
Godot's LSP caches them until the client reconnects. The config handles
this automatically: when Neovim regains focus after a scene changed on
disk, it restarts the `gdscript` client. So to see new/renamed nodes in
completion, save the scene (`Ctrl+S`) in Godot before switching back to
Neovim. Inside tmux this needs `set -g focus-events on`.

## Common Fixes

To fix a ntfs drive just you can try to run:

-> Check [here](https://wiki.archlinux.org/title/NTFS#Unable_to_mount_with_ntfs3_with_partition_marked_dirty)

```shell
sudo ntfsfix -d PATH_TO_VOLUME
```

To fix audio/mic problems setup configuration with `alsamixer` and then run the following:

```shell
sudo alsactl store
```

The `ly` keyboard layout fix (`us-acentos` console keymap) is applied automatically from
[Extras/system/etc/vconsole.conf](Extras/system/etc/vconsole.conf).

## What's Next?

- [ ] Improve `~/.local/share/applications/` organization
- [x] TUI File manager (lf or ranger?)
- [ ] Email client (muttwizard)
- [ ] Music player (termusic)
- [x] Refactor nvim config
- [ ] Improve mpv config
- [x] Rofi window switcher
- [x] Rofi emoji picker
- [ ] Rofi system menu
- [x] Rofi calculator
- [ ] Theme switcher
- [x] Install script
- [ ] Lydm theme
- [x] ProtonVPN


## Inspirations

- [HyDE](https://github.com/HyDE-Project/HyDE/)
- [ML4W](https://www.ml4w.com/)
- [Omarchy](https://github.com/basecamp/omarchy): the run-once migrations in `dots`
- [aconfmgr](https://github.com/CyberShadow/aconfmgr): the safe way `dots prune` removes packages
