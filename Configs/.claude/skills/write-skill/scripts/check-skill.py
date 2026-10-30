#!/usr/bin/env python3
"""Validate Claude Code skill directories. Exit 1 if any error.

usage: check-skill.py <skill-dir> [<skill-dir> ...]
"""
import re
import subprocess
import sys
from pathlib import Path

ALLOWED_KEYS = {"name", "description", "allowed-tools"}
PATH_RE = re.compile(r"(?<![\w/.~-])((?:references|scripts|assets|features)/[\w./-]*[\w/])")
HOME_SKILL_RE = re.compile(r"~/\.claude/skills/[\w./-]*[\w/]")
OPTIONAL_REFS = {"references/local.md"}


def parse_frontmatter(text):
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None, "SKILL.md must start with a '---' frontmatter line"
    try:
        end = lines.index("---", 1)
    except ValueError:
        return None, "frontmatter has no closing '---'"
    raw = lines[1:end]
    if any("\t" in line for line in raw):
        return None, "frontmatter contains a tab"
    fields, key = {}, None
    for line in raw:
        m = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", line)
        if m:
            key, value = m.group(1), m.group(2).strip()
            fields[key] = "" if value in (">", "|", ">-", "|-") else value
        elif key and line.startswith((" ", "-")):
            fields[key] = (fields[key] + " " + line.strip()).strip()
        elif line.strip():
            return None, f"cannot parse frontmatter line: {line!r}"
    for k, v in fields.items():
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
            fields[k] = v[1:-1].replace('\\"', '"')
    return fields, "\n".join(lines[end + 1:])


def check(skill_dir):
    errors, warnings = [], []
    skill_dir = Path(skill_dir).expanduser().resolve()
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        return [f"{skill_md} missing"], []
    fields, body = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
    if fields is None:
        return [body], []

    name, desc = fields.get("name", ""), fields.get("description", "")
    if name != skill_dir.name:
        errors.append(f"name '{name}' != directory '{skill_dir.name}'")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name or "-"):
        errors.append(f"name '{name}' is not kebab-case")
    if not desc:
        errors.append("description missing")
    elif len(desc) > 300:
        errors.append(f"description is {len(desc)} chars (max 300)")
    if desc and not re.search(r"\bUse (when|whenever|for|right before|before|after)\b", desc):
        warnings.append("description has no 'Use when ...' trigger clause")
    if "Use for /" in desc:
        errors.append("description says 'Use for /name'; describe the situations instead")
    for k in fields:
        if k == "disable-model-invocation":
            errors.append("disable-model-invocation blocks auto-triggering; remove it")
        elif k not in ALLOWED_KEYS:
            warnings.append(f"extra frontmatter key '{k}'")

    texts = [body] + [p.read_text(encoding="utf-8") for p in skill_dir.rglob("*.md") if p != skill_md]
    for text in texts:
        for ref in set(PATH_RE.findall(text)):
            if "<" in ref or "*" in ref or ref in OPTIONAL_REFS:
                continue
            if not (skill_dir / ref).exists() and not any((p / ref).exists() for p in skill_dir.rglob("*") if p.is_dir()):
                errors.append(f"referenced file not found: {ref}")
        for ref in set(HOME_SKILL_RE.findall(text)):
            sibling = skill_dir.parent / ref[len("~/.claude/skills/"):]
            if not sibling.exists() and not Path(ref).expanduser().exists():
                errors.append(f"referenced path not found: {ref}")

    for script in (skill_dir / "scripts").glob("*") if (skill_dir / "scripts").is_dir() else []:
        check_script(script, errors)
    for script in skill_dir.rglob("*.sh"):
        if script.parent.name != "scripts":
            check_script(script, errors)

    lines = body.count("\n")
    if lines > 150:
        warnings.append(f"body is {lines} lines; move reference material to references/")
    return errors, warnings


def check_script(script, errors):
    if not script.is_file():
        return
    if not script.stat().st_mode & 0o111:
        errors.append(f"{script.name} is not executable")
    if script.suffix == ".sh":
        r = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
        if r.returncode:
            errors.append(f"{script.name}: bash -n failed: {r.stderr.strip()}")
    elif script.suffix == ".py":
        try:
            compile(script.read_text(encoding="utf-8"), str(script), "exec")
        except SyntaxError as e:
            errors.append(f"{script.name}: line {e.lineno}: {e.msg}")


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    failed = False
    for d in argv[1:]:
        errors, warnings = check(d)
        status = "FAIL" if errors else "ok"
        print(f"{status}  {d}")
        for e in errors:
            print(f"  error: {e}")
        for w in warnings:
            print(f"  warn:  {w}")
        failed |= bool(errors)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main(sys.argv)
