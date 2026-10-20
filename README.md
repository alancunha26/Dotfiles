# Welcome to my Dotfiles

Hi! This is my guide to what you are expected to find when using my Dotfiles for to setup your digital environment. It supports [Arch Linux](#arch-linux-hyprland), [MacOS](#macos-aerospace) and [Windows](#windows-11).

## Gallery

![img](Extras/previews/01.png)

![img](Extras/previews/02.png)

![img](Extras/previews/03.png)

![img](Extras/previews/04.png)

![img](Extras/previews/05.png)

![img](Extras/previews/06.png)

## Installation

Currently, only manual installation is supported, but in the near future I hope to write an automatic installation script for each platform supported.

### Arch Linux (Hyprland)

> [!tip]
> For a reference list of all packages used, you can [check below](#arch-linux-packages).

This is my primary environment and where most of my daily usage happens, so it's much more mature when compared to my dotfiles for other environments.

It's built on top of the [Hyprland](https://hypr.land/) wayland compositor, with huge inspiration from a lot of different rices throughout the internet, to see which inspirations are these, check the "[Inspirations](#inspirations)" section.

#### Install Packages

The first step is to install Yay and Git.

```shell
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
```

Then it's necessary to install the **Core Packages**.

```shell
yay -Sy pipewire pipewire-alsa pipewire-audio pipewire-jack pipewire-pulse gst-plugin-pipewire wireplumber networkmanager nm-connection-editor network-manager-applet bluez bluez-utils bluetui brightnessctl playerctl udiskie uwsm hyprland hyprpaper hyprlock hyprpicker hypridle hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk libnotify dunst rofi-git waybar grim slurp wf-recorder cliphist wl-clipboard wl-clip-persist ly xdg-user-dirs zsh starship btop fastfetch ffmpeg imagemagick ripgrep fzf fd less unzip jq luarocks pacman-contrib wget tuckr-git qt5-wayland qt6-wayland kvantum kvantum-qt5 qt5ct-kde qt6ct-kde gtk3 gtk4 nwg-look brave-bin kitty nautilus tumbler ffmpeg-audio-thumbnailer ffmpegthumbnailer neovim-nightly tree-sitter-cli mpv nsxiv zathura zathura-pdf-mupdf zk lazygit lazydocker asdf-vm xwaylandvideobridge noto-fonts-emoji noto-fonts noto-fonts-cjk noto-fonts-extra ttf-ia-writer ttf-jetbrains-mono-nerd ttf-jetbrains-mono ttf-fira-sans ttf-fira-code ttf-firacode-nerd sassc gtk-engine-murrine gnome-themes-extra ntfs-3g ntfsprogs gnome-keyring libqalculate rofi-calc rofi-emoji wiremix pokemon-colorscripts-git mpd rmpc mpc cava zoxide 7zip pavucontrol
```

Install the **Hardware Packages** (AMD CPU/GPU, SSD health, compressed swap).

```shell
yay -Sy amd-ucode vulkan-radeon xf86-video-amdgpu lact smartmontools zram-generator
```

Optionally you can also install the **Extra Packages**.

```shell
yay -Sy obs-studio obsidian libreoffice-fresh flatpak github-cli vscodium-bin ungoogled-chromium-bin discord discord-chat-exporter-gui opencode-bin proton-vpn-gtk-app filezilla yt-dlp-git gimp inkscape-bin godot tiled
```

Optionally you can also install the **Gaming Packages**. Enable the `[multilib]` repository
in `/etc/pacman.conf` first (uncomment the `[multilib]` section and its `Include` line).

```shell
yay -Sy steam gamescope protonup-qt-bin wine-mono
```

> [!tip]
> The exact list of explicitly installed packages of the last machine is kept in
> [Extras/packages/pacman.txt](Extras/packages/pacman.txt) and
> [Extras/packages/aur.txt](Extras/packages/aur.txt). Regenerate them with
> `pacman -Qqen > Extras/packages/pacman.txt && pacman -Qqem > Extras/packages/aur.txt`.

Then you can remove all unused packages currently installed.

```shell
sudo pacman -Rsn $(pacman -Qdtq)
```

##### Install the WSL version (Optional)

Alternatively you can install the WSL version:

```shell
yay -Sy neovim-nightly tree-sitter-cli luarocks ripgrep fastfetch zsh starship xdg-ninja stow pacseek less fzf zk btop lazydocker lazygit
```

Install the clipboard manager for WSL integration on windows:

```shell
winget install --id=equalsraf.win32yank  -e
```

#### Install Oh-My-Zsh!

To proceed run the following command

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Next, install the **zsh autosuggestions** plugin:

```shell
git clone https://github.com/zsh-users/zsh-autosuggestions \
  $ZSH_CUSTOM/plugins/zsh-autosuggestions
```

Then, install the **zsh vi mode** plugin:

```shell
git clone https://github.com/jeffreytse/zsh-vi-mode \
  $ZSH_CUSTOM/plugins/zsh-vi-mode
```

#### Install NodeJS, Yarn and pnpm

Add NodeJS to the ASDF plugins list:

```shell
asdf plugin add nodejs
```

Install the latest version:

```shell
asdf install nodejs latest
```

Set the latest version of node globally:

```shell
asdf set nodejs latest --home
```

Then, install yarn:

```shell
npm i -g yarn
```

Finally, install pnpm:

```shell
npm i -g pnpm
```

Then install short-unique-id with npm. This is used to generate unique short ids in my note taking system.

```shell
npm install --global short-unique-id
```

Add java to the ASDF plugins list:

```shell
asdf plugin add java
```

Install the correct java version:

```shell
asdf install java latest:adoptopenjdk-11
```

Set the java version globally:

```shell
asdf set java latest:adoptopenjdk-11 --home
```

Add uv (Python package and project manager) to the ASDF plugins list:

```shell
asdf plugin add uv
```

Install the latest version and set it globally:

```shell
asdf install uv latest && asdf set uv latest --home
```

Add Proton GE to the ASDF plugins list. It installs into Steam's
`compatibilitytools.d`, so launch Steam once before installing it:

```shell
asdf plugin add protonge https://github.com/augustobmoura/asdf-protonge.git
```

Install the latest version and set it globally:

```shell
asdf install protonge latest && asdf set protonge latest --home
```

#### Install CLI tools

Claude Code (native installer, puts the `claude` binary in `~/.local/bin`):

```shell
curl -fsSL https://claude.ai/install.sh | bash
```

#### Enable required services under systemd

Waybar:

```shell
systemctl --user enable --now waybar.service
```

Hyprerland Poolkit Agent:

```shell
systemctl --user enable --now hyprpolkitagent.service
```

Hyprpaper:

```shell
systemctl --user enable --now hyprpaper.service
```

Hypridle:

```shell
systemctl --user enable --now hypridle.service
```

Music Player Daemon:

```shell
systemctl --user enable mpd.service
```

Bluetooth:

```shell
sudo systemctl enable --now bluetooth.service
```

Ly Display Manager:

```shell
systemctl enable ly@tty2.service
systemctl disable getty@tty2.service
```

LACT (GPU control daemon):

```shell
sudo systemctl enable --now lactd.service
```

Periodic SSD TRIM:

```shell
sudo systemctl enable --now fstrim.timer
```

#### Install the system configs

After cloning the dotfiles (see below), copy the system-wide files in `Extras/system/etc`
into `/etc` (they are copied, not symlinked):
zram swap, LACT GPU profile and the X11 `us-intl` keyboard layout.

```shell
sudo cp -r ~/.dotfiles/Extras/system/etc/. /etc/
sudo systemctl daemon-reload && sudo systemctl start systemd-zram-setup@zram0.service
```

#### Download and install the themes

Follow the instructions provided on my
[Themes](https://github.com/alancunha26/Themes) repository.

#### Download and install the dotfiles

First you need to download the dotifles from the git repository:

```shell
git clone git@github.com:alancunha26/Dotfiles.git ~/.dotfiles
```

Then you have to run the following command.

```shell
tuckr set \* -f
```

Whenever you create a new file you must run `tuckr` again and clear the broken
symlinks:

```shell
tuckr set \* & find -xtype l -delete
```

#### Setup Gaming

Run games on steam with gamescope by pasting this on Steam launch options:

```shell
gamescope -w 1920 -h 1080 -r 240.0 -b -e --backend=sdl --adaptive-sync --force-grab-cursor -- %command%
```

#### Setup Godot with Neovim

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

#### Common Fixes

To fix a ntfs drive just you can try to run:

-> Check [here](https://wiki.archlinux.org/title/NTFS#Unable_to_mount_with_ntfs3_with_partition_marked_dirty)

```shell
sudo ntfsfix -d PATH_TO_VOLUME
```

To fix audio/mic problems setup configuration with `alsamixer` and then run the following:

```shell
sudo alsactl store
```

To fix keyboard layout issues on the `ly` greeter (e.g. typing `@` produces `@2`, or missing Portuguese dead keys), set the TTY console keymap to `us-acentos` (the console equivalent of `us-intl`):

```shell
sudo localectl set-keymap us-acentos
```

Reboot for the change to take effect.

#### Arch Linux Packages

_Core Packages_

| Package                     | Description                                     |
| --------------------------- | ----------------------------------------------- |
| pipewire                    | Audio/video server                              |
| pipewire-alsa               | Pipewire alsa client                            |
| pipewire-audio              | Pipewire audio client                           |
| pipewire-jack               | Pipewire jack client                            |
| pipewire-pulse              | Pipewire pulseaudio client                      |
| gst-plugin-pipewire         | Pipewire gstreamer client                       |
| wireplumber                 | Pipewire session manager                        |
| networkmanager              | Network manager                                 |
| nm-connection-editor        | GUI Network manager editor                      |
| network-manager-applet      | GUI Network manager applet                      |
| bluez                       | Bluetooth protocol stack                        |
| bluez-utils                 | Bluetooth utility cli                           |
| bluetui                     | Bluetooth manager tui                           |
| brightnessctl               | Screen brightness control                       |
| playerctl                   | Media controls                                  |
| udiskie                     | Manage removable media                          |
| uwsm                        | Universal wayland session manager               |
| hyprland                    | Wayland compositor based on wlroots-based       |
| hyprpaper                   | Wallpapers                                      |
| hyprlock                    | Lock screen                                     |
| hyprpicker                  | Color picker                                    |
| hypridle                    | Idle manager                                    |
| hyprpolkitagent             | Authentication agent                            |
| xdg-desktop-portal-hyprland | xdg desktop portal for hyprland                 |
| xdg-desktop-portal-gtk      | File picker and dbus integration                |
| xwaylandvideobridge         | Screen sharing of XWayland apps                 |
| libnotify                   | For notifications                               |
| dunst                       | Notification daemon                             |
| rofi-git                    | Application launcher                            |
| waybar                      | System bar                                      |
| grim                        | Screenshot tool                                 |
| slurp                       | Region selector for screenshot/screenshare      |
| wf-recorder                 | Screen recorder for wlroots compositors         |
| cliphist                    | Clipboard manager                               |
| wl-clipboard                | Clipboard utilities for wayland                 |
| wl-clip-persist             | Persist clipboard after programs close          |
| ly                          | TUI display manager                             |
| xdg-user-dirs               | Manage user directories                         |
| zsh                         | Shell                                           |
| starship                    | Shell prompt                                    |
| btop                        | Process viewer                                  |
| fastfetch                   | System information tool                         |
| ffmpeg                      | Record, convert and stream audio and video      |
| imagemagick                 | Image processing                                |
| ripgrep                     | Regex directory searcher                        |
| fzf                         | CLI fuzzy finder                                |
| fd                          | CLI fuzzy finder                                |
| less                        | Terminal based program for viewing text         |
| unzip                       | Zip extractor                                   |
| jq                          | JSON processor                                  |
| luarocks                    | Lua package manager                             |
| pacman-contrib              | Scripts and tools for pacman systems            |
| wget                        | Network utility to retrieve files from the web  |
| tuckr-git                   | Dotfiles manager                                |
| qt5-wayland                 | Wayland support in qt5                          |
| qt6-wayland                 | Wayland support in qt6                          |
| kvantum                     | Svg based qt6 theme engine                      |
| kvantum-qt5                 | Svg based qt5 theme engine                      |
| qt5ct-kde                   | qt5 configuration tool                          |
| qt6ct-kde                   | qt6 configuration tool                          |
| gtk3                        | Gnome 3                                         |
| gtk4                        | Gnome 4                                         |
| nwg-look                    | GTK configuration tool                          |
| brave-bin                   | Web browser                                     |
| kitty                       | Terminal emulator                               |
| nautilus                    | GUI file manager                                |
| ffmpegthumbnailer           | Video thumbnails for nautilus                   |
| ffmpeg-audio-thumbnailer    | Audio thumbnails for nautilus                   |
| tumbler                     | Thumbnails for evey file manager (not nautilus) |
| neovim-nightly              | Terminal text editor                            |
| tree-sitter-cli             | Required by nvim treesitter parser manager      |
| mpv                         | Video player                                    |
| nsxiv                       | Simple image viewer                             |
| zathura                     | Simple document viewer                          |
| zathura-pdf-mupdf           | PDF and Epub support for zathura                |
| lazygit                     | Simple terminal UI for git commands             |
| lazydocker                  | TUI docker manager                              |
| zk                          | Zettelkasten note taking LSP                    |
| sassc                       | Deps for GTK Theme                              |
| gtk-engine-murrine          | Deps for GTK Theme                              |
| gnome-themes-extra          | Deps for GTK Theme                              |
| ntfs-3g                     | NTFS filesystem driver                          |
| ntfsprogs                   | NTFS utilities (ntfsfix, ntfsinfo, mkntfs)      |
| gnome-keyring               | Gnome keyring                                   |
| wiremix                     | TUI audio manager                               |
| libqalculate                | Powers rofi calculator                          |
| rofi-calc                   | Rofi calculator                                 |
| rofi-emoji                  | Rofi emoji                                      |
| noto-fonts-emoji            | -                                               |
| noto-fonts                  | -                                               |
| noto-fonts-cjk              | -                                               |
| noto-fonts-extra            | -                                               |
| ttf-ia-writer               | -                                               |
| ttf-jetbrains-mono-nerd     | -                                               |
| ttf-jetbrains-mono          | -                                               |
| ttf-fira-sans               | -                                               |
| ttf-fira-code               | -                                               |
| ttf-firacode-nerd           | -                                               |

_Extra Packages (Optional)_

| Package            | Description                         |
| ------------------ | ----------------------------------- |
| obs-studio         | Live streaming and recording        |
| obsidian           | Markdown note taking app            |
| libreoffice-fresh  | Open-source office suite            |
| flatpak            | Run sandboxed applications on Linux |
| qbittorrent        | Trusted torrent client              |
| proton-vpn-gtk-app | Proton VPN                          |

_Gaming Packages (Optional)_

> See more in the wiki: [Gaming](https://wiki.archlinux.org/title/Gaming), [Steam](https://wiki.archlinux.org/title/Steam)

| Package        | Description                                |
| -------------- | ------------------------------------------ |
| steam          | Valve's digital software delivery system   |
| gamescope      | SteamOS session compositing window manager |
| retroarch      | Reference frontend for the libretro API    |
| corectrl       | AMD GUI hardware control                   |
| ttf-liberation | Arial font used for steam                  |

### MacOS (Aerospace)

TODO

### Windows 11

TODO

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
- [ ] Install script
- [ ] Lydm theme
- [x] ProtonVPN

## Inspirations

- [HyDE](https://github.com/HyDE-Project/HyDE/)
- [ML4W](https://www.ml4w.com/)
