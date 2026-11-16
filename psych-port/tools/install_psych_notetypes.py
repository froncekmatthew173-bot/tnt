#!/usr/bin/env python3
"""Install basic Psych Lua behavior for FPS Plus numbered note types."""

from __future__ import annotations

import shutil
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MOD = ROOT / "psych-engine-1.0.4" / "mods" / "TNT"
SOUND_NAMES = {1: "mine", 2: "gunshot", 3: "heal", 4: "mine", 5: "freeze", 6: "paper"}
TEXTURES = {1: "minenote", 2: "warningnote", 3: "healnote", 4: "fakehealnote", 5: "icenote", 6: "scribblenote"}


TEMPLATE = r'''local noteType = "FPSPlus-{number}"
local texture = "notes/{texture}.png"
local sound = "{sound}"

function onCreatePost()
    for i = 0, getProperty("unspawnNotes.length") - 1 do
        if getPropertyFromGroup("unspawnNotes", i, "noteType") == noteType then
            setPropertyFromGroup("unspawnNotes", i, "texture", texture)
            if {ignore_miss} then
                setPropertyFromGroup("unspawnNotes", i, "ignoreNote", true)
                setPropertyFromGroup("unspawnNotes", i, "missHealth", 0)
            end
        end
    end
end

function noteMiss(id, direction, noteTypeHit, isSustainNote)
    if noteTypeHit ~= noteType or isSustainNote then return end
    if {number} == 2 then
        setProperty("health", getProperty("health") - 0.35)
    end
end

function goodNoteHit(id, direction, noteTypeHit, isSustainNote)
    if noteTypeHit ~= noteType or isSustainNote then return end
    if {number} == 1 or {number} == 4 then
        setProperty("health", getProperty("health") - 0.24)
        setProperty("songMisses", getProperty("songMisses") + 1)
        setProperty("songScore", getProperty("songScore") - 350)
        setProperty("combo", 0)
        playSound(sound, 1)
    elseif {number} == 3 then
        setProperty("health", math.min(2, getProperty("health") + 0.33))
        playSound(sound, 1)
    elseif {number} == 5 then
        setProperty("health", getProperty("health") - 0.023)
        setProperty("songMisses", getProperty("songMisses") + 1)
        setProperty("songScore", getProperty("songScore") - 350)
        setProperty("combo", 0)
        playSound(sound, 1)
        for i = 0, 3 do setPropertyFromGroup("playerStrums", i, "alpha", 0.35) end
        runTimer("fpsplus-freeze", 2)
    elseif {number} == 6 then
        setProperty("health", getProperty("health") - 0.023)
        setProperty("songMisses", getProperty("songMisses") + 1)
        setProperty("songScore", getProperty("songScore") - 350)
        setProperty("combo", 0)
        playSound(sound, 0.6)
        cameraFlash("camGame", "FFFFFF", 0.2, true)
    end
end

function onTimerCompleted(tag)
    if tag == "fpsplus-freeze" then
        for i = 0, 3 do setPropertyFromGroup("playerStrums", i, "alpha", 1) end
    end
end
'''


def main() -> int:
    note_dir = MOD / "custom_notetypes"
    note_dir.mkdir(parents=True, exist_ok=True)
    sound_dir = MOD / "sounds"
    sound_dir.mkdir(parents=True, exist_ok=True)
    for number, sound in SOUND_NAMES.items():
        (note_dir / f"FPSPlus-{number}.lua").write_text(
            TEMPLATE.format(
                number=number,
                texture=TEXTURES[number],
                sound=sound,
                ignore_miss="true" if number != 2 else "false",
            ),
            encoding="utf-8",
        )
        source_sound = ROOT / "assets" / "sounds" / f"{sound}.ogg"
        if source_sound.exists():
            shutil.copy2(source_sound, sound_dir / source_sound.name)
    print("Installed six FPS Plus note type scripts and available note effect sounds.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
