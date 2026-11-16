package;

import sys.FileSystem;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	public var defualtIconScale:Float = 1.0;
	public var iconScale:Float = 1.0;
	public var iconSize:Float = 128;

	var char:String;
	public var status:String = "normal";

	private var tween:FlxTween;

	private static final pixelIcons:Array<String> = ["bf-pixel", "senpai", "senpai-angry", "spirit", "shaggy-3d", "bf-places", "bloxbi"];

	public function new(char:String = 'face', isPlayer:Bool = false, ?_id:Int = -1)
	{
		super();
		flipX = isPlayer;

		changeChar(char);
		if (isShaggyIcon(this.char))
			defualtIconScale = 1.2;
		if (this.char == "bf-places")
			defualtIconScale = 1.5;
		if (this.char == "bloxbi")
			defualtIconScale = 1.5;

		normal();

		antialiasing = !pixelIcons.contains(char);
		scrollFactor.set();

		tween = FlxTween.tween(this, {}, 0);
	}

	private static function isShaggyIcon(char:String):Bool
	{
		return switch (char)
		{
			case 'shaggy' | 'sshaggy' | 'pshaggy' | 'wbshaggy' | 'rshaggy' | 'zshaggy' | 'shaggy-3d': true;
			default: false;
		}
	}

	public function changeChar(char:String)
	{
		if (FileSystem.exists("assets/images/healthicons/" + char + ".png"))
			this.char = char;
		else if (FileSystem.exists("assets/images/healthicons/" + char))
			this.char = char;
		else
			this.char = "face";
	}

	public function normal()
	{
		if (FileSystem.exists("assets/images/healthicons/" + char + ".png"))
		{
			loadGraphic(Paths.image("healthicons/" + char), true, 150, 150);
			animation.add("normal", [0]);
			animation.add("lose", [1]);
			animation.play("normal");
		}
		else if (FileSystem.exists("assets/images/healthicons/" + char + "/normal.png"))
			loadGraphic(Paths.image("healthicons/" + char + "/normal"));
		status = "normal";
	}

	public function win()
	{
		if (FileSystem.exists("assets/images/healthicons/" + char + ".png"))
			animation.play("normal");
		else if (FileSystem.exists("assets/images/healthicons/" + char + "/win.png"))
			loadGraphic(Paths.image("healthicons/" + char + "/win"));
		status = "win";
	}

	public function lose()
	{
		if (FileSystem.exists("assets/images/healthicons/" + char + ".png"))
			animation.play("lose");
		else if (FileSystem.exists("assets/images/healthicons/" + char + "/lose.png"))
			loadGraphic(Paths.image("healthicons/" + char + "/lose"));
		status = "lose";
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		setGraphicSize(Std.int(iconSize * iconScale));
		updateHitbox();
	}

	public function tweenToDefaultScale(_time:Float, _ease:Null<flixel.tweens.EaseFunction>)
	{
		tween.cancel();
		tween = FlxTween.tween(this, {iconScale: this.defualtIconScale}, _time, {ease: _ease});
	}

	override public function destroy()
	{
		tween = FlxDestroyUtil.destroy(tween);
		super.destroy();
	}
}
