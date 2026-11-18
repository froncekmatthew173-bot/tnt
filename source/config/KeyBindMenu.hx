package config;

import PlayState;
import transition.data.*;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.text.FlxText;

using StringTools;

/**
 * Key re-bind menu extended for EK extra keys.
 *
 * Shows one entry per note lane (0 .. keyCount-1) and lets the user bind an
 * arbitrary key to each lane. Binds are stored via KeyConfig (per-lane note
 * binds) and, for the first four lanes, mirrored into the legacy
 * leftBind/downBind/upBind/rightBind save fields so menu controls stay in sync.
 */
class KeyBindMenu extends MusicBeatState
{

    var keyTextDisplay:FlxTextThing;
    var keyWarning:FlxTextThing;
    var warningTween:FlxTween;

    // Display label for each lane (LEFT/DOWN/UP/RIGHT then LANE N)
    var keyText:Array<String> = [];
    var defaultKeys:Array<String> = ["A", "S", "W", "D", "R"];
    var curSelected:Int = 0;

    // Raw key-name strings bound to each note lane (length = keyCount)
    var keys:Array<String> = [];

    var tempKey:String = "";
    var blacklist:Array<String> = ["ESCAPE", "ENTER", "BACKSPACE", "SPACE"];

    var state:String = "select";

    override function create()
    {
        keyCountRefresh();

        var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.getImageFunk('menuDesat'));
        bg.scrollFactor.x = 0;
        bg.scrollFactor.y = 0;
        bg.setGraphicSize(Std.int(bg.width * 1.18));
        bg.updateHitbox();
        bg.screenCenter();
        bg.antialiasing = true;
        bg.color = 0xFF9766BE;
        add(bg);

        keyTextDisplay = new FlxTextThing(0, 0, 1280, "", 72);
        keyTextDisplay.scrollFactor.set(0, 0);
        keyTextDisplay.setFormat(Paths.font("Funkin-Bold", "otf"), 72, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        keyTextDisplay.borderSize = 3;
        keyTextDisplay.borderQuality = 1;
        keyTextDisplay.antialiasing = true;
        add(keyTextDisplay);

        keyWarning = new FlxTextThing(0, 580, 1280, "WARNING: BIND NOT SET, TRY ANOTHER KEY", 42);
        keyWarning.scrollFactor.set(0, 0);
        keyWarning.setFormat(Paths.font("vcr"), 42, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        keyWarning.borderSize = 3;
        keyWarning.borderQuality = 1;
        keyWarning.screenCenter(X);
        keyWarning.alpha = 0;
        add(keyWarning);

        var backText = new FlxTextThing(5, FlxG.height - 37, 0, "ESCAPE/BACKSPACE - Back to Menu\nDELETE - Reset to Defaults\n", 16);
        backText.scrollFactor.set();
        backText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(backText);

        warningTween = FlxTween.tween(keyWarning, {alpha: 0}, 0);

        textUpdate();

        customTransIn = new WeirdBounceIn(0.6);
        customTransOut = new WeirdBounceOut(0.6);

        super.create();
    }

    /** Rebuild lane labels and current binds to match PlayState.keyCount. */
    public function keyCountRefresh():Void
    {
        var count:Int = PlayState.keyCount;
        keyText = [];
        keys = [];
        var arrows = ["LEFT", "DOWN", "UP", "RIGHT"];
        for (i in 0...count)
        {
            keyText.push(i < 4 ? arrows[i] : "LANE " + (i + 1));
            var names = KeyConfig.laneNames(i);
            keys.push(names.length > 0 ? names[0] : defaultKeys[i % defaultKeys.length]);
        }
    }

    override function update(elapsed:Float)
    {
        switch(state){

            case "select":
                if (controls.UP_P)
                {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    changeItem(-1);
                }

                if (controls.DOWN_P)
                {
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    changeItem(1);
                }

                if (FlxG.keys.justPressed.ENTER){
                    FlxG.sound.play(Paths.sound('scrollMenu'));
                    state = "input";
                }
                else if(FlxG.keys.justPressed.ESCAPE || FlxG.gamepads.anyJustPressed(ANY) || FlxG.keys.justPressed.BACKSPACE){
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                    quit();
                }
                else if (FlxG.keys.justPressed.DELETE){
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                    reset();
                }

            case "input":
                tempKey = keys[curSelected];
                keys[curSelected] = "?";
                textUpdate();
                state = "waiting";

            case "waiting":
                if(FlxG.keys.justPressed.ESCAPE){
                    keys[curSelected] = tempKey;
                    state = "select";
                    FlxG.sound.play(Paths.sound('cancelMenu'));
                }
                else if(FlxG.keys.justPressed.ENTER){
                    addKey(defaultKeys[curSelected % defaultKeys.length]);
                    save();
                    state = "select";
                }
                else if(FlxG.keys.justPressed.ANY){
                    addKey(FlxG.keys.getIsDown()[0].ID.toString());
                    save();
                    state = "select";
                }


            case "exiting":


            default:
                state = "select";

        }

        if(FlxG.keys.justPressed.ANY)
			textUpdate();

        super.update(elapsed);
		
    }

    function textUpdate():Void{

        keyTextDisplay.clearFormats();
        keyTextDisplay.text = "\n\n";

        for(i in 0...keys.length){

            var sectionStart = keyTextDisplay.text.length;
            var shown = KeyConfig.laneNames(i);
            var display = shown.length > 0 ? shown.join(" + ") : keys[i];
            if(i < 4)
                keyTextDisplay.text += keyText[i] + ": " + ((keys[i] != keyText[i]) ? (keys[i] + " + ") : "" ) + display + "\n";
            else
                keyTextDisplay.text += keyText[i] + ": " + display + "\n";
            var sectionEnd = keyTextDisplay.text.length - 1;

            if(i == curSelected){
                keyTextDisplay.addFormat(new FlxTextFormat(0xFFFFFF00), sectionStart, sectionEnd);
            }

        }

        keyTextDisplay.screenCenter();

    }

    function save():Void
    {
        // Per-lane note binds (EK extra keys)
        for (i in 0...keys.length)
            KeyConfig.setLane(i, [keys[i]]);

        // Mirror the first four lanes into the legacy bind fields so the
        // menu/in-game 4K controls (Controls.loadKeyBinds) stay in sync.
        if (keys.length > 0) FlxG.save.data.leftBind  = keys[0];
        if (keys.length > 1) FlxG.save.data.downBind  = keys[1];
        if (keys.length > 2) FlxG.save.data.upBind    = keys[2];
        if (keys.length > 3) FlxG.save.data.rightBind = keys[3];

        FlxG.save.flush();

        PlayerSettings.player1.controls.loadKeyBinds();
    }

    function reset():Void
    {
        KeyConfig.reset(PlayState.keyCount);
        keyCountRefresh();
        quit();
    }

    function quit():Void
    {
        state = "exiting";

        save();

        ConfigMenu.startSong = false;
        switchState(new ConfigMenu());
    }

    function addKey(r:String):Void
    {
        var shouldReturn:Bool = true;

        var notAllowed:Array<String> = [];

        for(x in keys){
            if(x != tempKey){notAllowed.push(x);}
        }

        for(x in blacklist){notAllowed.push(x);}

        // Don't clash with the direction-arrow names used by the 4K lanes
        var arrows:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];
        for(x in arrows){notAllowed.push(x);}

        for(x in notAllowed){if(x == r){shouldReturn = false;}}

        if(shouldReturn){
            keys[curSelected] = r;
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        else if(!shouldReturn && keys.contains(r)){
            keys[keys.indexOf(r)] = tempKey;
            keys[curSelected] = r;
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
        else{
            keys[curSelected] = tempKey;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            keyWarning.alpha = 1;
            warningTween.cancel();
            warningTween = FlxTween.tween(keyWarning, {alpha: 0}, 0.5, {ease: FlxEase.circOut, startDelay: 2});
        }

    }

    function changeItem(_amount:Int = 0)
    {
        curSelected += _amount;
                
        if (curSelected > keys.length - 1)
            curSelected = 0;
        if (curSelected < 0)
            curSelected = keys.length - 1;
    }
}
