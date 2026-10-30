#!/usr/bin/env bash
# SessionStart hook: load the unslop rules into every session so replies are written by them.
d="$HOME/.claude/skills/unslop"
[ -f "$d/SKILL.md" ] || exit 0
echo "## Writing rules for every reply you write to the user"
echo "Apply the unslop rules and the reply rules below to your chat replies as you write them, not only to documents. Lead with the conclusion, then only what changes what the user does next. No preamble, no recap of what was asked, no closing offers."
echo
awk '/^---$/ {n++; next} n>=2' "$d/SKILL.md"
if [ -f "$d/references/reply-rules.md" ]; then echo; cat "$d/references/reply-rules.md"; fi
if [ -f "$d/references/local.md" ]; then echo; cat "$d/references/local.md"; fi
exit 0
