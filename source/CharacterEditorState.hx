package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;

class CharacterEditorState extends MusicBeatState
{
	static final characterNames:Array<String> = ["shaggy", "shaggy3d", "pshaggy", "rshaggy", "sshaggy", "wbshaggy", "zshaggy", "spamton"];
	var selectedCharacter:Int = 0;
	var selectedAnimation:Int = 0;
	var characterData:Dynamic;
	var animations:Array<Dynamic> = [];
	var preview:Character;
	var statusText:FlxText;
	var saveMessage:String = "";

	override function create():Void
	{
		FlxG.mouse.visible = false;
		FlxG.camera.zoom = 1;
		loadCharacter();

		var help = new FlxText(12, 12, FlxG.width - 24,
			"CHARACTER EDITOR\nLEFT/RIGHT: character  UP/DOWN: animation  WASD: position  Q/E: scale  Z/X: camera X  R/F: camera Y  SHIFT+WASD: anim offset  ENTER: save  ESC: back",
			14);
		help.setFormat(Paths.font("vcr"), 14, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		help.scrollFactor.set();
		add(help);

		statusText = new FlxText(12, 120, FlxG.width - 24, "", 18);
		statusText.setFormat(Paths.font("vcr"), 18, FlxColor.YELLOW, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		statusText.scrollFactor.set();
		add(statusText);
		updateEditorView();
		super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (controls.BACK)
		{
			destroyPreview();
			FlxG.switchState(new EditorsMenuState());
			return;
		}

		if (FlxG.keys.justPressed.LEFT)
		{
			selectedCharacter = (selectedCharacter + characterNames.length - 1) % characterNames.length;
			loadCharacter();
		}
		else if (FlxG.keys.justPressed.RIGHT)
		{
			selectedCharacter = (selectedCharacter + 1) % characterNames.length;
			loadCharacter();
		}

		if (animations.length > 0 && FlxG.keys.justPressed.UP)
		{
			selectedAnimation = (selectedAnimation + animations.length - 1) % animations.length;
			playSelectedAnimation();
		}
		else if (animations.length > 0 && FlxG.keys.justPressed.DOWN)
		{
			selectedAnimation = (selectedAnimation + 1) % animations.length;
			playSelectedAnimation();
		}

		var step = FlxG.keys.pressed.SHIFT ? 10.0 : 1.0;
		if (FlxG.keys.justPressed.A)
			adjustValue(FlxG.keys.pressed.SHIFT ? "animationOffsetX" : "positionX", -step);
		else if (FlxG.keys.justPressed.D)
			adjustValue(FlxG.keys.pressed.SHIFT ? "animationOffsetX" : "positionX", step);
		else if (FlxG.keys.justPressed.W)
			adjustValue(FlxG.keys.pressed.SHIFT ? "animationOffsetY" : "positionY", -step);
		else if (FlxG.keys.justPressed.S)
			adjustValue(FlxG.keys.pressed.SHIFT ? "animationOffsetY" : "positionY", step);
		else if (FlxG.keys.justPressed.Q)
			adjustValue("scale", -0.05);
		else if (FlxG.keys.justPressed.E)
			adjustValue("scale", 0.05);
		else if (FlxG.keys.justPressed.Z)
			adjustValue("cameraX", -step);
		else if (FlxG.keys.justPressed.X)
			adjustValue("cameraX", step);
		else if (FlxG.keys.justPressed.R)
			adjustValue("cameraY", -step);
		else if (FlxG.keys.justPressed.F)
			adjustValue("cameraY", step);

		if (FlxG.keys.justPressed.ENTER)
		{
			var saved = EditorSaveData.saveCharacter(characterNames[selectedCharacter], characterData);
			saveMessage = saved ? 'Saved ${characterNames[selectedCharacter]} character override.' : "Save failed; see the log.";
		}

		updateEditorView();
		super.update(elapsed);
	}

	function loadCharacter():Void
	{
		destroyPreview();
		var name = characterNames[selectedCharacter];
		characterData = EditorSaveData.loadCharacter(name);
		if (characterData == null)
			characterData = Json.parse(Assets.getText(Paths.json("shaggy/characters/" + name)));

		var rawAnimations:Dynamic = Reflect.field(characterData, "animations");
		animations = rawAnimations == null ? [] : cast rawAnimations;
		selectedAnimation = 0;
		preview = new Character(0, 0, name, false);
		preview.scrollFactor.set();
		preview.cameras = [FlxG.camera];
		add(preview);
		playSelectedAnimation();
	}

	function playSelectedAnimation():Void
	{
		if (preview == null || animations.length == 0)
			return;
		var animationData = animations[selectedAnimation];
		var animationName = Std.string(Reflect.field(animationData, "anim"));
		if (preview.animExists(animationName))
			preview.playAnim(animationName, true);
	}

	function adjustValue(field:String, delta:Float):Void
	{
		switch (field)
		{
			case "positionX":
				changeArrayValue(characterData, "position", 0, delta);
			case "positionY":
				changeArrayValue(characterData, "position", 1, delta);
			case "cameraX":
				changeArrayValue(characterData, "camera_position", 0, delta);
			case "cameraY":
				changeArrayValue(characterData, "camera_position", 1, delta);
			case "scale":
				var scale = Math.max(0.1, EditorSaveData.numberField(characterData, "scale", 1) + delta);
				Reflect.setField(characterData, "scale", scale);
				if (preview != null)
				{
					preview.scale.set(scale, scale);
					preview.updateHitbox();
				}
			case "animationOffsetX" | "animationOffsetY":
				if (animations.length == 0)
					return;
				var animationData = animations[selectedAnimation];
				var offsets:Dynamic = Reflect.field(animationData, "offsets");
				if (offsets == null || offsets.length < 2)
				{
					offsets = [0, 0];
					Reflect.setField(animationData, "offsets", offsets);
				}
				var index = field == "animationOffsetX" ? 0 : 1;
				offsets[index] = Std.parseFloat(Std.string(offsets[index])) + delta;
				var animationName = Std.string(Reflect.field(animationData, "anim"));
				if (preview != null)
				{
					preview.addOffset(animationName, offsets[0], offsets[1]);
					preview.playAnim(animationName, true);
				}
		}
	}

	function changeArrayValue(object:Dynamic, field:String, index:Int, delta:Float):Void
	{
		var values:Dynamic = Reflect.field(object, field);
		if (values == null || values.length < 2)
		{
			values = [0, 0];
			Reflect.setField(object, field, values);
		}
		values[index] = Std.parseFloat(Std.string(values[index])) + delta;
	}

	function updateEditorView():Void
	{
		if (preview != null)
		{
			var position:Dynamic = Reflect.field(characterData, "position");
			preview.x = FlxG.width / 2 - preview.width / 2 + readArrayValue(position, 0);
			preview.y = FlxG.height / 2 - preview.height + readArrayValue(position, 1);
		}

		var animationName = animations.length > 0 ? Std.string(Reflect.field(animations[selectedAnimation], "anim")) : "(none)";
		statusText.text = '${characterNames[selectedCharacter]}  animation: $animationName  scale: ${EditorSaveData.numberField(characterData, "scale", 1)}\n$saveMessage';
	}

	function readArrayValue(values:Dynamic, index:Int):Float
	{
		if (values == null || values.length <= index)
			return 0;
		var value = Std.parseFloat(Std.string(values[index]));
		return Math.isNaN(value) ? 0 : value;
	}

	function destroyPreview():Void
	{
		if (preview != null)
		{
			remove(preview, true);
			preview.destroy();
			preview = null;
		}
	}
}
