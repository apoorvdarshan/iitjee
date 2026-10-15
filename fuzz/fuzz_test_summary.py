#!/usr/bin/env python3
"""Fuzz target: the test-result checker in scripts/ios_test_summary.py.

The iOS tests workflow passes only when this checker accepts an .xcresult summary.
For any test tree, `count_cases` must count every test case under its unit or UI
test bundle (and reject a test case outside any bundle), and `check` must report
no problems exactly when every counted test passed and each required kind of test
ran at least once.

  python3 fuzz/fuzz_test_summary.py -max_total_time=60   # needs Atheris
"""
from __future__ import annotations

import contextlib
import sys
from collections import Counter
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
sys.path[:0] = [str(HERE), str(HERE.parent / "scripts")]

try:
    import atheris
except ImportError:  # test_fuzz_targets.py replays the target without Atheris
    atheris = None

with atheris.instrument_imports() if atheris else contextlib.nullcontext():
    from ios_test_summary import check, count_cases

from fuzz_input import FuzzInput

BUNDLES = {"Unit test bundle": "unit", "UI test bundle": "ui"}
NODE_TYPES = ("Unit test bundle", "UI test bundle", "Test Suite", "Test Case", "Test Case", "Device", "Test Plan", "Arguments")
RESULTS = ("Passed", "Passed", "Passed", "Failed", "Skipped", "Expected Failure", "passed", None)


def TestOneInput(data: bytes) -> None:
    fuzz = FuzzInput(data)
    # (bundle kind or None, result) of every test case the checker should count.
    cases: list[tuple[str | None, str]] = []

    def node(depth: int, kind: str | None, counted: bool) -> dict[str, Any]:
        node_type = fuzz.pick(NODE_TYPES) if fuzz.int_in(0, 7) else fuzz.text(2)
        kind = BUNDLES.get(node_type, kind)
        built: dict[str, Any] = {"nodeType": node_type, "name": fuzz.text(2)}
        if node_type == "Test Case":
            if fuzz.int_in(0, 7):
                built["result"] = fuzz.pick(RESULTS)
            if counted:
                cases.append((kind, built.get("result") or "Unknown"))
            counted = False  # nothing inside a test case is a separate test
        if depth < 4 and fuzz.flag():
            built["children"] = [node(depth + 1, kind, counted) for _ in range(fuzz.int_in(0, 3))]
        return built

    tree = [node(0, None, True) for _ in range(fuzz.int_in(0, 3))]
    try:
        counts = count_cases(tree)
    except SystemExit:
        assert any(kind is None for kind, _ in cases), ("rejected a valid tree", tree)
        return
    assert all(kind is not None for kind, _ in cases), ("counted a test case outside any bundle", tree)
    for kind in ("unit", "ui"):
        assert counts[kind] == dict(Counter(result for k, result in cases if k == kind)), (kind, counts, tree)

    require_unit, require_ui = fuzz.flag(), fuzz.flag()
    problems = check(counts, require_unit=require_unit, require_ui=require_ui)
    passes = (
        all(result == "Passed" for _, result in cases)
        and (not require_unit or any(kind == "unit" for kind, _ in cases))
        and (not require_ui or any(kind == "ui" for kind, _ in cases))
    )
    assert (not problems) == passes, (problems, cases, require_unit, require_ui)


def main() -> None:
    if atheris is None:
        raise SystemExit("Atheris is required: pip install --require-hashes -r fuzz/requirements.txt")
    atheris.Setup(sys.argv, TestOneInput)
    atheris.Fuzz()


if __name__ == "__main__":
    main()
