module src.particles;

import derelict.opengl3.gl3;
import src.constants;
import src.resources;
import src.shaders;
import std.algorithm;
import std.math;
import std.random;
import std.stdio;
import src.models;

class PlayerParticleSystem : HardcodedResource
{
	alias checkGlError _;
	
	struct Particle
	{
		float x;
		float y;
		float size = 0;
		float grayscale;
	}
	
	struct ParticleSpeed
	{
		float speed = 0;
		float dspeed = 0;
		float angle = 0;
		float dangle = 0;
		float ddangle = 0;
		float dsize = 0;
		float ddsize = 0;
	}
	
	Particle[PARTICLE_COUNT] particles;
	ParticleSpeed[PARTICLE_COUNT] particleSpeeds;
	
	uint particleVA, particleVB;
	uint particleB, particleBT;
	
	~this()
	{
		delete resources;
	}
	
	void load(Done done)
	{
		resources = new ResourceSet({
			done(true);
		});
		particleShader = resources.acquire!ShaderProgram("particle.shp", (ShaderProgram shader) {
			shader.use();
			_(glUniform2f(shader["resolution"], SCREEN_HALF_WIDTH, SCREEN_HALF_HEIGHT));
		});
		quad = resources.acquire!SquareQuad();
		
		_(glGenBuffers(1, &particleB));
		_(glGenTextures(1, &particleBT));
	}
	
	void emit(float x, float y, float grayscale)
	{
		for (int i = 0; i < PARTICLE_COUNT; ++i)
		{
			if (particles[i].size < PARTICLE_SIZE_THRESHOLD)
			{
				float angle = uniform(-PI, PI);
				
				particles[i].x = x + cos(angle) * PLAYER_CENTER_RADIUS;
				particles[i].y = y + sin(angle) * PLAYER_CENTER_RADIUS;
				particles[i].size = uniform(particleSizeMin, particleSizeMax);
				particles[i].grayscale = grayscale;
				
				particleSpeeds[i].angle = angle;
				particleSpeeds[i].dangle = uniform(particleDAngleMin, particleDAngleMax);
				particleSpeeds[i].ddangle = uniform(particleDDAngleMin, particleDDAngleMax);
				particleSpeeds[i].dsize = uniform(particleDSizeMin, particleDSizeMax);
				particleSpeeds[i].ddsize = uniform(particleDDSizeMin, particleDDSizeMax);
				particleSpeeds[i].speed = uniform(particleSpeedMin, particleSpeedMax);
				particleSpeeds[i].dspeed = uniform(particleDSpeedMin, particleDSpeedMax);
				return;
			}
		}
	}
	
	void update(float dt)
	{
		configureParticleRendering();
		
		while (dt > 0)
		{
			float interval = min(dt, 0.0001);
			dt -= interval;
			updateParticles(interval);
			renderParticles();
		}
		
	}
	
	void configureParticleRendering()
	{
		particleShader.use();
		_(glBindBuffer(GL_ARRAY_BUFFER, particleB));
	}
	
	void updateParticles(float dt)
	{
		for (int i = 0; i < PARTICLE_COUNT; ++i)
		{
			if (particles[i].size >= PARTICLE_SIZE_THRESHOLD)
			{
				particleSpeeds[i].speed += particleSpeeds[i].dspeed * dt / 2;
				particleSpeeds[i].dangle += particleSpeeds[i].ddangle * dt / 2;
				particleSpeeds[i].dsize += particleSpeeds[i].ddsize * dt / 2;
				
				particleSpeeds[i].angle += particleSpeeds[i].dangle * dt;
				particles[i].x += particleSpeeds[i].speed * cos(particleSpeeds[i].angle) * dt;
				particles[i].y += particleSpeeds[i].speed * sin(particleSpeeds[i].angle) * dt;
				particles[i].size += particleSpeeds[i].dsize * dt;
				
				particleSpeeds[i].speed += particleSpeeds[i].dspeed * dt / 2;
				particleSpeeds[i].dangle += particleSpeeds[i].ddangle * dt / 2;
				particleSpeeds[i].dsize += particleSpeeds[i].ddsize * dt / 2;
			}
		}
	}
	
	void renderParticles()
	{
		_(glBufferData(GL_ARRAY_BUFFER, PARTICLE_COUNT * Particle.sizeof, particles.ptr, GL_DYNAMIC_DRAW));
		
		_(glActiveTexture(GL_TEXTURE0));
		_(glBindTexture(GL_TEXTURE_BUFFER, particleBT));
		_(glTexBuffer(GL_TEXTURE_BUFFER, GL_RGBA32F, particleB));
		
		quad.renderInstanced(PARTICLE_COUNT);
	}
	
private:
	ResourceSet resources;
	ShaderProgram particleShader;
	SquareQuad quad;
}
