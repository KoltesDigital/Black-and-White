module src.sounds;

import derelict.alure.functions;
import derelict.openal.functions;
import derelict.openal.types;
import src.constants;
import src.resources;
import std.stdio;

class SoundBuffer : FileResource
{
	alias checkAlError _;
	
	~this()
	{
		if (buffer)
			_(alDeleteBuffers(1, &buffer));
	}
	
	void load(Done done, const(ubyte[]) data)
	{
		_(buffer = alureCreateBufferFromMemory(cast(ubyte*)data.ptr, data.length));
		done(true);
	}
	
package:
	uint buffer;
}


class Sound
{
	alias checkAlError _;
	
	this()
	{
		_(alGenSources(1, &source));
		_(alSourcef(source, AL_REFERENCE_DISTANCE, 1));
		_(alSourcef(source, AL_MAX_DISTANCE, 10));
	}
	
	~this()
	{
		_(alDeleteSources(1, &source));
	}
	
	@property void buffer(SoundBuffer buffer)
	{
		_(alSourceQueueBuffers(source, 1, &buffer.buffer));
	}
	
	@property void looping(bool looping)
	{
		_(alSourcei(source, AL_LOOPING, looping));
	}
	
	@property void pitch(float pitch)
	{
		_(alSourcef(source, AL_PITCH, pitch));
	}
	
	void play()
	{
		_(alSourcePlay(source));
	}
	
	void setPosition(float x, float y)
	{
		_(alSource3f(source, AL_POSITION, x / SCREEN_HALF_WIDTH, 0, -(y + SCREEN_HALF_HEIGHT) / cast(float)SCREEN_HEIGHT));
	}
	
	@property void volume(float v)
	{
		_(alSourcef(source, AL_GAIN, v));
		_volume = v;
	}
	
	@property float volume()
	{
		return _volume;
	}
	
private:
	uint source;
	float _volume = 1;
}

