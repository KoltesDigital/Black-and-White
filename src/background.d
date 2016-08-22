module src.background;

import derelict.devil.ilut;
import derelict.opengl3.gl3;
import src.constants;
import src.models;
import src.resources;
import src.shaders;
import std.string;
import std.stdio;

class Background : HardcodedResource
{
	~this()
	{
		delete resources;
	}
	
	void load(Done done)
	{
		alias checkGlError _;
		
		resources = new ResourceSet(() {
			uint initialTexture = ilutGLLoadImage(cast(char*)toStringz(dataPath ~ "bg.png"));
			assert(initialTexture >= 0);
			glGetError(); // ilutGLLoadImage behaves badly
			
			bind();
			shader.use();
			_(glActiveTexture(GL_TEXTURE0));
			_(glBindTexture(GL_TEXTURE_2D, initialTexture));
			quad.render();
			step = 1 - step;
			
			done(true);
		});
		quad = resources.acquire!ScreenQuad();
		shader = resources.acquire!ShaderProgram("background.shp");
		
		// Empty texture to render the first pass into
		_(glGenTextures(2, renderTextures.ptr));
		
		foreach (uint texture; renderTextures)
		{
			_(glBindTexture(GL_TEXTURE_2D, texture));
			
			_(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
			_(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
			_(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST));
			_(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST));
			
			_(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, SCREEN_WIDTH, SCREEN_HEIGHT, 0, GL_RGB, GL_UNSIGNED_BYTE, null));
		}
		
		// The shaders just output a color
		immutable GLenum buffers[1] = [GL_COLOR_ATTACHMENT0];
		
		// Framebuffer for the first pass
		_(glGenFramebuffers(2, framebuffers.ptr));
		
		foreach (int i, uint framebuffer; framebuffers)
		{
			_(glBindFramebuffer(GL_FRAMEBUFFER, framebuffer));
			_(glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, renderTextures[i], 0));
			_(glDrawBuffers(buffers.length, buffers.ptr));
			
			if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
				throw new Exception("Framebuffer not complete.");
		}
		
		_(glBindFramebuffer(GL_FRAMEBUFFER, 0));
	}
	
	void edit()
	{
		bind();
		render();
	}
	
	void save()
	{
		alias checkGlError _;
		
		_(glBindFramebuffer(GL_FRAMEBUFFER, 0));
		_(glViewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT));
		
		step = 1 - step;
		render();
	}
	
private:
	ResourceSet resources;
	ScreenQuad quad;
	ShaderProgram shader;
	
	uint[2] renderTextures;
	uint[2] framebuffers;
	int step = 0;
	
	void bind()
	{
		alias checkGlError _;
		
		_(glBindFramebuffer(GL_FRAMEBUFFER, framebuffers[step]));
		_(glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT));
	}
	
	void render()
	{
		alias checkGlError _;
		
		_(glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT));
		
		shader.use();
		
		_(glActiveTexture(GL_TEXTURE0));
		_(glBindTexture(GL_TEXTURE_2D, renderTextures[1 - step]));
		
		quad.render();
	}
	
}