package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class EditorsMenuState extends MusicBeatState
{
	static final options:Array<String> = ["Chart Editor", "Stage Editor", "Character Editor", "Mod Converter"];
	var selected:Int = 0;
	var optionTexts:Array<FlxText> = [];

	override function create():Void
	{
		FlxG.save.bind("data");
		FlxG.mouse.visible = false;
		add(new CrappyTile(Paths.getImagePNG("tile"), 50, 50));

		var title = new FlxText(0, 34, FlxG.width, "EDITORS", 48);
		title.setFormat(Paths.font("bungee"), 48, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set();
		add(title);

		for (i in 0...options.length)
		{
			var option = new FlxText(0, 150 + i * 90, FlxG.width, options[i], 36);
			option.setFormat(Paths.font("bungee"), 36, FlxColor.GRAY, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			option.scrollFactor.set();
			optionTexts.push(option);
			add(option);
		}

		var help = new FlxText(0, FlxG.height - 44, FlxG.width, "UP/DOWN SELECT  ENTER OPEN  ESC BACK", 18);
		help.setFormat(Paths.font("vcr"), 18, FlxColor.WHITE, FlxTextAlign.CENTER);
		help.scrollFactor.set();
		add(help);
		updateSelection();
		super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (controls.UP_P)
			changeSelection(-1);
		else if (controls.DOWN_P)
			changeSelection(1);

		if (controls.BACK)
			FlxG.switchState(new MainMenuState());
		else if (controls.ACCEPT)
		{
			Main.unmusic();
			switch (selected)
			{
				case 0:
					PlayState.SONG = Song.loadFromJson("shaggy3d", "shaggy3d");
					FlxG.switchState(new ChartingState());
				case 1:
					FlxG.switchState(new StageEditorState());
				case 2:
					FlxG.switchState(new CharacterEditorState());
				case 3:
					FlxG.switchState(new ModConverterState());
			}
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int):Void
	{
		selected = (selected + change + options.length) % options.length;
		FlxG.sound.play(Paths.sound("scrollMenu"));
		updateSelection();
	}

	function updateSelection():Void
	{
		for (i in 0...optionTexts.length)
			optionTexts[i].color = i == selected ? FlxColor.WHITE : FlxColor.GRAY;
	}
}
