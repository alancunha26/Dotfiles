Every repo on terra. A repo's CLAUDE.md adds to these and wins on conflict.

## Chat replies
- Every reply to me follows the unslop rules (a session hook loads them). Conclusion first, short, plain. If I say I didn't understand, restate it plainly (bro).
- A question is read-only. Explain, then wait. Change nothing until I ask for a change.
- On this machine, make the judgement call and state it in one line ("Decided: X, because Y"). Ask only before something irreversible or outward-facing.

## Before choosing
- When more than one approach exists, research online how people do it before picking, and name what you found in one line.
- Prune before adding. No new package, dependency, service, or file without a need you can name. Remove dead parts first.
- Never touch what already works. Change only what the request names; revert unrelated hunks before handing back.
- Smallest diff that solves it, one source of truth per decision, no wrapper with one caller.
- Fix the first place the system went wrong, not a guard where the symptom showed.
- Never edit ~/.claude/skills/synced/ (account-managed). A committed CLAUDE.md or AGENTS.md in a shared repo is a team change: propose it, don't write it.

## Before handing back
- After changing a running system (a daemon, a server, a systemd unit), reload or restart it yourself and show evidence it applies: the command and its output, a log line, or a screenshot.
- Prove it on the real thing (run it, read the live value), never on a proxy like "it compiles" or "the file changed".

## Code
- No comments in code, unless the repo's CLAUDE.md allows a kind or the comment explains behavior forced by an outside tool.

## Durable guidance
- Do not use the auto-memory system. Repo rules go in that repo's CLAUDE.md; rules for every repo go here.
- When a correction repeats, encode it as a script, lint, hook, or test (the pstack `correct` skill) instead of another line here.

## pstack skills (plugin, manual-only)
- They do not auto-run, and the plugin files are read-only. Each lives at `~/.claude/pstack/skills/<name>/SKILL.md`. For each one you use, read it, then the repo's .claude/pstack-notes.md section for it when the repo's CLAUDE.md points to one. Map Cursor tool names with `~/.claude/pstack/docs/harness/claude-code.md` (read it once per session, when first needed).
- when I say 'what does X mean', 'I didn't understand', 'I still don't get the X thing' -> bro (define each term in one sentence with a concrete example; no new information; five sentences at most)
- when I say 'how does X work', 'how is this mounted', 'why is X installed' -> how
- when I say 'is it safe to run now', 'anything problematic to remove', or before an install, prune, or removal I did not name -> blast-radius
- when I say 'the sizes are still different', 'they look bigger now', 'doesn't match the design' -> visual-parity (a playbook: ~/.claude/pstack/skills/poteto-mode/playbooks/visual-parity.md)
- when I correct the same thing twice -> correct
- when I say 'reflect', 'what did we learn', 'that took too long' -> reflect (there is no devex tracker; list Backlog items in the summary and offer `correct` for each)
- when I say 'make a verify skill', 'test it like a user' -> create-verification-skill (tmux isn't installed; use `script -qc` for a CLI or TUI transcript)
- when I say 'no comments', 'remove the comments' (explicit only) -> no-comments
- when you create or edit a skill or a CLAUDE.md -> write-skill (a playbook: ~/.claude/pstack/skills/poteto-mode/playbooks/authoring-a-skill.md; a skill description says what it does, then `Use when` and the situations in my words)
- The session hook loads unslop, so it needs no read.
- For rigorous work I type `/pstack:poteto-mode` per task. It is not sticky in Claude Code.
