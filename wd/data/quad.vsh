#version 140

in vec2 position;
in vec2 uv;

out vec2 texCoord;
out vec2 fragCoord;

uniform vec2 resolution;

void main(void)
{
	gl_Position = vec4(position, 0, 1);
	texCoord = uv;
	fragCoord = uv * resolution;
}