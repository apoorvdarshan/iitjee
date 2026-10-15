"""Structured values from fuzzer bytes, for the fuzz targets in this directory.

The targets build structured inputs (release notes, repository variables, App Store
Connect payloads, test-result trees) from the raw bytes libFuzzer mutates, so that
random bytes reach the interesting cases. Reading past the end of the data yields
zeros, so every byte string decodes to some valid input and decoding never raises.
"""
from __future__ import annotations

from typing import Sequence, TypeVar

T = TypeVar("T")

# Characters that matter to the parsers under test, mixed with arbitrary text.
TEXT_PIECES = (
    "", " ", "  ", "\t", "\n", "\r\n", "#", "## ", "v", ".", "0", "1", "9", "-",
    "true", "false", "yes", "no", "on", "off", "TRUE", " On ", "é", "ß", " ",
    " ", "﻿", "😀",
)


class FuzzInput:
    def __init__(self, data: bytes) -> None:
        self._data = data
        self._pos = 0

    def byte(self) -> int:
        if self._pos >= len(self._data):
            return 0
        value = self._data[self._pos]
        self._pos += 1
        return value

    def int_in(self, low: int, high: int) -> int:
        """An integer in [low, high]."""
        span = high - low + 1
        value = 0
        for _ in range(max(1, ((span - 1).bit_length() + 7) // 8)):
            value = (value << 8) | self.byte()
        return low + value % span

    def flag(self) -> bool:
        return self.byte() & 1 == 1

    def pick(self, options: Sequence[T]) -> T:
        return options[self.int_in(0, len(options) - 1)]

    def choose(self, likely: Sequence[T], unlikely: Sequence[T]) -> T:
        """Usually one of `likely`; one time in eight one of `unlikely`.

        Keeps most inputs close to valid so they get past the first check."""
        return self.pick(unlikely) if self.int_in(0, 7) == 0 else self.pick(likely)

    def text(self, max_pieces: int = 8, *, exclude: str = "") -> str:
        """Arbitrary text, built from parser-relevant pieces and raw UTF-8 bytes.

        Characters in `exclude` never appear, so a target can build text that
        cannot contain a structural marker it adds itself."""
        parts = []
        for _ in range(self.int_in(0, max_pieces)):
            if self.flag():
                parts.append(self.pick(TEXT_PIECES))
            else:
                raw = bytes(self.byte() for _ in range(self.int_in(1, 4)))
                parts.append(raw.decode("utf-8", "replace"))
        text = "".join(parts)
        for char in exclude:
            text = text.replace(char, "")
        return text
