package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import sys.thread.Mutex;
import sys.thread.Thread;
import cpp.Int16;
import cpp.Pointer;
import Song.SwagSong;

using StringTools;

class ModConverterState extends MusicBeatState
{
	static final targets:Array<String> = ["Psych Engine", "Codename Engine", "Both"];
	static final targetFolders:Array<String> = ["PsychEngine", "CodenameEngine"];

	var selectedTarget:Int = 2;
	var targetText:FlxText;
	var statusText:FlxText;
	var running:Bool = false;
	var statusLock:Mutex = new Mutex();
	var statusMessage:String = "Choose an export target and press ENTER to generate SF2 vocals as OGG.";

	override function create():Void
	{
		FlxG.mouse.visible = false;
		add(new CrappyTile(Paths.getImagePNG("tile"), 50, 50));

		var title = new FlxText(0, 40, FlxG.width, "MOD CONVERTER", 44);
		title.setFormat(Paths.font("bungee"), 44, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		title.scrollFactor.set();
		add(title);

		targetText = new FlxText(0, 190, FlxG.width, "", 30);
		targetText.setFormat(Paths.font("bungee"), 30, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		targetText.scrollFactor.set();
		add(targetText);

		statusText = new FlxText(80, 310, FlxG.width - 160, "", 20);
		statusText.setFormat(Paths.font("vcr"), 20, FlxColor.YELLOW, FlxTextAlign.CENTER);
		statusText.scrollFactor.set();
		add(statusText);

		var help = new FlxText(0, FlxG.height - 70, FlxG.width,
			"LEFT/RIGHT: TARGET  ENTER: GENERATE SF2 OGG VOCALS  ESC: BACK\nRequires FFmpeg on PATH. Output: exported-mods/<engine>/songs/<song>/", 16);
		help.setFormat(Paths.font("vcr"), 16, FlxColor.WHITE, FlxTextAlign.CENTER);
		help.scrollFactor.set();
		add(help);

		updateLabels();
		super.create();
	}

	override function update(elapsed:Float):Void
	{
		if (!running)
		{
			if (controls.BACK)
			{
				FlxG.switchState(new EditorsMenuState());
				return;
			}
			else if (controls.LEFT_P)
				changeTarget(-1);
			else if (controls.RIGHT_P)
				changeTarget(1);
			else if (controls.ACCEPT)
				startExport();
		}

		updateLabels();
		super.update(elapsed);
	}

	function changeTarget(change:Int):Void
	{
		selectedTarget = (selectedTarget + change + targets.length) % targets.length;
		FlxG.sound.play(Paths.sound("scrollMenu"));
		updateLabels();
	}

	function updateLabels():Void
	{
		targetText.text = '< ${targets[selectedTarget]} >';
		statusLock.acquire();
		statusText.text = statusMessage;
		statusLock.release();
	}

	function startExport():Void
	{
		var charts:Array<{song:SwagSong, chartName:String}> = [];
		try
		{
			collectDefaultCharts("assets/data", charts);
		}
		catch (error:Dynamic)
		{
			setStatus('Could not scan assets/data: $error');
			return;
		}

		if (charts.length == 0)
		{
			setStatus("No default song charts were found in assets/data.");
			return;
		}

		var outputTargets = selectedTarget == 2 ? targetFolders.copy() : [targetFolders[selectedTarget]];
		running = true;
		setStatus('Generating 0/${charts.length} vocals. Output: exported-mods/${outputTargets.join(", exported-mods/")}');

		Thread.create(() ->
		{
			var previousSong = PlayState.SONG;
			var completed = 0;
			var errors:Array<String> = [];
			try
			{
				for (chart in charts)
				{
					try
					{
						PlayState.SONG = chart.song;
						var songLength = getSongLength(chart.song);
						var vocalBytes = SoundFontThing.songToBytes(chart.song, songLength);
						var mixed:Array<Int16> = [];
						var dad:Array<Int16> = vocalBytes[0];
						var boyfriend:Array<Int16> = vocalBytes[1];
						var sampleCount = Std.int(Math.min(dad.length, boyfriend.length));
						mixed.resize(sampleCount);
						for (i in 0...sampleCount)
							mixed[i] = cast Std.int((dad[i] + boyfriend[i]) / 2);

						Pointer.ofArray(dad).destroyArray();
						Pointer.ofArray(boyfriend).destroyArray();
						var wav = SoundFontThing.rawPCMtoWAV(mixed);
						mixed = null;

						try
						{
							for (target in outputTargets)
							{
								var audioName = getAudioName(chart.song);
								var outputFolder = Path.join(["exported-mods", target, "songs", audioName]);
								createDirectoryRecursive(outputFolder);
								var wavPath = createTempWavPath(chart.chartName, target);
								var oggPath = Path.join([outputFolder, audioName + "-Voices.ogg"]);
								try
								{
									File.saveBytes(wavPath, wav);
									encodeOgg(wavPath, oggPath);
								}
								catch (error:Dynamic)
								{
									if (FileSystem.exists(wavPath))
										FileSystem.deleteFile(wavPath);
									throw error;
								}
								if (FileSystem.exists(wavPath))
									FileSystem.deleteFile(wavPath);
							}
						}
						catch (error:Dynamic)
						{
							wav.destroy();
							throw error;
						}

						wav.destroy();
						completed++;
						setStatus('Generating $completed/${charts.length}: ${chart.song.song}');
					}
					catch (error:Dynamic)
					{
						errors.push('${chart.chartName}: $error');
						setStatus('Generating $completed/${charts.length}; failed ${chart.chartName}');
					}
				}
			}
			catch (error:Dynamic)
			{
				errors.push('Export stopped: $error');
			}
			PlayState.SONG = previousSong;
			running = false;
			if (errors.length == 0)
				setStatus('Done. Generated OGG vocals for $completed/${charts.length} charts.');
			else
				setStatus('Finished $completed/${charts.length}; ${errors.length} error(s). First: ${errors[0]}');
		});
	}

	static function collectDefaultCharts(directory:String, charts:Array<{song:SwagSong, chartName:String}>):Void
	{
		for (entry in FileSystem.readDirectory(directory))
		{
			var path = Path.join([directory, entry]);
			if (FileSystem.isDirectory(path))
			{
				collectDefaultCharts(path, charts);
				continue;
			}

			if (Path.extension(entry).toLowerCase() != "json")
				continue;

			var folder = Path.directory(path).substr("assets/data/".length);
			var chartName = Path.withoutExtension(entry);
			if (folder.toLowerCase() != chartName.toLowerCase())
				continue;

			var song = Song.loadFromJson(chartName, folder);
			if (song != null && song.notes != null && song.notes.length > 0)
				charts.push({song: song, chartName: folder + "/" + chartName});
		}
	}

	static function getSongLength(song:SwagSong):Float
	{
		var stepCrochet = ((60 / song.bpm) * 1000) / 4;
		var length:Float = 0;
		for (section in song.notes)
		{
			for (note in section.sectionNotes)
			{
				if (note[0] == null)
					continue;
				var sustain:Float = note.length > 6 && note[6] != null ? note[6] : (note.length > 2 && note[2] != null ? note[2] : 0);
				length = Math.max(length, note[0] + sustain + stepCrochet);
			}
		}
		return length;
	}

	static function getAudioName(song:SwagSong):String
	{
		var audioFolder = song.audioFolder != null && song.audioFolder.length > 0 ? song.audioFolder : song.song;
		audioFolder = audioFolder.replace("\\", "/");
		var name = Path.withoutDirectory(audioFolder);
		for (invalid in ["<", ">", ":", "\"", "/", "\\", "|", "?", "*"])
			name = name.replace(invalid, "_");
		return name;
	}

	static function createTempWavPath(chartName:String, target:String):String
	{
		var tempRoot = Sys.getEnv("TEMP");
		if (tempRoot == null || tempRoot.length == 0)
			tempRoot = Sys.getCwd();
		var directory = Path.join([tempRoot, "tnt-sf2-vocals"]);
		createDirectoryRecursive(directory);
		var safeName = chartName.replace("/", "_").replace("\\", "_");
		return Path.join([directory, safeName + "-" + target + ".wav"]);
	}

	static function encodeOgg(wavPath:String, oggPath:String):Void
	{
		var process:Process;
		try
		{
			process = new Process("ffmpeg", [
				"-hide_banner", "-loglevel", "error", "-y", "-i", wavPath,
				"-vn", "-c:a", "libvorbis", "-q:a", "5", oggPath
			]);
		}
		catch (error:Dynamic)
		{
			throw 'FFmpeg could not be started. Install FFmpeg and add it to PATH. $error';
		}

		var stderr = process.stderr.readAll().toString();
		var exitCode = process.exitCode();
		process.close();
		if (exitCode != 0)
			throw 'FFmpeg exited with code $exitCode: $stderr';
		if (!FileSystem.exists(oggPath) || FileSystem.stat(oggPath).size <= 0)
			throw "FFmpeg completed without creating an OGG file.";
	}

	static function createDirectoryRecursive(directory:String):Void
	{
		if (FileSystem.exists(directory))
			return;
		var parent = Path.directory(directory);
		if (parent != null && parent.length > 0 && parent != directory && !FileSystem.exists(parent))
			createDirectoryRecursive(parent);
		FileSystem.createDirectory(directory);
	}

	function setStatus(message:String):Void
	{
		statusLock.acquire();
		statusMessage = message;
		statusLock.release();
	}
}
