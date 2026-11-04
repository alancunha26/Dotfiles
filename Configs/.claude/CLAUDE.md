Every repo on terra. A repo's CLAUDE.md adds to these and wins on conflict.

## Chat replies
- Every reply to me follows the unslop rules (a session hook loads them). Conclusion first, short, plain. If I say I didn't understand, restate it plainly.
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
- When a correction repeats, encode it as a script, lint, hook, or test instead of another line here.

