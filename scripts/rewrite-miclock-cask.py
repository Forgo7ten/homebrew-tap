#!/usr/bin/env python3

import pathlib
import re
import sys


def main() -> int:
    if len(sys.argv) != 6:
        raise SystemExit(
            "usage: rewrite-miclock-cask.py "
            "<source-cask> <output-cask> <version> <arm-sha256> <intel-sha256>"
        )

    source_path = pathlib.Path(sys.argv[1])
    output_path = pathlib.Path(sys.argv[2])
    version = sys.argv[3]
    arm_sha = sys.argv[4]
    intel_sha = sys.argv[5]

    if not source_path.is_file():
        raise SystemExit(f"Cask file does not exist: {source_path}")

    if re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version) is None:
        raise SystemExit(f"Invalid Cask version: {version}")

    if re.fullmatch(r"[0-9A-Fa-f]{64}", arm_sha) is None:
        raise SystemExit("Invalid ARM64 SHA256")

    if re.fullmatch(r"[0-9A-Fa-f]{64}", intel_sha) is None:
        raise SystemExit("Invalid Intel SHA256")

    source = source_path.read_text(encoding="utf-8")

    updated, version_count = re.subn(
        r'^  version "[^"\n]+"$',
        f'  version "{version}"',
        source,
        flags=re.MULTILINE,
    )

    updated, sha_count = re.subn(
        r'^  sha256 (?::no_check|arm:\s+"[0-9A-Fa-f]{64}",\n\s+intel:\s+"[0-9A-Fa-f]{64}")$',
        f'  sha256 arm:   "{arm_sha}",\n'
        f'         intel: "{intel_sha}"',
        updated,
        flags=re.MULTILINE,
    )

    if version_count != 1:
        raise SystemExit(
            f"Cask must contain exactly one version stanza; found {version_count}"
        )

    if sha_count != 1:
        raise SystemExit(
            f"Cask must contain exactly one supported sha256 stanza; found {sha_count}"
        )

    output_path.write_text(updated, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
