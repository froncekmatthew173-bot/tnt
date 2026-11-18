package config;

import InputFormatter;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

/**
 * Configurable per-lane key binds.
 *
 * Port of the FunkinExtraKeys (EK) key-binds system:
 * each note lane is bound to an array of keys, stored in the save file, so
 * songs with more than 4 keys (5K, 6K, 7K, ...) can use arbitrary keys
 * instead of hardcoded ones.
 */
class KeyConfig
{
	// noteKeyBinds[lane] = array of keys that trigger that lane
	public static var noteKeyBinds:Array<Array<FlxKey>> = [];

	// Standard direction arrow names for the four 4K lanes
	public static var laneArrows:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];

	/**
	 * (Re)configure the lane key binds for a given key count.
	 * Loads user binds from the save file when available, falling back to
	 * the defaults for that key count.
	 */
	public static function setup(count:Int):Void
	{
		var saved = cast FlxG.save.data.noteKeyBinds;
		var defaults = defaultBindsFor(count);
		var binds:Array<Array<FlxKey>> = [];

		for (i in 0...count)
		{
			var laneNames:Array<String>;
			if (saved != null && i < saved.length && cast saved[i] != null)
				laneNames = cast saved[i];
			else
				laneNames = defaults[i];

			var arr:Array<FlxKey> = [];
			for (name in laneNames)
				arr.push(FlxKey.fromString(Std.string(name)));
			binds.push(arr);
		}

		noteKeyBinds = binds;
	}

	/** Default key names per lane for a given key count. */
	public static function defaultBindsFor(count:Int):Array<Array<String>>
	{
		return switch (count)
		{
			case 4:
				[
					["LEFT",  FlxG.save.data.leftBind  ?? "A"],
					["DOWN",  FlxG.save.data.downBind  ?? "S"],
					["UP",    FlxG.save.data.upBind    ?? "W"],
					["RIGHT", FlxG.save.data.rightBind ?? "D"]
				];
			case 5: [["D"], ["F"], ["SPACE"], ["J"], ["K"]];
			case 6: [["S"], ["D"], ["F"], ["J"], ["K"], ["L"]];
			default:
				var base = ["LEFT", "DOWN", "UP", "RIGHT"];
				var arr:Array<Array<String>> = [];
				for (i in 0...count) arr.push([base[i % 4]]);
				arr;
		}
	}

	/** Returns the lane index whose binds contain the given key name, or -1. */
	public static function findLane(keyName:String):Int
	{
		for (i in 0...noteKeyBinds.length)
			for (key in noteKeyBinds[i])
				if (Std.string(key) == keyName)
					return i;
		return -1;
	}

	/** True if any key bound to the lane is currently pressed. */
	public static function lanePressed(lane:Int):Bool
	{
		if (lane < 0 || lane >= noteKeyBinds.length)
			return false;
		return FlxG.keys.anyPressed(noteKeyBinds[lane]);
	}

	/** True if any key bound to the lane was just pressed. */
	public static function laneJustPressed(lane:Int):Bool
	{
		if (lane < 0 || lane >= noteKeyBinds.length)
			return false;
		return FlxG.keys.anyJustPressed(noteKeyBinds[lane]);
	}

	/** True if any key bound to the lane was just released. */
	public static function laneJustReleased(lane:Int):Bool
	{
		if (lane < 0 || lane >= noteKeyBinds.length)
			return false;
		return FlxG.keys.anyJustReleased(noteKeyBinds[lane]);
	}

	/** Get the display names for a lane's bound keys. */
	public static function laneNames(lane:Int):Array<String>
	{
		if (lane < 0 || lane >= noteKeyBinds.length)
			return [];
		var out:Array<String> = [];
		for (key in noteKeyBinds[lane])
			out.push(InputFormatter.getKeyName(key));
		return out;
	}

	/** Set a lane's binds from key-name strings and save. */
	public static function setLane(lane:Int, keys:Array<String>):Void
	{
		while (noteKeyBinds.length <= lane)
			noteKeyBinds.push([]);
		var arr:Array<FlxKey> = [];
		for (name in keys)
			arr.push(FlxKey.fromString(name));
		noteKeyBinds[lane] = arr;
		save();
	}

	/** Reset all lanes to defaults for the given count and save. */
	public static function reset(count:Int):Void
	{
		setup(count);
		save();
	}

	public static function save():Void
	{
		var out:Array<Array<String>> = [];
		for (lane in noteKeyBinds)
		{
			var names:Array<String> = [];
			for (key in lane)
				names.push(Std.string(key));
			out.push(names);
		}
		FlxG.save.data.noteKeyBinds = out;
		FlxG.save.flush();
	}

	/** The number of configured lanes. */
	public static inline function laneCount():Int
	{
		return noteKeyBinds.length;
	}
}
