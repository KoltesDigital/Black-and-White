#version 140

in vec2 texCoord;
in vec3 color;

out vec4 fragColor;

const float edgeMin = 0.2;
const float edgeMax = 0.8;

void main()
{
	float dist2 = texCoord.s * texCoord.s + texCoord.t * texCoord.t;
	float alpha = 1 - smoothstep(edgeMin, edgeMax, sqrt(dist2));
	fragColor = vec4(color, alpha);
}