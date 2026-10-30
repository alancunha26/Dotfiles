#!/usr/bin/env python3
"""List this project's Claude Code transcripts, or print a compact digest of one.

usage: transcript.py list [project-dir]
       transcript.py digest <file.jsonl> [--max-chars N]
"""
import json
import os
import re
import sys
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"


def project_store(cwd):
    return PROJECTS / re.sub(r"[^A-Za-z0-9]", "-", os.path.abspath(cwd))


def entries(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def texts(message):
    content = message.get("content")
    if isinstance(content, str):
        return [content]
    if isinstance(content, list):
        return [p.get("text", "") for p in content if isinstance(p, dict) and p.get("type") == "text"]
    return []


def first_prompt(path):
    for e in entries(path):
        if e.get("type") == "user" and not e.get("isMeta"):
            for t in texts(e.get("message", {})):
                if t.strip():
                    return " ".join(t.split())[:100]
    return ""


def cmd_list(cwd):
    store = project_store(cwd)
    if not store.is_dir():
        sys.exit(f"no transcript store at {store}")
    files = sorted(store.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)[:10]
    for p in files:
        subs = len(list((store / p.stem / "subagents").glob("*.jsonl")))
        print(f"{p}\t{subs} subagents\t{first_prompt(p)}")


def cmd_digest(path, max_chars):
    turn = 0
    for e in entries(path):
        kind = e.get("type")
        if kind not in ("user", "assistant") or e.get("isMeta") or e.get("isSidechain"):
            continue
        body = " ".join(" ".join(texts(e.get("message", {}))).split())
        if not body:
            continue
        if kind == "user":
            turn += 1
            print(f"\n[{turn}] USER: {clip(body, max_chars * 4)}")
        else:
            print(f"    AGENT: {clip(body, max_chars)}")


def clip(text, limit):
    return text if len(text) <= limit else text[:limit] + "..."


def main(argv):
    if len(argv) >= 2 and argv[1] == "list":
        cmd_list(argv[2] if len(argv) > 2 else os.getcwd())
    elif len(argv) >= 3 and argv[1] == "digest":
        max_chars = int(argv[argv.index("--max-chars") + 1]) if "--max-chars" in argv else 300
        cmd_digest(argv[2], max_chars)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
