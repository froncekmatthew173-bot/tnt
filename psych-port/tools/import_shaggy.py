#!/usr/bin/env python3
"""Import the cloned Shaggy mod's content into the TNT Psych mod folder."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "psych-port" / "imports" / "the-shaggy-mod"
DEFAULT_TARGET = ROOT / "psych-engine-1.0.4" / "mods" / "TNT"


def merge_tree(source: Path, target: Path) -> int:
    copied = 0
    if not source.exists():
        return copied
    for path in source.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(source)
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)
        copied += 1
    return copied


def chart_key_count(song: dict) -> int:
    return (4, 6, 7, 9)[max(0, min(3, int(song.get("mania", 0))))]


def make_four_key_chart(source_path: Path, target_path: Path, raw_chart_path: Path) -> None:
    chart = json.loads(source_path.read_text(encoding="utf-8-sig"))
    raw_chart_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_path, raw_chart_path)
    song = chart["song"]
    count = chart_key_count(song)
    for section in song.get("notes", []):
        for note in section.get("sectionNotes", []):
            if len(note) < 2 or note[1] < 0:
                continue
            raw_lane = int(note[1])
            player_side = raw_lane < count
            player_owns_note = player_side if section.get("mustHitSection", False) else not player_side
            lane = raw_lane % count % 4
            note[1] = lane if player_owns_note == section.get("mustHitSection", False) else lane + 4
    song.pop("mania", None)
    song["sourceMania"] = count
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_text(json.dumps(chart, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--target", type=Path, default=DEFAULT_TARGET)
    args = parser.parse_args()
    source_assets = args.source / "assets"
    target = args.target
    counts = 0

    # Shaggy's checked-in source assets live in preload/shared libraries.
    for area in ("images", "music", "sounds"):
        counts += merge_tree(source_assets / "preload" / area, target / area)
        counts += merge_tree(source_assets / "shared" / area, target / area)
    # Only Shaggy characters are mod-owned. Keep shared BF/GF/Dad JSON files
    # from overriding the host game's character definitions.
    character_ids = {"pshaggy", "rshaggy", "shaggy", "spamton", "sshaggy", "wbshaggy", "zshaggy"}
    for character_id in character_ids:
        source_character = source_assets / "preload" / "characters" / f"{character_id}.json"
        if source_character.exists():
            destination = target / "characters" / source_character.name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_character, destination)
            counts += 1
    # Put Shaggy tracks in song-ID-prefixed folders so they cannot replace
    # same-named TNT tracks in the host mod.
    songs_root = source_assets / "songs"
    for song_dir in songs_root.iterdir() if songs_root.exists() else []:
        if song_dir.is_dir():
            counts += merge_tree(song_dir, target / "songs" / f"shaggy-{song_dir.name.lower()}")

    # Psych 1.0.4's runtime is four-column. Keep the full source charts as
    # sidecars and fold their columns into four playable directions for now.
    for source_chart in sorted((source_assets / "preload" / "data").glob("*/*.json")):
        if source_chart.name.lower() in {"events.json"}:
            continue
        try:
            parsed = json.loads(source_chart.read_text(encoding="utf-8-sig"))
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(parsed.get("song"), dict) or not isinstance(parsed["song"].get("notes"), list):
            continue
        relative = source_chart.relative_to(source_assets / "preload" / "data")
        output_song = f"shaggy-{relative.parts[0]}"
        target_relative = Path(output_song) / source_chart.name.replace(relative.parts[0], output_song, 1)
        source_copy = target / "data" / "shaggy-source" / relative
        make_four_key_chart(
            source_chart,
            target / "data" / target_relative,
            source_copy,
        )
        converted = json.loads((target / "data" / target_relative).read_text(encoding="utf-8"))
        converted["song"]["song"] = output_song
        (target / "data" / target_relative).write_text(json.dumps(converted, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
        counts += 1

    weeks = [
        ("week-shaggy-1", "Shaggy Week 1", ["shaggy-where-are-you", "shaggy-eruption", "shaggy-kaio-ken"]),
        ("week-shaggy-2", "Shaggy Week 2", ["shaggy-whats-new", "shaggy-blast", "shaggy-super-saiyan"]),
        ("week-shaggy-3", "Shaggy Week 3", ["shaggy-god-eater"]),
        ("week-shaggy-4", "Shaggy Bonus Week", ["shaggy-soothing-power", "shaggy-thunderstorm", "shaggy-dissasembler"]),
        ("week-shaggy-5", "Shaggy Encore", ["shaggy-talladega", "shaggy-big-shot", "shaggy-astral-calamity"]),
    ]
    weeks_dir = target / "weeks"
    weeks_dir.mkdir(parents=True, exist_ok=True)
    (weeks_dir / "weekList.txt").write_text("\n".join(item[0] for item in weeks) + "\n", encoding="utf-8")
    for week_index, (week_id, title, songs) in enumerate(weeks):
        data = {
            "songs": [[song, "shaggy", [112, 74, 164]] for song in songs],
            "weekCharacters": ["shaggy", "bf", "gf"],
            "weekBackground": "stage",
            "weekBefore": "week1" if week_index == 0 else weeks[week_index - 1][0],
            "storyName": title,
            "weekName": title,
            "startUnlocked": True,
            "hiddenUntilUnlocked": False,
            "hideStoryMode": False,
            "hideFreeplay": False,
            "difficulties": "easy,normal,hard",
        }
        (weeks_dir / f"{week_id}.json").write_text(json.dumps(data, indent="\t") + "\n", encoding="utf-8")

    menu_chars = target / "images" / "menucharacters"
    menu_chars.mkdir(parents=True, exist_ok=True)
    menu_config = {
        "image": "Menu_Shaggy",
        "scale": 1,
        "position": [0, 10],
        "idle_anim": "M Shaggy Idle",
        "confirm_anim": "",
        "flipX": False,
        "antialiasing": True,
    }
    (menu_chars / "shaggy.json").write_text(json.dumps(menu_config, indent="\t") + "\n", encoding="utf-8")

    target.mkdir(parents=True, exist_ok=True)
    (target / "pack.json").write_text(json.dumps({
        "name": "TNT + Shaggy",
        "description": "TNT charts and the imported Shaggy campaign content.",
        "restart": False,
        "runsGlobally": False,
        "color": [112, 74, 164],
    }, indent="\t") + "\n", encoding="utf-8")
    (target / "SHAGGY_SOURCE.md").write_text(
        "# Shaggy source and content\n\n"
        "Imported from [GithubSPerez/the-shaggy-mod](https://github.com/GithubSPerez/the-shaggy-mod). "
        "The complete cloned source and its Apache 2.0 license are kept in `psych-port/imports/the-shaggy-mod`. "
        "This folder contains the original Shaggy campaign assets, charts, and songs, plus TNT charts.\n",
        encoding="utf-8",
    )
    print(f"Imported {counts} Shaggy asset files into {target}")
    print(f"Created {len(weeks)} Shaggy story weeks.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
