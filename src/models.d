module src.models;

import derelict.opengl3.gl3;
import src.constants;
import src.resources;

class ScreenQuad : HardcodedResource
{
	alias checkGlError _;
	
	void load(Done done)
	{
		// Triangle configuration
		immutable float[6] vertices = [
			-1, -1,
			3, -1,
			-1, 3
		];
		
		immutable float[6] uvs = [
			0, 0,
			2, 0,
			0, 2
		];
		
		immutable uint positionAttribute = 0;
		immutable uint uvAttribute = 1;
		
		_(glGenVertexArrays(1, &va));
		_(glBindVertexArray(va));
		
		_(glGenBuffers(1, &positionVb));
		_(glBindBuffer(GL_ARRAY_BUFFER, positionVb));
		_(glBufferData(GL_ARRAY_BUFFER, vertices.length * float.sizeof, vertices.ptr, GL_STATIC_DRAW));
		_(glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, GL_FALSE, 0, null));
		_(glEnableVertexAttribArray(positionAttribute));
		
		_(glGenBuffers(1, &uvVB));
		_(glBindBuffer(GL_ARRAY_BUFFER, uvVB));
		_(glBufferData(GL_ARRAY_BUFFER, uvs.length * float.sizeof, uvs.ptr, GL_STATIC_DRAW));
		_(glVertexAttribPointer(uvAttribute, 2, GL_FLOAT, GL_FALSE, 0, null));
		_(glEnableVertexAttribArray(uvAttribute));
		
		done(true);
	}
	
	void render()
	{
		_(glBindVertexArray(va));
		_(glDrawArrays(GL_TRIANGLES, 0, 3));
	}
	
private:
	uint va, positionVb, uvVB;
}

class SquareQuad : HardcodedResource
{
	alias checkGlError _;
	
	void load(Done done)
	{
		immutable float[8] uvs = [
			-1, -1,
			1, -1,
			-1, 1,
			1, 1
		];
		
		immutable uint uvAttribute = 0;
		
		_(glGenVertexArrays(1, &va));
		_(glBindVertexArray(va));
		
		_(glGenBuffers(1, &uvVb));
		_(glBindBuffer(GL_ARRAY_BUFFER, uvVb));
		_(glBufferData(GL_ARRAY_BUFFER, uvs.length * float.sizeof, uvs.ptr, GL_STATIC_DRAW));
		_(glVertexAttribPointer(uvAttribute, 2, GL_FLOAT, GL_FALSE, 0, null));
		_(glEnableVertexAttribArray(uvAttribute));
		
		done(true);
	}
	
	void render()
	{
		_(glBindVertexArray(va));
		_(glDrawArrays(GL_TRIANGLE_STRIP, 0, 4));
	}
	
	void renderInstanced(int n)
	{
		_(glBindVertexArray(va));
		_(glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, n));
	}
	
private:
	uint va, uvVb;
}
