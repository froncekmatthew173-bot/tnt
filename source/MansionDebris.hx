package;

import flixel.FlxSprite;

class MansionDebris extends FlxSprite
{
	var startX:Float;
	var startY:Float;
	var scroll:Float;
	var timeFactor:Float;
	var timeDelay:Float;
	var positionFactor:Float;
	var time:Float = 0;
	var gravity:Float = 0.15;
	var verticalSpeed:Float = -20;

	public function new(startX:Float, startY:Float, debrisName:String, scroll:Float, timeFactor:Float, timeDelay:Float, positionFactor:Float)
	{
		super(startX, startY);
		this.startX = startX;
		this.startY = startY;
		this.scroll = scroll;
		this.timeFactor = timeFactor;
		this.timeDelay = timeDelay;
		this.positionFactor = positionFactor;

		frames = Paths.getSparrowAtlasPNG("mansion/god_bg");
		animation.addByPrefix("debris", "deb_" + debrisName, 30);
		animation.play("debris");
		scrollFactor.set(scroll, scroll);
		antialiasing = true;
		setGraphicSize(Std.int(frameWidth * (scroll / 0.75)));
		updateHitbox();
	}

	override function update(elapsed:Float):Void
	{
		time += elapsed * 60;
		if (timeDelay == -4)
		{
			var horizontalSpeed = positionFactor;
			verticalSpeed += gravity;
			x += horizontalSpeed;
			y += verticalSpeed;
			angle -= horizontalSpeed / 2;
		}
		else
		{
			x = startX;
			y = startY + Math.sin((time + timeDelay) / 50 * timeFactor) * 50 * positionFactor;
		}

		super.update(elapsed);
	}
}
