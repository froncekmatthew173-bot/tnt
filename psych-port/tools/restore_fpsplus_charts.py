#!/usr/bin/env python3
"""Rebuild original FPS Plus charts from the converter's source-note sidecars."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CONVERTED = ROOT / "psych-port" / "mods" / "TNT" / "data"
SOURCE = ROOT / "assets" / "data"


def main() -> int:
    restored = 0
    for folder in CONVERTED.iterdir():
        if not folder.is_dir() or folder.name.startswith("shaggy"):
            continue
        for sidecar in folder.glob("fpsplus-*.json"):
            metadata = json.loads(sidecar.read_text(encoding="utf-8"))
            chart_path = folder / (folder.name + ("" if metadata["difficulty"] == "normal" else f'-{metadata["difficulty"]}') + ".json")
            if not chart_path.exists():
                continue
            converted = json.loads(chart_path.read_text(encoding="utf-8"))["song"]
            sections = []
            for index, section in enumerate(converted["notes"]):
                restored_notes = [item["source"] for item in metadata["customNotes"] if item["section"] == index]
                sections.append({
                    "sectionNotes": restored_notes,
                    "lengthInSteps": section.get("lengthInSteps", 16),
                    "typeOfSection": 1 if section.get("gfSection", False) else 0,
                    "altAnim": section.get("altAnim", False),
                    "changeBPM": section.get("changeBPM", False),
                    "bpm": section.get("bpm", converted["bpm"]),
                    "mustHitSection": section.get("mustHitSection", False),
                })
            original = dict(converted)
            original["notes"] = sections
            original["gf"] = original.pop("gfVersion", "gf")
            destination = SOURCE / folder.name / metadata["sourceChart"]
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(json.dumps({"song": original}, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
            restored += 1
    print(f"Restored {restored} original FPS Plus charts from preserved note sidecars.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
