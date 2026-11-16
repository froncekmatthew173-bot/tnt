package;

import flixel.system.FlxAssets.FlxShader;

class Shaggy3DShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform float uTime;
		uniform float uSpeed;
		uniform float uFrequency;
		uniform float uWaveAmplitude;

		vec2 sineWave(vec2 pt)
		{
			float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / max(abs(pt.x), 0.05) * pt.y);
			float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / max(abs(pt.y), 0.05) * pt.x);
			return pt + vec2(offsetX, offsetY);
		}

		void main()
		{
			gl_FragColor = texture2D(bitmap, sineWave(openfl_TextureCoordv));
		}')
	public function new()
	{
		super();
		uTime.value = [0];
		uSpeed.value = [2];
		uFrequency.value = [5];
		uWaveAmplitude.value = [0.1];
	}

	public function update(elapsed:Float):Void
	{
		uTime.value[0] += elapsed;
	}
}
