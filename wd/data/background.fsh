#version 140

in vec2 texCoord;
in vec2 fragCoord;

out vec4 fragColor;

uniform sampler2D texture;

void main()
{
	fragColor = texture2D(texture, texCoord);
}