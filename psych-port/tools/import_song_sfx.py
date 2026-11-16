#!/usr/bin/env python3
"""Convert song-specific Opus effects for the FPS Plus and Psych targets."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
FFMPEG = shutil.which("ffmpeg")
SOURCES = sorted((ROOT / "assets" / "music").glob("*_sfx.opus"))
TARGETS = [
    ROOT / "assets" / "sounds" / "shaggy",
    ROOT / "psych-engine-1.0.4" / "mods" / "TNT" / "sounds",
]


def main() -> int:
    if SOURCES and FFMPEG is None:
        raise SystemExit("ffmpeg is required to convert the Opus song effects to OGG.")
    converted = 0
    for source in SOURCES:
        for target_root in TARGETS:
            target_root.mkdir(parents=True, exist_ok=True)
            target = target_root / f"{source.stem}.ogg"
            subprocess.run(
                [FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", str(source), "-c:a", "libvorbis", "-q:a", "5", str(target)],
                check=True,
            )
        converted += 1
    print(f"Converted {converted} song effects into both game targets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
