# pstack attribution

The skills listed in `../SHARED-SKILLS.txt` are adapted from [cursor/plugins pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT, (c) 2026 Lauren Tan).

Changes from the originals, and only these:
- Frontmatter: `disable-model-invocation` removed and descriptions rewritten as auto-triggers (`Use when ...`).
- Steps for other harnesses (Cursor, Codex, Grok, OpenCode) removed or swapped for the Claude Code equivalent.
- A short `## Overrides` block where a rule applies on every machine, and a final `## Local rules` pointer to `references/local.md`.
- `write-skill` and `visual-parity` are built from pstack playbooks (`authoring-a-skill`, `visual-parity`).
- Added scripts: `write-skill/scripts/check-skill.py`, `reflect/scripts/transcript.py`.
