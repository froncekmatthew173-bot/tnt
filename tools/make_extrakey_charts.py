"""
Build extra-key ("mania") versions of the game's charts.

Each chart gets its own key count (5K-9K). The layout is the normal 4
arrows plus (key count - 4) center space keys, so the chart's `mania`
field is the total number of keys. Space notes are stored as note type 7
on lanes 0..(center keys - 1); existing effect lanes (>= 8) are untouched.

Run from the repo root: python tools/make_extrakey_charts.py
"""

import json
import os
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "assets", "data")
SUFFIX = "-ek"

# (freeplay song folder, normal chart file, key count)
BASE_SONGS = [
    ("tutorial", "tutorial.json", 5),
    ("kickin", "kickin.json", 6),
    ("demoniac", "demoniac.json", 7),
    ("revenant", "revenant.json", 8),
    ("trigger-happy", "trigger-happy.json", 9),
    ("playtime", "playtime.json", 5),
    ("zombie-flower", "zombie-flower.json", 6),
    ("tune-a-fish", "tune-a-fish.json", 7),
    ("fresnel", "fresnel.json", 8),
    ("sio2", "sio2.json", 9),
    ("bopeebo", "bopeebo.json", 5),
    ("roses", "roses.json", 6),
    ("ugh", "ugh.json", 7),
]

# Shaggy songs already store their own audio folder in the chart.
SHAGGY_SONGS = [
    ("shaggy-where-are-you", "shaggy-where-are-you.json", 5),
    ("shaggy-eruption", "shaggy-eruption.json", 6),
    ("shaggy-kaio-ken", "shaggy-kaio-ken.json", 7),
    ("shaggy-whats-new", "shaggy-whats-new.json", 8),
    ("shaggy-blast", "shaggy-blast.json", 9),
    ("shaggy-super-saiyan", "shaggy-super-saiyan.json", 5),
    ("shaggy-god-eater", "shaggy-god-eater.json", 6),
    ("shaggy-soothing-power", "shaggy-soothing-power.json", 7),
    ("shaggy-thunderstorm", "shaggy-thunderstorm.json", 8),
    ("shaggy-dissasembler", "shaggy-dissasembler.json", 9),
    ("shaggy-talladega", "shaggy-talladega.json", 5),
    ("shaggy-big-shot", "shaggy-big-shot.json", 6),
    ("shaggy-astral-calamity", "shaggy-astral-calamity.json", 9),
    ("final-destination", "final-destination.json", 5),
    ("power-link", "power-link.json", 6),
    ("revenge", "revenge.json", 7),
]

SPACE_NOTE_TYPE = 7


def make_chart(folder, chart_file, key_count):
    src = os.path.join(DATA, folder, chart_file)
    if not os.path.exists(src):
        print("skip (missing):", src)
        return

    with open(src, encoding="utf-8-sig") as f:
        chart = json.load(f)

    song = chart["song"]
    song["mania"] = key_count
    center_keys = max(1, key_count - 4)

    bpm = float(song.get("bpm", 120) or 120)
    step_ms = 60000.0 / bpm / 4.0
    start = 0.0
    space_index = 0

    for index, section in enumerate(song.get("notes", [])):
        if section.get("changeBPM") and section.get("bpm"):
            bpm = float(section["bpm"])
            step_ms = 60000.0 / bpm / 4.0

        notes = section.get("sectionNotes") or []

        # One space note every other section, cycling through the center keys.
        if index % 2 == 0 and notes:
            has_space_here = any(
                isinstance(note, list) and len(note) > 7 and note[7] == SPACE_NOTE_TYPE
                and abs(float(note[0]) - start) < 1.0
                for note in notes
            )
            if not has_space_here:
                notes.append([round(start, 6), space_index % center_keys, 0, 62, 0, 1, 0, SPACE_NOTE_TYPE])
                notes.sort(key=lambda note: note[0])
                section["sectionNotes"] = notes
                space_index += 1

        start += int(section.get("lengthInSteps", 16)) * step_ms

    out_folder = os.path.join(DATA, folder + SUFFIX)
    os.makedirs(out_folder, exist_ok=True)
    out_file = os.path.join(out_folder, folder + SUFFIX + ".json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(chart, f, separators=(",", ":"))
    print("wrote", out_file, "keys:", key_count)


# Remove charts from the older all-9K naming.
for folder, _, _ in BASE_SONGS + SHAGGY_SONGS:
    stale = os.path.join(DATA, folder + "-9k")
    if os.path.isdir(stale):
        shutil.rmtree(stale)

for folder, chart_file, key_count in BASE_SONGS + SHAGGY_SONGS:
    make_chart(folder, chart_file, key_count)
