package;

import flixel.FlxG;
import haxe.Json;

class EditorSaveData
{
	static function loadOverride(collectionName:String, key:String):Dynamic
	{
		if (FlxG.save.data == null)
			FlxG.save.bind("data");

		var collection:Dynamic = Reflect.field(FlxG.save.data, collectionName);
		if (collection == null)
			return null;

		var serialized:Dynamic = Reflect.field(collection, key);
		if (serialized == null)
			return null;

		try
		{
			return Json.parse(Std.string(serialized));
		}
		catch (error:haxe.Exception)
		{
			trace('Could not load editor override "$key": $error');
			return null;
		}
	}

	static function saveOverride(collectionName:String, key:String, value:Dynamic):Bool
	{
		if (FlxG.save.data == null)
			FlxG.save.bind("data");

		var collection:Dynamic = Reflect.field(FlxG.save.data, collectionName);
		if (collection == null)
		{
			collection = {};
			Reflect.setField(FlxG.save.data, collectionName, collection);
		}

		Reflect.setField(collection, key, Json.stringify(value, null, "  "));
		if (!FlxG.save.flush())
		{
			trace('Could not save editor override "$key"');
			return false;
		}
		return true;
	}

	public static function loadStage(name:String):Dynamic
	{
		var stage = loadOverride("stageEditorOverrides", name);
		if (name == "shaggy3d" && stage != null)
		{
			migrateStagePosition(stage, "dad", -220, 806, 350, 686);
			migrateStagePosition(stage, "gf", 400, 656, 800, 566);
		}
		return stage;
	}

	public static function saveStage(name:String, data:Dynamic):Bool
	{
		return saveOverride("stageEditorOverrides", name, data);
	}

	static function migrateStagePosition(stage:Dynamic, character:String, oldX:Float, oldY:Float, newX:Float, newY:Float):Void
	{
		var position:Dynamic = Reflect.field(stage, character);
		if (position == null || numberField(position, "x", oldX) != oldX || numberField(position, "y", oldY) != oldY)
			return;

		Reflect.setField(position, "x", newX);
		Reflect.setField(position, "y", newY);
	}

	public static function loadCharacter(name:String):Dynamic
	{
		return loadOverride("characterEditorOverrides", name);
	}

	public static function saveCharacter(name:String, data:Dynamic):Bool
	{
		return saveOverride("characterEditorOverrides", name, data);
	}

	public static function numberField(object:Dynamic, field:String, fallback:Float):Float
	{
		if (object == null)
			return fallback;

		var value:Dynamic = Reflect.field(object, field);
		if (value == null)
			return fallback;

		var parsed = Std.parseFloat(Std.string(value));
		if (Math.isNaN(parsed))
		{
			trace('Invalid editor value "$field"; using default');
			return fallback;
		}
		return parsed;
	}
}
