package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;

class StageEditorState extends MusicBeatState
{
	static final selections:Array<String> = ["background", "pyramids", "hills", "dad", "boyfriend", "gf", "cameraZoom"];
	var selected:Int = 0;
	var stageData:Dynamic;
	var layerSprites:Map<String, FlxSprite> = [];
	var layerBaseWidths:Map<String, Float> = [];
	var markers:Map<String, FlxSprite> = [];
	var statusText:FlxText;
	var saveMessage:String = "";

	override function create():Void
	{
		FlxG.mouse.visible = false;
		FlxG.camera.bgColor = FlxColor.BLACK;
		stageData = EditorSaveData.loadStage("shaggy3d");
		if (stageData == null)
			stageData = defaultStageData();

		FlxG.camera.zoom = EditorSaveData.numberField(stageData, "cameraZoom", 0.6);
		var focus = FlxPoint.get(FlxG.width / 2, FlxG.height / 2);
		FlxG.camera.focusOn(focus);
		focus.put();

		addLayer("background", "shaggy3d/background");
		addLayer("pyramids", "shaggy3d/pyramids");
		addLayer("hills", "shaggy3d/hills");
		addMarker("dad", FlxColor.RED);
		addMarker("boyfriend", FlxColor.LIME);
		addMarker("gf", FlxColor.CYAN);

		var help = new FlxText(12, 12, FlxG.width - 24,
			"SHAGGY 3D STAGE EDITOR\nTAB: select  WASD: move  Q/E: scale or zoom  SHIFT: larger step  ENTER: save  ESC: back", 16);
		help.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		help.scrollFactor.set();
		add(help);

		statusText = new FlxText(12, 80, FlxG.width - 24, "", 18);
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
			FlxG.switchState(new EditorsMenuState());
			return;
		}

		if (FlxG.keys.justPressed.TAB)
		{
			var direction = FlxG.keys.pressed.SHIFT ? -1 : 1;
			selected = (selected + direction + selections.length) % selections.length;
			updateEditorView();
		}

		var step = FlxG.keys.pressed.SHIFT ? 10.0 : 1.0;
		var item = selections[selected];
		if (item == "cameraZoom")
		{
			if (FlxG.keys.justPressed.Q)
				changeNumber(stageData, "cameraZoom", -0.01 * step);
			else if (FlxG.keys.justPressed.E)
				changeNumber(stageData, "cameraZoom", 0.01 * step);
			FlxG.camera.zoom = EditorSaveData.numberField(stageData, "cameraZoom", 0.6);
		}
		else if (FlxG.keys.justPressed.A)
			changeNumber(Reflect.field(stageData, item), "x", -step);
		else if (FlxG.keys.justPressed.D)
			changeNumber(Reflect.field(stageData, item), "x", step);
		else if (FlxG.keys.justPressed.W)
			changeNumber(Reflect.field(stageData, item), "y", -step);
		else if (FlxG.keys.justPressed.S)
			changeNumber(Reflect.field(stageData, item), "y", step);
		else if (FlxG.keys.justPressed.Q && layerSprites.exists(item))
			changeNumber(Reflect.field(stageData, item), "scale", -0.1 * step);
		else if (FlxG.keys.justPressed.E && layerSprites.exists(item))
			changeNumber(Reflect.field(stageData, item), "scale", 0.1 * step);

		if (FlxG.keys.justPressed.ENTER)
		{
			var saved = EditorSaveData.saveStage("shaggy3d", stageData);
			saveMessage = saved ? "Saved Shaggy 3D stage override." : "Save failed; see the log.";
		}

		updateEditorView();
		super.update(elapsed);
	}

	function addLayer(name:String, image:String):Void
	{
		var layerData:Dynamic = Reflect.field(stageData, name);
		var sprite = new FlxSprite(EditorSaveData.numberField(layerData, "x", 0), EditorSaveData.numberField(layerData, "y", 0));
		sprite.loadGraphic(Paths.getImagePNG(image));
		layerBaseWidths.set(name, sprite.width);
		sprite.antialiasing = false;
		sprite.active = false;
		sprite.cameras = [FlxG.camera];
		add(sprite);
		layerSprites.set(name, sprite);
	}

	function addMarker(name:String, color:FlxColor):Void
	{
		var marker = new FlxSprite().makeGraphic(24, 48, color);
		marker.scrollFactor.set();
		marker.cameras = [FlxG.camera];
		add(marker);
		markers.set(name, marker);
	}

	function updateEditorView():Void
	{
		for (name => sprite in layerSprites)
		{
			var layerData:Dynamic = Reflect.field(stageData, name);
			sprite.x = EditorSaveData.numberField(layerData, "x", 0);
			sprite.y = EditorSaveData.numberField(layerData, "y", 0);
			var scale = Math.max(0.1, EditorSaveData.numberField(layerData, "scale", 1));
			sprite.setGraphicSize(Std.int(layerBaseWidths.get(name) * scale));
			sprite.updateHitbox();
		}

		for (name => marker in markers)
		{
			var position:Dynamic = Reflect.field(stageData, name);
			marker.setPosition(EditorSaveData.numberField(position, "x", 0) - marker.width / 2,
				EditorSaveData.numberField(position, "y", 0) - marker.height);
		}

		var selectedName = selections[selected];
		var selectedData:Dynamic = Reflect.field(stageData, selectedName);
		var details = selectedName == "cameraZoom" ? 'zoom ${EditorSaveData.numberField(stageData, "cameraZoom", 0.6)}' :
			'x ${EditorSaveData.numberField(selectedData, "x", 0)}  y ${EditorSaveData.numberField(selectedData, "y", 0)}';
		if (layerSprites.exists(selectedName))
			details += '  scale ${EditorSaveData.numberField(selectedData, "scale", 1)}';
		statusText.text = 'Selected: $selectedName  $details\n$saveMessage';
	}

	function changeNumber(object:Dynamic, field:String, delta:Float):Void
	{
		var current = EditorSaveData.numberField(object, field, 0);
		Reflect.setField(object, field, current + delta);
	}

	static function defaultStageData():Dynamic
	{
		return Json.parse(Assets.getText(Paths.json("stages/shaggy3d")));
	}
}
