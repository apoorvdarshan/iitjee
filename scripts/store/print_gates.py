#!/usr/bin/env python3
"""Print the iOS store automation switches. Never mutates a store.

Values are shown as configured; scripts/store/ios_release.py is what validates
them (an invalid value fails the release run even when the master switch is off).
"""
from __future__ import annotations

import os

GATES = (
    "IOS_RELEASE_AUTOMATION",
    "IOS_UPLOAD_BUILD",
    "IOS_UPLOAD_LISTING",
    "IOS_UPLOAD_WHATS_NEW",
    "IOS_UPLOAD_SCREENSHOTS",
    "IOS_SUBMIT_REVIEW",
    "IOS_PUBLIC_RELEASE",
)
TIMING = ("IOS_BUILD_POLL_SECONDS", "IOS_BUILD_WAIT_MINUTES")


def enabled(name: str) -> bool:
    return os.environ.get(name, "").strip().lower() in {"1", "true", "yes", "on"}


def main() -> None:
    print("iOS store automation switches (missing or false = off):")
    for name in GATES:
        raw = os.environ.get(name, "")
        shown = "true" if enabled(name) else ("false" if not raw.strip() else raw.strip())
        print(f"  {name}={shown}")
    for name in TIMING:
        print(f"  {name}={os.environ.get(name, '').strip() or '(default)'}")
    if not enabled("IOS_RELEASE_AUTOMATION"):
        print("  note: IOS_RELEASE_AUTOMATION is off, so every iOS store operation is skipped")
        return
    on = [name for name in GATES[1:] if enabled(name)]
    if on:
        print(f"WARNING: live App Store operations are on: {', '.join(on)}")
    else:
        print("master switch on, but every store operation is off")


if __name__ == "__main__":
    main()
