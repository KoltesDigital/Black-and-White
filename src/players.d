module src.players;

import derelict.glfw3.glfw3;
import derelict.opengl3.functions;
import src.constants;
import src.joystick;
import src.particles;
import src.resources;
import src.shaders;
import std.random;
import std.math;
import std.stdio : writeln;
import src.models;
import src.sounds;

class Player
{
	alias checkGlError _;
	
public:
	float x;
	float y;
	
	float sx;
	float sy;
	
	bool loaded = false;
	
	this(int id)
	{
		resources = new ResourceSet(() {
			loaded = true;
		});
		particleSystem = resources.acquire!PlayerParticleSystem();
		playerCenterShader = resources.acquire!ShaderProgram("playerCenter.shp", (ShaderProgram shader) {
			shader.use();
			_(glUniform2f(shader["resolution"], SCREEN_HALF_WIDTH, SCREEN_HALF_HEIGHT));
		});
		playerCircleShader = resources.acquire!ShaderProgram("playerCircle.shp", (ShaderProgram shader) {
			shader.use();
			_(glUniform2f(shader["resolution"], SCREEN_HALF_WIDTH, SCREEN_HALF_HEIGHT));
		});
		quad = resources.acquire!SquareQuad();
		
		sound = new Sound();
		sound.looping = true;
		sound.volume = 0;
		
		joystick = new Joystick();
		string soundFile;
		
		switch (id)
		{
			case 0:
				joystick.id = GLFW_JOYSTICK_1;
				grayscale = 1;
				x = -300;
				y = 0;
				soundFile = "wind.wav";
				break;
				
			case 1:
				joystick.id = GLFW_JOYSTICK_2;
				grayscale = 0;
				x = 300;
				y = 0;
				soundFile = "electric.wav";
				break;
				
			default:
				assert(0, "Player id unknown");
				break;
		}
		
		soundBuffer = resources.acquire!SoundBuffer(soundFile, (SoundBuffer buffer) {
			sound.buffer = buffer;
			sound.play();
		});
		
		sx = 0;
		sy = 0;
		
		circleRadius = uniform(PLAYER_CIRCLE_SMALL_MIN_RADIUS, PLAYER_CIRCLE_SMALL_MAX_RADIUS);
		circleRadiusTarget = uniform(PLAYER_CIRCLE_BIG_MIN_RADIUS, PLAYER_CIRCLE_BIG_MAX_RADIUS);
		circleGrowth = PLAYER_CIRCLE_GROWTH;
		
		particleTimer = 0;
		nextSpawnTime = 0;
	}
	
	~this()
	{
		delete sound;
		delete resources;
	}
	
	void update(float dt, float dx, float dy)
	{
		joystick.update();
		
		if (joystick.id)
		{
			dx -= joystick.axis(0);
			dy -= joystick.axis(1);
		}
		else
		{
			dx += joystick.axis(0);
			dy += joystick.axis(1);
		}
		
		float d = sqrt(dx * dx + dy * dy);
		if (d > 1)
		{
			dx /= d;
			dy /= d;
			d = 1;
		}
		sound.volume = sound.volume + (0.05 + 0.2 * d - sound.volume) * (1 - exp(-0.5 * dt));
		//writeln(sound.volume);
		
		float previousSx = sx;
		float previousSy = sy;
		
		float acceleration = dt * ACCELERATION;
		float damping = exp(- dt * DAMPING);
		
		sx = (sx + dx * acceleration) * damping;
		sy = (sy + dy * acceleration) * damping;
		
		x += (sx + previousSx) / 2 * dt;
		y += (sy + previousSy) / 2 * dt;
		
		if (x < -SCREEN_HALF_WIDTH)
			x = -SCREEN_HALF_WIDTH;
		else if (x > SCREEN_HALF_WIDTH)
			x = SCREEN_HALF_WIDTH;
		
		if (y < -SCREEN_HALF_HEIGHT)
			y = -SCREEN_HALF_HEIGHT;
		else if (y > SCREEN_HALF_HEIGHT)
			y = SCREEN_HALF_HEIGHT;
		
		sound.setPosition(x, y);
		
		particleTimer += dt;
		while (particleTimer >= nextSpawnTime)
		{
			particleTimer -= nextSpawnTime;
			nextSpawnTime = uniform(spawnTimeMin, spawnTimeMax);
			
			particleSystem.emit(x, y, grayscale);
		}
		
		circleRadius += circleGrowth * dt;
		if (circleGrowth > 0 && circleRadius >= circleRadiusTarget)
		{
			circleRadiusTarget = uniform(PLAYER_CIRCLE_SMALL_MIN_RADIUS, PLAYER_CIRCLE_SMALL_MAX_RADIUS);
			circleGrowth = -PLAYER_CIRCLE_GROWTH;
		}
		else if (circleGrowth < 0 && circleRadius <= circleRadiusTarget)
		{
			circleRadiusTarget = uniform(PLAYER_CIRCLE_BIG_MIN_RADIUS, PLAYER_CIRCLE_BIG_MAX_RADIUS);
			circleGrowth = PLAYER_CIRCLE_GROWTH;
		}
	}
	
	void renderCenter()
	{
		playerCenterShader.use();
		_(glUniform4f(playerCenterShader["position"], x, y, PLAYER_CENTER_RADIUS, grayscale));
		quad.render();
	}
	
	void renderCircle()
	{
		playerCircleShader.use();
		_(glUniform4f(playerCircleShader["position"], x, y, PLAYER_CIRCLE_RADIUS, 1 - grayscale));
		_(glUniform1f(playerCircleShader["radius"], circleRadius));
		quad.render();
	}
	
	void swapJoystick()
	{
		joystick.id = 1 - joystick.id;
	}
	
private:
	ResourceSet resources;
	PlayerParticleSystem particleSystem;
	ShaderProgram playerCenterShader;
	ShaderProgram playerCircleShader;
	SquareQuad quad;
	SoundBuffer soundBuffer;
	Sound sound;
	
	float grayscale;
	
	float circleRadius;
	float circleGrowth;
	float circleRadiusTarget;
	
	float particleTimer;
	float nextSpawnTime;
	
	Joystick joystick;
}

Player[2] players;

void createPlayers()
{
	players[0] = new Player(0);
	players[1] = new Player(1);
}

bool arePlayersLoaded()
{
	return players[0].loaded && players[1].loaded;
}

void deletePlayers()
{
	delete players[0];
	delete players[1];
}
