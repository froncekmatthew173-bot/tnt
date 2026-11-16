package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Int;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	@:optional var player3:String;
	var stage:String;
	var gf:String;
	var validScore:Bool;
	var vocalVolume:Null<Float>;
	var songVolume:Null<Float>;
	@:optional var audioFolder:String;
	@:optional var chartFolder:String;
	@:optional var mania:Int;
	@:optional var sourceMania:Int;
	@:optional var sourceChart:String;
	@:optional var soundfont1:String;
	@:optional var soundfont2:String;
	@:optional var events:Array<Dynamic>;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	@:optional public var player3:String = null;
	public var stage:String = '';
	public var gf:String = 'gf';
	public var vocalVolume:Float = 1.0;
	public var songVolume:Float = 1.0;
	public var audioFolder:String = null;
	public var mania:Int = 0;
	public var sourceMania:Int = 0;
	public var sourceChart:String = null;
	public var soundfont1:String = null;
	public var soundfont2:String = null;
	public var events:Array<Dynamic> = null;

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = Assets.getText(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		var song = parseJSONshit(rawJson);
		song.chartFolder = folder.toLowerCase();
		return song;
	}

	public static function parseJSONshit(rawJson:String, ?addNoteDefaults:Bool = true):SwagSong
	{
		var parsed:Dynamic = Json.parse(rawJson);
		
		// Check if this is a codename engine chart format (has 'events' key)
		if (parsed.events != null)
		{
			// Codename engine chart - return song object with defaults
			var songName:String = parsed.song != null ? parsed.song : 'unknown';
			return {
				song: songName,
				notes: [], // codename engine uses events, not traditional notes
				bpm: parsed.bpm ?? 223,
				needsVoices: true,
				speed: parsed.speed ?? 1.0,
				player1: 'bf',
				player2: 'bf',
				stage: '',
				gf: 'gf',
				validScore: true,
				vocalVolume: 1.0,
				songVolume: 1.0,
				chartFolder: parsed.song != null ? parsed.song.toLowerCase() : 'places',
				mania: parsed.mania ?? 4,
				soundfont1: null,
				soundfont2: null,
				events: parsed.events
			};
		}
		
		// Try loading events from a separate events.json file in the chart folder
		var eventsFilePath:String = null;
		// Determine the song name for the events file path
		var songNameForPath:String = parsed.song != null ? parsed.song.toLowerCase() : '';
		if (songNameForPath.length == 0) return null;
		try 
		{
			eventsFilePath = "assets/data/" + songNameForPath + "/events.json";
			var eventsRaw: String = Assets.getText(Paths.json(eventsFilePath)).trim();
			if (eventsRaw.length > 2 && !eventsRaw.endsWith("}"))
			{
				// Clean up the JSON
				while (!eventsRaw.endsWith("}"))
					eventsRaw = eventsRaw.substr(0, eventsRaw.length - 1);
			}
			if (eventsRaw.length > 0 && eventsRaw != "{}")
			{
				var eventsParsed:Dynamic = Json.parse(eventsRaw);
				if (eventsParsed.events != null)
				{
					return {
						song: songNameForPath,
						notes: parsed.notes, // Keep original notes
						bpm: parsed.bpm ?? 223,
						needsVoices: true,
						speed: parsed.speed ?? 1.0,
						player1: parsed.player1 != null ? parsed.player1 : 'bf',
						player2: parsed.player2 != null ? parsed.player2 : 'dad',
						stage: parsed.stage ?? '',
						gf: parsed.gf ?? 'gf',
						validScore: true,
						vocalVolume: 1.0,
						songVolume: 1.0,
						chartFolder: '',
						mania: parsed.mania ?? 4,
						soundfont1: parsed.soundfont1 ?? null,
						soundfont2: parsed.soundfont2 ?? null,
						events: eventsParsed.events
					};
				}
			}
		}
		catch(e) 
		{
			// events.json not found or invalid - continue with original JSON events
		}
		
		// Original SwagSong format
		var swagShit:SwagSong = cast parsed.song;
		for (section in swagShit.notes)
		{
			for (note in section.sectionNotes)
			{
				if (addNoteDefaults && note.length > 1 && note[1] < 8)
				{
					if (note[3] == null)
						note[3] = 60;
					if (note[4] == null)
						note[4] = 0;
					if (note[5] == null)
						note[5] = 1.0;
				}
			}
		}
		swagShit.validScore = true;
		return swagShit;
	}
}
