module src.shaders;

import derelict.opengl3.gl3;
import src.constants;
import src.resources;
import std.conv;
import std.file;
import std.stdio;
import std.json;
import std.container;
import std.string;

class Shader : FileResource
{
	alias checkGlError _;
	
	this()
	{
		_id = 0;
	}
	
	~this()
	{
		if (_id)
			_(glDeleteShader(_id));
	}
	
	void load(Done done, const(ubyte[]) data)
	{
		_(_id = glCreateShader(shaderType));
		
		const(char*)[1] sources = [cast(char*)data.ptr];
		const(int)[1] lengths = [data.length];
		
		_(glShaderSource(_id, 1, sources.ptr, lengths.ptr));
		
		_(glCompileShader(_id));
		
		int compileStatus;
		glGetShaderiv(_id, GL_COMPILE_STATUS, &compileStatus);
		if (compileStatus == GL_FALSE)
		{
			char[256] infoBuffer;
			int infoLength;
			
			glGetShaderInfoLog(_id, infoBuffer.length, &infoLength, infoBuffer.ptr);
			if (infoLength > 0)
				writeln(to!string(infoBuffer.ptr));
			
			throw new Exception("Shader compilation failed");
			done(false);
		}
		
		done(true);
	}
	
	@property GLuint id()
	{
		return _id;
	}
	
private:
	GLuint _id;
	GLenum shaderType;
}

class VertexShader : Shader
{
	this()
	{
		shaderType = GL_VERTEX_SHADER;
	}
}

class FragmentShader : Shader
{
	this()
	{
		shaderType = GL_FRAGMENT_SHADER;
	}
}

class ShaderProgram : FileResource
{
	alias checkGlError _;
	
	this()
	{
		_(id = glCreateProgram());
	}
	
	~this()
	{
		_(glDeleteProgram(id));
	}
	
	void load(Done done, const(ubyte[]) data)
	{
		Shader[] shaders;
		
		ResourceSet resources;
		resources = new ResourceSet({
			foreach (shader; shaders)
				_(glAttachShader(id, shader.id));
			
			_(glLinkProgram(id));
			
			foreach (shader; shaders)
				_(glDetachShader(id, shader.id));
			
			delete resources;
			
			int linkStatus;
			_(glGetProgramiv(id, GL_LINK_STATUS, &linkStatus));
			if (linkStatus == GL_FALSE)
			{
				char[256] infoBuffer;
				int infoLength;
				
				_(glGetProgramInfoLog(id, infoBuffer.length, &infoLength, infoBuffer.ptr));
				if (infoLength > 0) {
					writeln(to!string(infoBuffer.ptr));
				}
				
				throw new Exception("Program linking failed");
			}
			
			int total;
			_(glGetProgramiv(id, GL_ACTIVE_UNIFORMS, &total));
			for (int i = 0; i < total; ++i)
			{
				int length;
				int size;
				GLenum type;
				char[64] buffer;
				GLint location;
				_(glGetActiveUniform(id, i, buffer.length, &length, &size, &type, buffer.ptr));
				string name = buffer[0 .. length].idup;
				_(locations[name] = location = glGetUniformLocation(id, buffer.ptr));
			}
			
			done(true);
		});
		
		JSONValue root = parseJSON(data);
		assert(root.type == JSON_TYPE.OBJECT);
		
		assert(root["shaders"].type == JSON_TYPE.ARRAY);
		foreach (value; root["shaders"].array)
		{
			assert(value.type == JSON_TYPE.STRING);
			uint type;
			switch (value.str[$ - 3 .. $])
			{
				case "vsh":
					shaders ~= resources.acquire!VertexShader(value.str);
					break;
				case "fsh":
					shaders ~= resources.acquire!FragmentShader(value.str);
					break;
				default:
					throw new Exception("Shader type unknown: " ~ value.str);
			}
		}
		
		if ("attributes" in root.object)
		{
			assert(root["attributes"].type == JSON_TYPE.OBJECT);
			foreach (string attribute, JSONValue value; root["attributes"].object)
			{
				assert(value.type == JSON_TYPE.INTEGER || value.type == JSON_TYPE.UINTEGER);
				uint location;
				switch (value.type)
				{
					case JSON_TYPE.INTEGER:
						location = cast(uint)value.integer;
						break;
					case JSON_TYPE.UINTEGER:
						location = cast(uint)value.uinteger;
						break;
					default:
						throw new Exception("Bad location for attribute " ~ attribute);
				}
				_(glBindAttribLocation(id, location, toStringz(attribute)));
			}
			
		}
	}
	
	void use()
	{
		glUseProgram(id);
		assert(!glGetError());
	}
	
	static void useDefault()
	{
		glUseProgram(0);
		assert(!glGetError());
	}
	
	GLint opIndex(string uniform)
	{
		GLint* location = uniform in locations;
		if (location)
			return *location;
		return -1;
	}
	
private:
	GLuint id;
	GLint[string] locations;
}