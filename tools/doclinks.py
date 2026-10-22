#!/usr/bin/env python3
"""Keeps the links from the docs into src/avatar-copier.lua pointing at the right lines.

A line link into the script says what it points at, so the line numbers can be checked:

  [`Catalog.search`](../../src/avatar-copier.lua#L2419-L2444)
      The text names a top-level definition; luau-ast gives its first and last line.
  [the hotkeys](../../src/avatar-copier.lua#L1008-L1014 "UIS.InputBegan:Connect")
      The title is text from exactly one line of the script. When that line starts a top-level
      statement the link covers the whole statement, otherwise just that line.

The tool reports links whose lines are wrong, or rewrites them with --write. It also checks that every
```lua excerpt block matches the script line by line (lines that are only "…" are skipped), and that
relative links and #anchors between the docs resolve.

Usage: python3 tools/doclinks.py path/to/luau-ast [--write]
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = "src/avatar-copier.lua"
CODE_LINK = re.compile(r'\[([^\]]+)\]\(((?:\.\./)*src/avatar-copier\.lua)(#L\d+(?:-L\d+)?)?(?: "([^"]+)")?\)')
ANY_LINK = re.compile(r'!?\[[^\]]*\]\(([^)\s]+)(?: "[^"]*")?\)|<img src="([^"]+)"')
HEADING = re.compile(r"^(#{1,6})\s+(.+?)\s*$")


def name_of(expr):
    kind = expr.get("type")
    if kind == "AstExprGlobal":
        return expr["global"]
    if kind == "AstExprLocal":
        return expr["local"]["name"]
    if kind == "AstExprIndexName":
        base = name_of(expr["expr"])
        return base and base + expr.get("op", ".") + expr["index"]
    return None


def lines_of(location):
    start, end = location.split(" - ")
    return int(start.split(",")[0]) + 1, int(end.split(",")[0]) + 1


def definitions(luau_ast):
    """Named top-level definitions -> [(first, last)], and first line -> last line of every top-level statement."""
    out = subprocess.run([luau_ast, os.path.join(ROOT, SRC)], capture_output=True, check=True).stdout
    found, statements = {}, {}
    for stat in json.loads(out.decode("latin-1"))["root"]["body"]:
        first, last = lines_of(stat["location"])
        statements[first] = max(last, statements.get(first, first))
        kind, names = stat["type"], []
        if kind == "AstStatFunction":
            names = [name_of(stat["name"])]
        elif kind == "AstStatLocalFunction":
            names = [stat["name"]["name"]]
        elif kind == "AstStatAssign" and len(stat["vars"]) == 1:
            names = [name_of(stat["vars"][0])]
        elif kind == "AstStatLocal":
            names = [var["name"] for var in stat["vars"]]
        for name in names:
            if name:
                found.setdefault(name, []).append((first, last))
    return found, statements


def anchor_slug(text):
    text = re.sub(r"`|\*\*|__", "", text.strip().lower())
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def strip_code(text):
    return re.sub(r"^```.*?^```", "", text, flags=re.S | re.M)


def markdown_files():
    for base, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for file in files:
            if file.endswith(".md"):
                yield os.path.relpath(os.path.join(base, file), ROOT)


def main():
    if len(sys.argv) < 2:
        print(__doc__.strip())
        return 2
    write = "--write" in sys.argv[2:]
    defs, statements = definitions(sys.argv[1])
    source = open(os.path.join(ROOT, SRC), encoding="utf-8").read().split("\n")
    stripped = [line.strip() for line in source]
    docs = {path: open(os.path.join(ROOT, path), encoding="utf-8").read() for path in markdown_files()}
    anchors = {}
    for path, text in docs.items():
        seen = {}
        for line in strip_code(text).split("\n"):
            match = HEADING.match(line)
            if match:
                slug = anchor_slug(match.group(2))
                count = seen.get(slug, 0)
                seen[slug] = count + 1
                anchors.setdefault(path, set()).add(slug if count == 0 else f"{slug}-{count}")
    problems, fixed = [], 0

    for path, text in docs.items():
        def replace(match):
            nonlocal fixed
            label, target, anchor, title = match.groups()
            if title:
                spots = [number for number, line in enumerate(source, 1) if title in line]
                if len(spots) != 1:
                    problems.append(f'{path}: "{title}" is on {len(spots)} lines of {SRC}; it must be on exactly one')
                    return match.group(0)
                start = spots[0]
                end = statements.get(start, start)
                what = f'"{title}"'
            elif label.startswith("`") and label.endswith("`"):
                name = label.strip("`").removesuffix("()").removeprefix("function ")
                spots = defs.get(name)
                if not spots:
                    if anchor:
                        problems.append(f"{path}: `{name}` is not a top-level definition in {SRC}")
                    return match.group(0)
                if len(spots) > 1:
                    problems.append(f"{path}: `{name}` is defined {len(spots)} times; use a title to pick one")
                    return match.group(0)
                start, end = spots[0]
                what = f"`{name}`"
            else:
                if anchor:
                    problems.append(f"{path}: the link to {target}{anchor} needs a definition name in backticks or a title")
                return match.group(0)
            want = f"#L{start}" if start == end else f"#L{start}-L{end}"
            if anchor != want:
                if not write:
                    problems.append(f"{path}: {what} should link {want}, not {anchor or 'no lines'}")
                    return match.group(0)
                fixed += 1
            return f"[{label}]({target}{want}" + (f' "{title}")' if title else ")")
        # Links inside fenced code blocks are examples, not links.
        new = "".join(part if part.startswith("```") else CODE_LINK.sub(replace, part)
                      for part in re.split(r"(^```.*?^```)", text, flags=re.S | re.M))
        if new != text:
            docs[path] = new
            open(os.path.join(ROOT, path), "w", encoding="utf-8").write(new)

    for path, text in docs.items():
        # Excerpts must be copied from the script, in order.
        for block in re.finditer(r"^```lua excerpt\n(.*?)^```", text, flags=re.S | re.M):
            position = 0
            first = text[:block.start()].count("\n") + 2
            for offset, line in enumerate(block.group(1).split("\n")[:-1]):
                wanted = line.strip()
                if wanted in ("", "…", "...", "-- …"):
                    continue
                try:
                    position = stripped.index(wanted, position) + 1
                except ValueError:
                    problems.append(f"{path}:{first + offset}: excerpt line not found in {SRC} (in order): {wanted[:80]}")
                    break
        # Relative links and anchors.
        for match in ANY_LINK.finditer(strip_code(text)):
            target = match.group(1) or match.group(2)
            if re.match(r"^[a-z]+:", target) or target.startswith("mailto:"):
                continue
            file, _, anchor = target.partition("#")
            full = os.path.normpath(os.path.join(os.path.dirname(path), file)) if file else path
            if not os.path.exists(os.path.join(ROOT, full)):
                problems.append(f"{path}: broken link {target}")
            elif anchor and full.endswith(".md") and anchor not in anchors.get(full, set()):
                problems.append(f"{path}: missing anchor {target}")
            elif anchor and full == SRC and not re.match(r"^L\d+(-L\d+)?$", anchor):
                problems.append(f"{path}: bad line anchor {target}")

    if write and fixed:
        print(f"updated {fixed} code link(s)")
    for problem in problems:
        print("FAIL: " + problem)
    if not problems:
        print("OK: doc links and excerpts match the script")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
