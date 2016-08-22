#version 140

in vec2 texCoord;
in vec3 color;

out vec4 fragColor;

void main()
{
	float dist2 = texCoord.s * texCoord.s + texCoord.t * texCoord.t;
	if (dist2 > 1)
		discard;
	fragColor = vec4(color, 1);
}