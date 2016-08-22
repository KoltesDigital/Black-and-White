module src.constants;

import derelict.openal.functions;
import derelict.opengl3.functions;
import std.array;
import std.conv;
import std.format;
import src.variables;

immutable
{
	/// Asset path.
	string dataPath = "data/";
	
	int SCREEN_WIDTH = 1920;
	int SCREEN_HEIGHT = 1080;
	
	int SCREEN_HALF_WIDTH = SCREEN_WIDTH / 2;
	int SCREEN_HALF_HEIGHT = SCREEN_HEIGHT / 2;
	
	debug
	{
		int WINDOW_WIDTH = SCREEN_WIDTH / 2;
		int WINDOW_HEIGHT = SCREEN_HEIGHT / 2;
	}
	else
	{
		int WINDOW_WIDTH = SCREEN_WIDTH;
		int WINDOW_HEIGHT = SCREEN_HEIGHT;
	}
	
	int PARTICLE_COUNT = 256;
	float PARTICLE_SIZE_THRESHOLD = 0.1;
}

version(all)
{
	float ACCELERATION = 5000f;
	float DAMPING = 5f;
	
	float spawnTimeMin = 0.002, spawnTimeMax = 0.004;
	
	float particleDAngleMin = -10, particleDAngleMax = 10;
	float particleDDAngleMin = -1, particleDDAngleMax = 1;
	float particleSizeMin = 10, particleSizeMax = 12;
	float particleDSizeMin = -270, particleDSizeMax = -250;
	float particleDDSizeMin = 0, particleDDSizeMax = 100;
	float particleSpeedMin = 1500, particleSpeedMax = 2000;
	float particleDSpeedMin = -100, particleDSpeedMax = 100;
	
	float PLAYER_CENTER_RADIUS = 25;
	float PLAYER_CIRCLE_RADIUS = 25;
	float PLAYER_CIRCLE_SMALL_MIN_RADIUS = 0.6;
	float PLAYER_CIRCLE_SMALL_MAX_RADIUS = 0.65;
	float PLAYER_CIRCLE_BIG_MIN_RADIUS = 0.75;
	float PLAYER_CIRCLE_BIG_MAX_RADIUS = 0.8;
	float PLAYER_CIRCLE_GROWTH = 0.2;
	
	float PLAYER_COLLIDE = 50;
	float PLAYER_COLLIDE_SPEED = 500;
	
	float THUNDER_MIN_VOLUME = 0.8;
	float THUNDER_MAX_VOLUME = 1;
	float THUNDER_MIN_PITCH = 0.5;
	float THUNDER_MAX_PITCH = 2;
	float THUNDER_COOLDOWN = 1;
}

debug
{
	VariableSet variableSet;
	
	void initVariables()
	{
		variableSet = new VariableSet([
			cast(Variable) new FloatRange("particleDAngle", &particleDAngleMin, &particleDAngleMax, 1),
			cast(Variable) new FloatRange("particleDDAngle", &particleDDAngleMin, &particleDDAngleMax, 1),
			cast(Variable) new FloatRange("particleSize", &particleSizeMin, &particleSizeMax, 10),
			cast(Variable) new FloatRange("particleDSize", &particleDSizeMin, &particleDSizeMax, 10),
			cast(Variable) new FloatRange("particleDDSize", &particleDDSizeMin, &particleDDSizeMax, 10),
			cast(Variable) new FloatRange("particleSpeed", &particleSpeedMin, &particleSpeedMax, 100),
			cast(Variable) new FloatRange("particleDSpeed", &particleDSpeedMin, &particleDSpeedMax, 100),
			cast(Variable) new FloatRange("spawnTime", &spawnTimeMin, &spawnTimeMax, 0.01),
			cast(Variable) new FloatVariable("acceleration", &ACCELERATION, 1000),
			cast(Variable) new FloatVariable("damping", &DAMPING, 10)
		]);
	}
}

void checkAlError(lazy void exp)
{
	exp();
	debug (checkALError)
	{
		auto err = alGetError();
		if (err)
		{
			auto writer = appender!string();
			formattedWrite(writer, "OpenAL error 0x%X", err);
			throw new Exception(writer.data);
		}
	}
}

void checkGlError(lazy void exp)
{
	exp();
	debug (checkGLError)
	{
		auto err = glGetError();
		if (err)
		{
			auto writer = appender!string();
			formattedWrite(writer, "OpenGL error 0x%X", err);
			throw new Exception(writer.data);
		}
	}
}
