#!/usr/bin/env python3
"""Convert FPS Plus 0.2.7 chart JSON into Psych Engine chart JSON.

FPS Plus stores songs under assets/data/<song-folder>/<chart>.json. Each chart
wraps its data in `song`; note arrays are [time, lane, sustain, pitch, preset,
volume, extraLength, noteType]. Lanes 0..7 already match the classic Psych
ownership convention. Lanes >= 8 are effect-only events, not playable notes.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE = ROOT / "assets" / "data"
DEFAULT_OUTPUT = ROOT / "psych-port" / "mods" / "TNT" / "data"
DIFFICULTY_SUFFIXES = {"-easy": "easy", "-hard": "hard"}


def chart_difficulty(stem: str) -> tuple[str, str]:
    lowered = stem.lower()
    for suffix, difficulty in DIFFICULTY_SUFFIXES.items():
        if lowered.endswith(suffix):
            return stem[: -len(suffix)], difficulty
    return stem, "normal"


def clean_number(value: Any) -> Any:
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return value


def convert_chart(source_path: Path, output_root: Path) -> tuple[Path, Path, int, int]:
    source = json.loads(source_path.read_text(encoding="utf-8-sig"))
    original = source.get("song")
    if not isinstance(original, dict) or not isinstance(original.get("notes"), list):
        raise ValueError(f"Not an FPS Plus song chart: {source_path}")

    song_id, difficulty = chart_difficulty(source_path.stem)
    folder = source_path.parent.name.lower()
    psych_sections: list[dict[str, Any]] = []
    extras: list[dict[str, Any]] = []
    playable_count = 0
    effect_count = 0

    for section_index, section in enumerate(original["notes"]):
        if not isinstance(section, dict):
            continue
        out_section = {
            "sectionNotes": [],
            "lengthInSteps": section.get("lengthInSteps", 16),
            "mustHitSection": bool(section.get("mustHitSection", False)),
            "gfSection": section.get("typeOfSection", 0) == 1,
            "bpm": section.get("bpm", original.get("bpm", 100)),
            "changeBPM": bool(section.get("changeBPM", False)),
            "altAnim": bool(section.get("altAnim", False)),
        }

        for note_index, note in enumerate(section.get("sectionNotes", [])):
            if not isinstance(note, list) or len(note) < 2:
                continue
            time = clean_number(note[0])
            lane = int(note[1])
            sustain = clean_number(note[2] if len(note) > 2 else 0)
            note_type = int(note[7] if len(note) > 7 and note[7] is not None else 0)
            if lane >= 8:
                effect_count += 1
                extras.append({
                    "section": section_index,
                    "note": note_index,
                    "time": time,
                    "lane": lane,
                    "source": note,
                    "kind": "effect",
                })
                continue

            # FPS Plus's 0..7 lanes encode both player sides explicitly. Psych
            # encodes ownership in mustHitSection and expects lane 0..3. Keep
            # the source side when generating Psych's lane convention.
            source_player_side = lane >= 4
            lane %= 4
            if source_player_side != out_section["mustHitSection"]:
                lane += 4
            out_section["sectionNotes"].append([time, lane, sustain, f"FPSPlus-{note_type}" if note_type else ""])
            playable_count += 1
            extras.append({
                "section": section_index,
                "note": note_index,
                "time": time,
                "lane": lane,
                "pitch": note[3] if len(note) > 3 else 1,
                "preset": note[4] if len(note) > 4 else -1,
                "volume": note[5] if len(note) > 5 else 1,
                "extraLength": note[6] if len(note) > 6 else 0,
                "noteType": note_type,
                "source": note,
                "kind": "note",
            })
        psych_sections.append(out_section)

    psych_song = {
        "song": original.get("song", song_id),
        "notes": psych_sections,
        "bpm": original.get("bpm", 100),
        "needsVoices": bool(original.get("needsVoices", True)),
        "speed": original.get("speed", 1),
        "player1": original.get("player1", "bf"),
        "player2": original.get("player2", "dad"),
        "gfVersion": original.get("gf", "gf"),
        "stage": original.get("stage", "stage"),
        "validScore": True,
    }

    destination = output_root / folder
    destination.mkdir(parents=True, exist_ok=True)
    chart_path = destination / (f"{folder}.json" if difficulty == "normal" else f"{folder}-{difficulty}.json")
    chart_path.write_text(json.dumps({"song": psych_song}, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
    extras_path = destination / (f"fpsplus-{difficulty}.json")
    extras_path.write_text(json.dumps({
        "source": "FPS Plus",
        "sourceChart": source_path.name,
        "song": folder,
        "difficulty": difficulty,
        "customNotes": extras,
    }, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
    return chart_path, extras_path, playable_count, effect_count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE, help="FPS Plus assets/data directory")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Psych mod data directory")
    args = parser.parse_args()
    charts = sorted(
        path for path in args.source.glob("*/*.json")
        if not path.parent.name.startswith("_")
        and path.name.lower() not in {"volumes.json", "pitches.json"}
    )
    converted = 0
    total_notes = 0
    total_effects = 0
    for path in charts:
        try:
            _, _, notes, effects = convert_chart(path, args.output)
        except (ValueError, json.JSONDecodeError) as error:
            print(f"SKIP {path.relative_to(args.source)}: {error}")
            continue
        converted += 1
        total_notes += notes
        total_effects += effects
    print(f"Converted {converted} charts, {total_notes} playable notes, {total_effects} effect events.")
    print(f"Output: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
