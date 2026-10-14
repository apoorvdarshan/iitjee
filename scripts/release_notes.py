#!/usr/bin/env python3
"""Print the reviewed RELEASE_NOTES.md section for an exact release tag.

A `## <tag>` section (e.g. `## v1.0.1`) becomes the GitHub Release notes. When the
tag has no section, nothing is printed and the release uses GitHub's generated
notes instead. A section that exists but is empty is a mistake and fails.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

NOTES = Path(__file__).resolve().parents[1] / "RELEASE_NOTES.md"


def section_for(text: str, tag: str) -> str | None:
    """The body under `## <tag>`, or None when the tag has no section."""
    for section in re.split(r"^## ", text, flags=re.MULTILINE)[1:]:
        title, _, body = section.partition("\n")
        if title.strip() == tag:
            body = body.strip()
            if not body:
                raise ValueError(f"the ## {tag} section in RELEASE_NOTES.md is empty")
            return body
    return None


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tag")
    parser.add_argument("--out", type=Path, help="write the notes here (an empty file means generated notes)")
    args = parser.parse_args(argv)
    try:
        notes = section_for(NOTES.read_text(encoding="utf-8"), args.tag)
    except ValueError as exc:
        parser.error(str(exc))
    if notes is None:
        print(f"RELEASE_NOTES.md has no ## {args.tag} section; using generated notes", file=sys.stderr)
    if args.out:
        args.out.write_text(notes + "\n" if notes else "", encoding="utf-8")
    elif notes:
        print(notes)


if __name__ == "__main__":
    main()
