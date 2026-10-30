#!/usr/bin/env bash
# SessionStart hook. Points ~/.claude/pstack at the newest installed pstack plugin and loads the unslop
# rules plus pstack's "Writing the reply" rules, so every chat reply is written by them.
base="$HOME/.claude/plugins/cache/cursor-plugins/pstack"
[ -d "$base" ] || exit 0
latest=$(ls -d "$base"/*/ 2>/dev/null | sort -V | tail -1)
latest=${latest%/}
[ -n "$latest" ] || exit 0
ln -sfn "$latest" "$HOME/.claude/pstack"
f="$latest/skills/unslop/SKILL.md"
[ -f "$f" ] || exit 0
echo "## Writing rules for every reply you write to the user"
echo "Apply the unslop rules and the reply rules below to your chat replies as you write them, not only to documents. Lead with the conclusion, then only what changes what the user does next. No preamble, no recap of what was asked, no closing offers."
echo
awk '/^---$/ {n++; next} n>=2' "$f"
p="$latest/skills/poteto-mode/SKILL.md"
if [ -f "$p" ]; then echo; awk '/^## Writing the reply/{f=1; print; next} f && /^## /{exit} f' "$p"; fi
if [ -f "$HOME/.claude/pstack-local/unslop.md" ]; then echo; cat "$HOME/.claude/pstack-local/unslop.md"; fi
exit 0
