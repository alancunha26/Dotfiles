# Claude setup on terra

Not loaded into sessions. This is the map for you.

## Loads in every session

1. `~/.claude/CLAUDE.md`, your working rules. Tracked in `~/.dotfiles/Configs/.claude/CLAUDE.md`.
2. The SessionStart hook `~/.claude/hooks/unslop-context.sh`. It prints pstack's unslop rules and its "Writing the reply" rules from the plugin. It also keeps the link `~/.claude/pstack` pointing at the installed plugin.
3. The pstack plugin (`pstack@cursor-plugins`). It has 58 skills, typed as `/pstack:<name>`. The model reads one only when a CLAUDE.md line says to. It costs about 4,800 tokens per session.

## Loads only in one repo

- `~/.dotfiles`: `CLAUDE.md`, `.claude/pstack-notes.md` (how each pstack skill applies there) and `.claude/scripts/vp.sh` (screenshot, measure and diff for visual-parity).
- Notes vaults (`~/.repos/github.com/alancunha26/notes`, `notes-alenyr`): each vault's `CLAUDE.md` has a `## Voice` section. `notes-alenyr-old` and `notes-dnd` have none.
- `notes` skills: compile, recap, lint, query, logging. Logging writes the vault log.
- `notes` hook `.claude/hooks/after-edit.sh`, after each Write or Edit of `zettels/*.md`. It runs prettier, then `lint.py --style`. It reports only findings that are new against git HEAD, and exits 2 so Claude sees them. The style checks are em dashes, wikilinks, bold links and repeated links.
- `notes-alenyr` hook `.claude/hooks/after-edit.sh`. Same flow, but it runs `.claude/hooks/style.py`. That script also flags relative time ("years ago", "recently"), because dates there use BT and AT.
- `notes-alenyr/CLAUDE.md` holds the lore rules.
- Dotfiles commands: `dots lint` (static checks), `dots link` (recreate symlinks from `Configs/`), `dots status` (how the machine differs from the repo).

## Where a new rule goes

- True in every project: `~/.claude/CLAUDE.md`.
- True in one repo: that repo's `CLAUDE.md` or `.claude/pstack-notes.md`.
- Never edit the plugin. Update it with `claude plugin update pstack@cursor-plugins`.
- A rule that keeps being broken becomes a check. Read `~/.claude/pstack/skills/correct/SKILL.md`.

## Debugging

- What is loaded: `/memory`, `/hooks`, `/plugin`.
- What the reply hook prints: `~/.claude/hooks/unslop-context.sh | head -20`.
- Plugin token cost: `claude plugin details pstack@cursor-plugins`.
- Dotfiles checks: `~/.dotfiles/dots lint`. `dots status` shows drift.
- Visual checks: `~/.dotfiles/.claude/scripts/vp.sh shot|boxes|diff`.
- Notes health: `python3 <vault>/.claude/skills/lint/scripts/lint.py` (add `--write` to save the report).
- Notes prose: `<notes>/.claude/scripts/prose-lint.sh FILE...`.
- Backup of the old setup: `~/.claude-backup-pstack-2026-10-30/` (old versions, diffs, change logs). Delete it once you trust the new setup.

## Not committed yet

- `~/.dotfiles`, Claude config: 3 modified (`CLAUDE.md`, `Configs/.claude/hooks/unslop-context.sh`, `Configs/.claude/settings.json`), 41 deleted (the old copied skills, agent, notice and backup files under `Configs/.claude`), 3 untracked (`.claude/`, `Configs/.claude/CLAUDE.md`, `Configs/.claude/SETUP.md`).
- `notes`: 10 modified, 4 deleted, 2 untracked.
- `notes-alenyr`: 5 modified, 2 deleted, 1 untracked.
