#!/usr/bin/env python3
"""Install Shaggy content and 4-key charts into the FPS Plus source project."""

from __future__ import annotations

import json
import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ASSETS = ROOT / "psych-port" / "imports" / "the-shaggy-mod" / "assets"
DEST_ASSETS = ROOT / "assets"
SONGS = [
    "where-are-you", "eruption", "kaio-ken", "whats-new", "blast", "super-saiyan",
    "god-eater", "soothing-power", "thunderstorm", "dissasembler", "talladega",
    "big-shot", "astral-calamity",
]
SPECIAL_SOUNDFONTS = {"thunderstorm": "rshaggy-thunderstorm"}
CHARACTER_SOUNDFONTS = {"sshaggy": "shaggy"}
SHAGGY_VOCAL_GAIN = 0.9


def key_count(song: dict) -> int:
    return (4, 6, 7, 9)[max(0, min(3, int(song.get("mania", 0))))]


def main() -> int:
    # Keep all original Shaggy art in a namespaced tree to avoid replacing TNT assets.
    for library in ("preload", "shared"):
        src_images = SOURCE_ASSETS / library / "images"
        dst_images = DEST_ASSETS / "images" / "shaggy" / library
        if src_images.exists():
            shutil.copytree(src_images, dst_images, dirs_exist_ok=True)

    char_dir = DEST_ASSETS / "data" / "shaggy" / "characters"
    char_dir.mkdir(parents=True, exist_ok=True)
    for char_file in (SOURCE_ASSETS / "preload" / "characters").glob("*.json"):
        data = json.loads(char_file.read_text(encoding="utf-8-sig"))
        image = data.get("image", "")
        image_name = image.replace("/", "\\")
        if (SOURCE_ASSETS / "shared" / "images" / (image + ".png")).exists():
            data["image"] = f"shaggy/shared/{image}"
        else:
            data["image"] = f"shaggy/preload/{image}"
        (char_dir / char_file.name).write_text(json.dumps(data, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")

    # FPS Plus stores each character icon as a sheet; preserve the original 2-frame icons.
    icon_dir = DEST_ASSETS / "images" / "healthicons"
    icon_dir.mkdir(parents=True, exist_ok=True)
    source_icons = SOURCE_ASSETS / "preload" / "images" / "icons"
    for icon in source_icons.glob("icon-*.png"):
        character = icon.stem.removeprefix("icon-")
        if not character.endswith("shaggy") and character != "spamton":
            continue
        shutil.copy2(icon, icon_dir / icon.name.replace("icon-", ""))

    # Copy all original song audio with a namespaced folder path used by audioFolder.
    music_root = DEST_ASSETS / "music" / "shaggy"
    for song in SONGS:
        source_song = SOURCE_ASSETS / "songs" / song
        dest_song = music_root / song
        dest_song.mkdir(parents=True, exist_ok=True)
        for track in ("Inst.ogg", "Voices.ogg"):
            source_track = source_song / track
            if source_track.exists():
                shutil.copy2(source_track, dest_song / track)

    # Convert Shaggy's 4/6/7/9-key chart lanes to FPS Plus's four-column layout.
    # Package originals as sidecars so the runtime converter can restore them.
    converted_charts = 0
    copied_source_charts = 0
    source_data = SOURCE_ASSETS / "preload" / "data"
    for song_id in SONGS:
        song_source = source_data / song_id
        if not song_source.exists():
            continue
        output_id = f"shaggy-{song_id}"
        dest_song = DEST_ASSETS / "data" / output_id
        dest_song.mkdir(parents=True, exist_ok=True)
        for source_chart in song_source.glob("*.json"):
            chart = json.loads(source_chart.read_text(encoding="utf-8-sig"))
            song = chart.get("song")
            if not isinstance(song, dict) or not isinstance(song.get("notes"), list):
                continue
            if source_chart.name == "events.json":
                # The legacy FPS Plus chart reader does not support Psych event charts.
                continue
            columns = key_count(song)
            source_chart_key = f"shaggy-source/{song_id}/{source_chart.stem}"
            source_chart_dest = DEST_ASSETS / "data" / "shaggy-source" / song_id / source_chart.name
            source_chart_dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_chart, source_chart_dest)
            copied_source_charts += 1
            for section in song["notes"]:
                must_hit = bool(section.get("mustHitSection", False))
                for note in section.get("sectionNotes", []):
                    if len(note) < 2 or note[1] < 0:
                        continue
                    raw_lane = int(note[1])
                    player_owns_note = (raw_lane < columns) == must_hit
                    four_key_lane = raw_lane % columns % 4
                    note[1] = four_key_lane if player_owns_note == must_hit else four_key_lane + 4
                    note_type = int(note[3] if len(note) > 3 and note[3] is not None else 0)
                    while len(note) < 8:
                        note.append(0)
                    # The Shaggy charts have note timing and lanes but no MIDI
                    # pitch/preset fields. Map the four chart lanes to a simple
                    # four-note vocal phrase and render it with the character SF2.
                    note[3] = (60, 62, 65, 67)[four_key_lane]
                    note[4] = 0
                    note[5] = SHAGGY_VOCAL_GAIN
                    note[6] = 0
                    note[7] = note_type
                section.pop("gfSection", None)
            song["song"] = output_id
            song["audioFolder"] = f"shaggy/{song_id}"
            song["soundfont1"] = CHARACTER_SOUNDFONTS.get(song.get("player1", "bf"), song.get("player1", "bf"))
            player2 = song.get("player2", "dad")
            song["soundfont2"] = SPECIAL_SOUNDFONTS.get(song_id, CHARACTER_SOUNDFONTS.get(player2, player2))
            song["sourceMania"] = columns
            song["sourceChart"] = source_chart_key
            song["mania"] = 0
            target_name = source_chart.name
            (dest_song / target_name).write_text(json.dumps(chart, ensure_ascii=False, indent="\t") + "\n", encoding="utf-8")
            converted_charts += 1

    # Keep the full cloned content's non-chart SFX and background music available.
    for area in ("sounds", "music"):
        src = SOURCE_ASSETS / "preload" / area
        dst = DEST_ASSETS / area / "shaggy"
        if src.exists():
            shutil.copytree(src, dst, dirs_exist_ok=True)

    # Separate song effects are not vocal tracks; keep them in a sound-effect
    # namespace and let the audio conversion step produce engine-readable OGGs.
    for effect in DEST_ASSETS.joinpath("music").glob("*_sfx.opus"):
        effect_target = DEST_ASSETS / "sounds" / "shaggy" / f"{effect.stem}.opus"
        effect_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(effect, effect_target)

    print(f"Imported Shaggy art, character files, icons, audio, {converted_charts} four-key charts, "
          f"and {copied_source_charts} original charts.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
