# How the pstack skills apply in the dotfiles repo

Read the section for the pstack skill you are using. The repo CLAUDE.md points here. These notes add to the skill; they never replace it.

## blast-radius

On the live system, step 5's proof is a read-only check that fails loudly if you're wrong, and step 1 includes what the command really does: pacman `-Rns` also removes dependencies, and `dots prune` removes every package no list names.

- Packages: `pacman -Rs --print PKG` (`--print` rejects `-n`), `pactree -r PKG`, `pacman -Qi PKG` (Required By, Install Reason), `Extras/packages/*.txt`, and `grep -i PKG /var/log/pacman.log | head` for what archinstall installed. Archinstall's packages, like zram, stay unless the user says otherwise.
- Services: `systemctl --user list-dependencies --reverse UNIT`, timers and sockets that start it, `USER_SERVICES` in `dots`.
- Files: `grep -rn` across `~/.dotfiles/Configs`, `~/.config`, `~/.local/bin`, and Hyprland `exec` lines.
- Commands: `./dots install --dry-run` and `./dots status` change nothing. Never test `install`, `update`, or `prune` without `--dry-run`.
- Push: `git status`, `git log origin/main..`, and a secrets scan of the diff.

## correct

Checks available here: `./dots lint` (it runs `Hyprland --verify-config`), `./dots status`, and a Claude Code hook.

| Class | Evidence | Enforce with |
|---|---|---|
| Handing back a system change without applying it | "did you restart waybar?" (9 times) | Reload it yourself (`systemctl --user restart waybar`, `hyprctl reload`, `swaync-client -rs`) and show the status output, a journal line, or a `grim` screenshot. |
| Touching what worked | "keep the workspace icons exactly how they were" | `git diff --stat` lists only files the request named; revert other hunks. For UI, the `visual-parity` diff is zero outside the target. |
| Adding too much | "why two new packages?", "I don't want zram stuff" | Diff `Extras/packages/` and `pacman -Qqe` before and after; name the reason for each addition. Run `blast-radius` before removing. |

Classes that apply in every repo are rules in the global CLAUDE.md. Add a row when a new class appears here. Drop a row once its mistake can no longer happen.

Find earlier instances in `~/.claude/history.jsonl` (every prompt the user typed), `git log`, and the CLAUDE.md files.

## create-verification-skill

- Drive desktop UI with `grim` for screenshots and `hyprctl -j` for state. `.claude/scripts/vp.sh shot` shoots a layer by its namespace.

## how

- On the live system, read the state and don't guess from config alone: `systemctl --user status`, `journalctl --user -u`, `hyprctl -j`, `pacman -Qi`, `dots status`. Put this line in every explorer and explainer prompt, and say which facts came from live state and which from files.
- For "why is X installed", read `pacman -Qi PKG` (Install Reason, Required By), `pactree -r PKG`, `Extras/packages/*.txt`, and `grep -i PKG /var/log/pacman.log`.

## no-comments

- Comments in `dots` carry facts (CLAUDE.md, "Working on `dots`"). They are a kind the repo allows, so keep them like a keep-list exception.
- After the fixes, run `./dots lint` to prove nothing broke.

## reflect

- A lesson for a pstack skill as it applies here goes in that skill's section of this file. A lesson for every repo goes in the global CLAUDE.md, tracked at `Configs/.claude/CLAUDE.md`.

## visual-parity

The poteto-mode playbook gives the rules; this is the procedure here. Measure and diff, never eyeball. Shoot a baseline before the change, then make the diff zero outside the target.

- `.claude/scripts/vp.sh` is the harness (grim on Wayland): `vp.sh shot TARGET OUT.png` shoots a layer namespace (waybar, swaync) or a grim geometry, `vp.sh boxes IMG.png [MINAREA]` measures every element, `vp.sh diff BASE.png NEW.png [DIFF.png]` counts differing pixels (exit 0 only at zero).
- Reload after each change (`systemctl --user restart waybar`, `swaync-client -rs`, `hyprctl reload`) before you shoot.
- If the old look is already gone, rebuild the baseline from `git stash` or `git show HEAD:<file>`, reload, and shoot that.
- To find a size mismatch's cause, read the real boxes in the GTK inspector: `systemctl --user stop waybar; GTK_DEBUG=interactive waybar`, then restart the service.

## write-skill

- Global skills live in `Configs/.claude/skills/<name>/`, linked into `~/.claude/skills/` (`.claude/skills` is in `REAL_DIRS`). Repo skills live in `<repo>/.claude/skills/<name>/`.
