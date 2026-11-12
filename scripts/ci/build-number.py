#!/usr/bin/env python3
"""The one source of store build numbers: Android versionCode, iOS CFBundleVersion, MSIX version.

Prints whole minutes since 2026-01-01T00:00Z. It needs no stored counter, so the local release
script and Codemagic can never hand out the same number twice for one app, and a later build is
always higher (Play, App Store Connect and Partner Center all reject a reused or lower number).

  python -I scripts/ci/build-number.py   ->   454321
"""
import time

EPOCH = 1767225600  # 2026-01-01T00:00:00Z
PLAY_MAX_VERSION_CODE = 2_100_000_000


def build_number(now: float) -> int:
    n = (int(now) - EPOCH) // 60
    if not 0 < n <= PLAY_MAX_VERSION_CODE:
        raise SystemExit(f"build number {n} is out of range; check this machine's clock")
    return n


assert build_number(EPOCH + 60) == 1 and build_number(EPOCH + 119) == 1 and build_number(EPOCH + 120) == 2

if __name__ == "__main__":
    print(build_number(time.time()))
