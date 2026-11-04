#!/usr/bin/env bash
f="$HOME/.claude/skills/unslop/SKILL.md"
[ -f "$f" ] || exit 0
echo "## Writing rules for every reply you write to the user"
echo "Apply the unslop rules below to your chat replies as you write them, not only to documents. Lead with the conclusion, then only what changes what the user does next. No preamble, no recap of what was asked, no closing offers."
echo
awk '/^---$/ {n++; next} n>=2' "$f"
exit 0
