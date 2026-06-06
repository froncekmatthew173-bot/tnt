import MiniAudio.MAResMan;
import MiniAudio.MAGroup;
import flixel.FlxG;
import MiniAudio.MAEngine;
import MiniAudio.MASound;
import lime.media.vorbis.VorbisFile;
import cpp.RawPointer;
import flixel.FlxBasic;

class AudioStreamThing extends FlxBasic
{
	var sound:RawPointer<MASound>;

	public var volume(get, set):Float;
	public var time(get, set):Float;
	public var speed(get, set):Float;
	public var looping(get, set):Bool;
	public var playing(get, never):Bool;
	public var isDone(get, never):Bool;
	public var length(get, never):Float;
	// public var gamePaused:Bool = false;

	var _length:Float = -1;
	var _volume:Float = 1;

	var prevGlobalVol:Float = 1;

	static var engine:RawPointer<MAEngine>;
	static var group:RawPointer<MAGroup>;
	static var resourceManager:RawPointer<MAResMan>;

	static var addedSounds:Array<AudioStreamThing> = [];

	public override function new(filePath:String, grouped:Bool = false)
	{
		super();
		var loadedPath = filePath;

		if (resourceManager == null)
			resourceManager = MiniAudio.init_resource();

		if (engine == null)
			engine = MiniAudio.init(resourceManager);

		if (engine == null)
		{
			trace("CAN'T INITIALIZE AUDIO ENGINE");
			return;
		}

		if (grouped && group == null)
			createGroup();

		sound = MiniAudio.loadSound(engine, filePath, (grouped ? group : null));
		if (sound == null)
		{
			var lowerPath = filePath.toLowerCase();

			if (StringTools.endsWith(lowerPath, ".opus"))
			{
				var oggPath = filePath.substr(0, filePath.length - 5) + ".ogg";
				trace("CAN'T LOAD SOUND " + filePath + ", retrying as " + oggPath);
				sound = MiniAudio.loadSound(engine, oggPath, (grouped ? group : null));
				loadedPath = oggPath;
			}
			else if (StringTools.endsWith(lowerPath, ".ogg"))
			{
				var opusPath = filePath.substr(0, filePath.length - 4) + ".opus";
				trace("CAN'T LOAD SOUND " + filePath + ", retrying as " + opusPath);
				sound = MiniAudio.loadSound(engine, opusPath, (grouped ? group : null));
				loadedPath = opusPath;
			}

			if (sound == null)
			{
				trace("CAN'T LOAD SOUND " + filePath);
				return;
			}
		}

		if (StringTools.endsWith(loadedPath.toLowerCase(), ".ogg"))
		{
			var vorb = VorbisFile.fromFile(loadedPath);
			_length = vorb.timeTotal() * 1000;
			vorb.clear();
			vorb = null;
		}
		else
		{
			_length = cast(MiniAudio.getLength(sound) * 1000, Float);
		}
		MiniAudio.setTime(sound, 0);

		addedSounds.push(this);
	}

	public override function destroy()
	{
		if (sound != null)
		{
			MiniAudio.stopSound(sound);
			MiniAudio.destroySound(sound);
		}
		sound = null;
		addedSounds.remove(this);
		super.destroy();
	}

	static public function destroyEngine()
	{
		if (group != null)
			destroyGroup();
		if (engine != null)
			MiniAudio.uninit(engine);
		engine = null;
		if (resourceManager != null)
			MiniAudio.uninit_resource(resourceManager);
		resourceManager = null;
	}

	static public function destroyEverything()
	{
		if (addedSounds != null)
		{
			while (addedSounds.length > 0)
			{
				addedSounds[0].stop();
				addedSounds[0].destroy();
			}
		}
		addedSounds = [];
		destroyEngine();
	}

	public override function update(elapsed:Float):Void
	{
		if (sound != null && prevGlobalVol != FlxG.sound.volume)
			MiniAudio.setVolume(sound, _volume * FlxG.sound.volume);
		prevGlobalVol = FlxG.sound.volume;
		super.update(elapsed);
	}

	public function play()
	{
		if (sound != null && MiniAudio.startSound(sound) != 0)
			trace("CAN'T PLAY SOUND");
	}

	public function pause()
	{
		if (sound != null)
			MiniAudio.pauseSound(sound);
	}

	public function stop()
	{
		if (sound != null)
			MiniAudio.stopSound(sound);
	}

	public static function createGroup()
	{
		if (group != null)
			destroyGroup();
		group = MiniAudio.makeGroup(engine);
	}

	public static function destroyGroup()
	{
		if (group != null)
			MiniAudio.killGroup(group);
		else
			trace("NO GROUP TO DESTROY");
		group = null;
	}

	public static function playGroup()
	{
		if (group != null)
			MiniAudio.startGroup(group);
		else
			trace("NO GROUP TO PLAY");
	}

	public static function pauseGroup()
	{
		if (group != null)
			MiniAudio.haltGroup(group);
		else
			trace("NO GROUP TO PAUSE");
	}

	function get_playing():Bool
	{
		return sound != null && cast(MiniAudio.isPlaying(sound), Bool);
	}

	function get_isDone():Bool
	{
		return sound == null || cast(MiniAudio.isDone(sound), Bool);
	}

	function get_length():Float
	{
		return _length;
	}

	function get_volume():Float
	{
		return _volume;
	}

	function set_volume(newVol:Float):Float
	{
		_volume = newVol;
		if (sound != null)
			MiniAudio.setVolume(sound, _volume * FlxG.sound.volume);
		return newVol;
	}

	function get_time():Float
	{
		return sound == null ? 0 : cast(MiniAudio.getTime(sound) * 1000, Float);
	}

	function set_time(newTime:Float):Float
	{
		if (sound != null)
			MiniAudio.setTime(sound, newTime / 1000);
		return newTime;
	}

	function get_speed():Float
	{
		return sound == null ? 1 : cast(MiniAudio.getPitch(sound), Float);
	}

	function set_speed(newSpeed:Float):Float
	{
		if (sound != null)
			MiniAudio.setPitch(sound, newSpeed);
		return newSpeed;
	}

	function get_looping():Bool
	{
		return sound != null && cast(MiniAudio.getLooping(sound), Bool);
	}

	function set_looping(shouldLoop:Bool):Bool
	{
		if (sound != null)
			MiniAudio.setLooping(sound, shouldLoop);
		return shouldLoop;
	}
}
