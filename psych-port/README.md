# TNT and Shaggy source port work

The source project is FPS Plus, based on FNF 0.2.7 with custom HaxeFlixel code. The selected target is the official Psych Engine 1.0.4 source checkout in `psych-engine-1.0.4/`. This work imports chart and asset content and adds a Shaggy campaign; it is not yet a complete port of every FPS Plus engine feature.

## Generated content

- `psych-engine-1.0.4/mods/TNT/` is the Psych mod output. It contains converted TNT charts, imported PNG/XML assets, 28 TNT instrumental OGGs, and five Shaggy story weeks. Shaggy song IDs use the `shaggy-` prefix to keep their charts and tracks separate from TNT songs with matching names.
- `psych-port/tools/convert_charts.py` translates FPS Plus's explicit eight-lane ownership into Psych's four lanes and section ownership, while preserving original note arrays and effect notes in `fpsplus-*.json` sidecars.
- `psych-port/tools/import_shaggy.py` imports the cloned Shaggy assets/charts into the Psych mod. The original source charts remain in `psych-port/imports/the-shaggy-mod/` under the Apache 2.0 license.
- `psych-port/tools/import_shaggy_fpsplus.py` installs the Shaggy campaign assets and four-key charts into FPS Plus under `assets/data/shaggy-*`. The source charts only contain note timing and lanes, so this importer maps the four lanes to MIDI pitches 60, 62, 65, and 67 at preset 0 for SF2 vocal rendering. It uses each opponent's matching SF2, maps `sshaggy` to `shaggy.sf2`, and maps Thunderstorm to `rshaggy-thunderstorm.sf2`.
- `psych-port/tools/import_song_sfx.py` converts `*_sfx.opus` assets, including Eruption and Astral-Calamity effects, to separate OGG sound assets for both targets.
- `psych-port/tools/install_psych_notetypes.py` installs Lua note-type handlers for the six FPS Plus numbered types, with their textures and sound effects. Freeze input handling and the original scribble overlay are approximated.
- `psych-port/tools/restore_fpsplus_charts.py` reconstructs the original FPS Plus chart files from the sidecars created before the Shaggy import.

## Remaining source port work

Psych Engine still runs its stock four-key gameplay. The imported Shaggy charts are folded to four keys and the original mania charts are kept under `mods/TNT/data/shaggy-source/`; Shaggy's 6/7/9-key gameplay and song-specific mechanics are not implemented in Psych. The FPS Plus chart editor, soundfont chart editor, custom stage logic, menus/settings, particle effects, `.funk` atlas support, full story/dialogue flow, and non-playable effect-event runtime have not been ported into Psych's Haxe source. Song effect assets are imported separately; their event timing/playback is not wired up yet.
