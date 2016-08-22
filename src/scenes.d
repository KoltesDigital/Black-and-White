module src.scenes;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.stdio : writeln;
import src.background;
import src.constants;
import src.input;
import src.models;
import src.particles;
import src.players;
import src.resources;
import src.shaders;
import std.math;
import src.sounds;
import std.random;

class Scene
{
	this()
	{
		resources = new ResourceSet(&loadComplete);
	}
	
	~this()
	{
		delete resources;
	}
	
	@property bool isLoaded()
	{
		return _loaded;
	}
	
	void update(float dt)
	{
		checkGlError(glClear(GL_COLOR_BUFFER_BIT));
	}
	
protected:
	void loadComplete()
	{
		_loaded = true;
	}
	
private:
	bool _loaded;
	ResourceSet resources;
}

class GameScene : Scene
{
	this()
	{
		background = resources.acquire!Background();
		particleSystem = resources.acquire!PlayerParticleSystem();
		thunderBuffer = resources.acquire!SoundBuffer("thunder.wav", (SoundBuffer buffer) {
			thunder.buffer = buffer;
		});
		thunder = new Sound();
	}
	
	~this()
	{
		delete thunder;
	}
	
	override @property bool isLoaded()
	{
		return super.isLoaded && arePlayersLoaded();
	}
	
	override void update(float dt)
	{
		float dx = 0;
		float dy = 0;
		
		if (input.isPressed(GLFW_KEY_RIGHT))
		{
			++dx;
		}
		
		if (input.isPressed(GLFW_KEY_LEFT))
		{
			--dx;
		}
		
		if (input.isPressed(GLFW_KEY_UP))
		{
			++dy;
		}
		
		if (input.isPressed(GLFW_KEY_DOWN))
		{
			--dy;
		}
		
		players[0].update(dt, dx, dy);
		
		dx = 0;
		dy = 0;
		
		if (input.isPressed(GLFW_KEY_D))
		{
			++dx;
		}
		
		if (input.isPressed(GLFW_KEY_A))
		{
			--dx;
		}
		
		if (input.isPressed(GLFW_KEY_W))
		{
			++dy;
		}
		
		if (input.isPressed(GLFW_KEY_S))
		{
			--dy;
		}
		
		players[1].update(dt, dx, dy);
		
		if (cooldown > 0)
			cooldown -= dt;
		
		dx = players[1].x - players[0].x;
		dy = players[1].y - players[0].y;
		float d2 = dx * dx + dy * dy;
		if (d2 <= PLAYER_COLLIDE * PLAYER_COLLIDE)
		{
			float d = sqrt(d2);
			dx /= d;
			dy /= d;
			players[0].sx -= dx * PLAYER_COLLIDE_SPEED;
			players[0].sy -= dy * PLAYER_COLLIDE_SPEED;
			players[1].sx += dx * PLAYER_COLLIDE_SPEED;
			players[1].sy += dy * PLAYER_COLLIDE_SPEED;
			if (cooldown <= 0)
			{
				thunder.setPosition((players[0].x + players[1].x) / 2, (players[0].y + players[1].y) / 2);
				thunder.volume = uniform(THUNDER_MIN_VOLUME, THUNDER_MAX_VOLUME);
				thunder.pitch = uniform(THUNDER_MIN_PITCH, THUNDER_MAX_PITCH);
				thunder.play();
				cooldown = THUNDER_COOLDOWN;
			}
		}
		
		background.edit();
		
		foreach (Player player; players)
			player.renderCenter();
		
		particleSystem.update(dt);
		
		background.save();
		
		foreach (Player player; players)
			player.renderCircle();
		
	}
	
private:
	Background background;
	PlayerParticleSystem particleSystem;
	SoundBuffer thunderBuffer;
	Sound thunder;
	float cooldown = 0;
}
