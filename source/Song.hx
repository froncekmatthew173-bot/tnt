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
	var stage:String;
	var gf:String;
	var validScore:Bool;
	var vocalVolume:Null<Float>;
	var songVolume:Null<Float>;
	@:optional var arrowSkin:Null<String>;
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
	public var stage:String = '';
	public var gf:String = 'gf';
	public var vocalVolume:Float = 1.0;

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

		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var root:Dynamic = Json.parse(rawJson);
		var songData:Dynamic = root != null && Reflect.hasField(root, "song") ? root.song : root;

		// Some community charts omit `validScore` entirely.
		if (!Reflect.hasField(songData, "validScore"))
			songData.validScore = true;

		// Haxe typedef casting can throw hard errors when required fields are missing.
		// Ensure defaults for known required fields.
		if (!Reflect.hasField(songData, "notes"))
			songData.notes = [];
		if (!Reflect.hasField(songData, "bpm"))
			songData.bpm = 0;
		if (!Reflect.hasField(songData, "needsVoices"))
			songData.needsVoices = true;
		if (!Reflect.hasField(songData, "speed"))
			songData.speed = 1;
		if (!Reflect.hasField(songData, "player1"))
			songData.player1 = 'bf';
		if (!Reflect.hasField(songData, "player2"))
			songData.player2 = 'dad';
		if (!Reflect.hasField(songData, "stage"))
			songData.stage = '';
		if (!Reflect.hasField(songData, "gf"))
			songData.gf = 'gf';

		return cast songData;
	}

}
