---
name: write-skill
description: "Standard for authoring, editing and trimming SKILL.md, CLAUDE.md and AGENTS.md files. Use whenever you create or change one, or the user says 'create a skill', 'make this a skill', 'simplify my skills', 'this is slop', or 'update CLAUDE.md'. A repeated mistake goes to correct first."
---

### Authoring or modifying a skill

## Overrides

- Frontmatter: `name` (== directory) and `description` only; `allowed-tools` only when truly needed; no `disable-model-invocation`. Description is the trigger: at most 300 chars, what it does, then `Use when` with the user's own phrases. Sharpen it against sibling descriptions that could fire on the same request.
- Skills live in `~/.claude/skills/<name>/` (personal) or `<repo>/.claude/skills/<name>/` (project). Never edit anything under `~/.claude/plugins/`.
- CLAUDE.md and AGENTS.md follow the same prose rules.
- Validator for step 2: `python3 -I ~/.claude/skills/write-skill/scripts/check-skill.py <skill-dir> [...]` (frontmatter, name, description length, referenced files, scripts executable and parse).

**You own the skill's voice.**

1. Use the **skill-creator** skill (Anthropic's skill for authoring SKILL.md files).
2. Validate the skill: frontmatter has `name` and `description`, referenced files exist, cross-skill links resolve.
3. Test cases if structural. Skip if subjective.
4. Run **Opening a PR**.

When in doubt, delete. Keep only prose that changes a decision. Tell it to do the thing and skip the reason. Explain only when the rule is confusing without one. Match tone to scope. Point at structural sources (types, READMEs, config) per the **encode-lessons-in-structure** principle skill. Delegate to other skills by path. Don't restate. A workflow you keep hitting but isn't captured → propose a new skill.

**Reply:** summary of the skill, key design decisions, validation notes.

Adapted from cursor/plugins pstack (MIT, (c) 2026 Lauren Tan).

## Local rules

Machine-specific rules, if present: references/local.md (read it when it exists).
