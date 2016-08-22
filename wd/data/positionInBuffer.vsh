#version 140
#extension GL_EXT_gpu_shader4 : enable

in vec2 uv;

out vec2 texCoord;
out vec3 color;

uniform samplerBuffer particles;
uniform vec2 resolution;

void main(void)
{
	vec4 particle = texelFetchBuffer(particles, gl_InstanceID);
	gl_Position = vec4((uv * particle.z + particle.xy) / resolution, 0, 1);
	texCoord = uv;
	color = vec3(particle.w);
}