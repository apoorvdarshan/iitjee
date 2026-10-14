#!/usr/bin/env python3
"""Check an .xcresult bundle: tests must have run, passed, and not been skipped.

  python3 scripts/ios_test_summary.py <result.xcresult> --require-unit --require-ui

Fails when a required kind of test (unit or UI) ran zero tests, when any test
failed, or when any test was skipped (every test runs on the device it targets,
so a skip means lost coverage). Prints the counts either way.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from typing import Any

BUNDLE_KINDS = {"Unit test bundle": "unit", "UI test bundle": "ui"}


def count_cases(nodes: list[dict[str, Any]]) -> dict[str, dict[str, int]]:
    """Per bundle kind, how many test cases ended in each result."""
    counts: dict[str, dict[str, int]] = {"unit": {}, "ui": {}}

    def walk(node: dict[str, Any], kind: str | None) -> None:
        node_type = node.get("nodeType")
        kind = BUNDLE_KINDS.get(node_type, kind)
        if node_type == "Test Case":
            if kind is None:
                raise SystemExit(f"error: test case {node.get('name')!r} is outside a test bundle")
            result = node.get("result") or "Unknown"
            counts[kind][result] = counts[kind].get(result, 0) + 1
            return
        for child in node.get("children") or []:
            walk(child, kind)

    for node in nodes:
        walk(node, None)
    return counts


def check(counts: dict[str, dict[str, int]], *, require_unit: bool, require_ui: bool) -> list[str]:
    problems = []
    for kind, required in (("unit", require_unit), ("ui", require_ui)):
        results = counts[kind]
        total = sum(results.values())
        if required and total == 0:
            problems.append(f"no {kind} tests ran")
        for result, number in sorted(results.items()):
            if result != "Passed":
                problems.append(f"{number} {kind} test(s) {result.lower()}")
    return problems


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("result_bundle")
    parser.add_argument("--require-unit", action="store_true")
    parser.add_argument("--require-ui", action="store_true")
    args = parser.parse_args(argv)

    output = subprocess.run(
        ["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", args.result_bundle],
        check=True, capture_output=True, text=True,
    ).stdout
    counts = count_cases(json.loads(output).get("testNodes") or [])
    for kind in ("unit", "ui"):
        results = ", ".join(f"{n} {r.lower()}" for r, n in sorted(counts[kind].items())) or "none"
        print(f"{args.result_bundle}: {kind} tests: {results}")
    problems = check(counts, require_unit=args.require_unit, require_ui=args.require_ui)
    if problems:
        print(f"error: {'; '.join(problems)}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
