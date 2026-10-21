# Migrations

One-off changes that a package list or a symlink can't express: swapping a
package for a conflicting one, deleting a file an old config left behind,
renaming a service. `dots update` runs each `*.sh` here once per machine, in
name order, and remembers it in `~/.local/state/dots/migrations/`.

- Create one with `dots new-migration "describe the change"`.
- Each runs with `bash -euo pipefail` from the repo root; stdin is closed.
- A failure stops `dots update`; fix the script and run it again.
- A fresh `dots install` marks every existing migration as done, because a new
  machine already gets the end state from the lists and configs.
- Keep them safe to run twice (check before changing).

Example, `1761100000-swap-rofi-git-for-rofi.sh`:

```bash
echo "Replacing rofi-git with rofi"
if pacman -Qq rofi-git &>/dev/null; then
  sudo pacman -Rdd --noconfirm rofi-git
  sudo pacman -S --needed --noconfirm rofi
fi
```
