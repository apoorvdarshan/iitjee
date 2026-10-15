#!/usr/bin/env python3
"""Tests for scripts/ios_test_summary.py (no Xcode needed).

Run: python3 -m unittest scripts/test_ios_test_summary.py
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ios_test_summary import check, count_cases  # noqa: E402


def case(name: str, result: str = "Passed", children: list | None = None) -> dict:
    return {"nodeType": "Test Case", "name": name, "result": result, "children": children or []}


def bundle(kind: str, *cases: dict) -> dict:
    return {"nodeType": kind, "name": kind, "children": [{"nodeType": "Test Suite", "children": list(cases)}]}


def plan(*bundles: dict) -> list[dict]:
    return [{"nodeType": "Test Plan", "name": "PCMNotes", "children": list(bundles)}]


class SummaryTests(unittest.TestCase):
    def test_counts_cases_per_bundle_kind(self) -> None:
        nodes = plan(
            bundle("Unit test bundle", case("a()"), case("b()")),
            bundle("UI test bundle", case("testA()"), case("testB()", "Skipped"),
                   case("testC()", children=[{"nodeType": "Arguments", "name": "Dark", "result": "Passed"}])),
        )
        self.assertEqual(count_cases(nodes), {"unit": {"Passed": 2}, "ui": {"Passed": 2, "Skipped": 1}})

    def test_all_passed_is_clean(self) -> None:
        counts = count_cases(plan(bundle("Unit test bundle", case("a()")), bundle("UI test bundle", case("t()"))))
        self.assertEqual(check(counts, require_unit=True, require_ui=True), [])

    def test_zero_required_tests_fail(self) -> None:
        counts = count_cases(plan(bundle("UI test bundle", case("t()"))))
        self.assertEqual(check(counts, require_unit=True, require_ui=True), ["no unit tests ran"])
        self.assertEqual(check(count_cases([]), require_unit=False, require_ui=True), ["no ui tests ran"])
        self.assertEqual(check(counts, require_unit=False, require_ui=True), [])

    def test_failures_and_skips_fail(self) -> None:
        counts = count_cases(plan(bundle("UI test bundle", case("a()", "Failed"), case("b()", "Skipped"))))
        self.assertEqual(check(counts, require_unit=False, require_ui=True),
                         ["1 ui test(s) failed", "1 ui test(s) skipped"])

    def test_case_outside_a_bundle_is_an_error(self) -> None:
        with self.assertRaises(SystemExit):
            count_cases([case("orphan()")])


if __name__ == "__main__":
    unittest.main()
