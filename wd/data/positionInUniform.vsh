#version 140

in vec2 uv;

out vec2 texCoord;
out vec3 color;

uniform vec4 position;
uniform vec2 resolution;

void main(void)
{
	gl_Position = vec4((uv * position.z + position.xy) / resolution, 0, 1);
	texCoord = uv;
	color = vec3(position.w);
}