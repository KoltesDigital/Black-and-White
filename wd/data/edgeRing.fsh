#version 140

in vec2 texCoord;
in vec3 color;

out vec4 fragColor;

uniform float radius;

const float widthMin = 0.05;
const float widthMax = 0.15;

void main()
{
	float dist = sqrt(texCoord.s * texCoord.s + texCoord.t * texCoord.t);
	float alpha = smoothstep(radius - widthMax, radius - widthMin, dist) - smoothstep(radius + widthMin, radius + widthMax, dist);
	fragColor = vec4(color, alpha);
}