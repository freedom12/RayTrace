#version 330

in vec2 TexCoords;
out vec4 color;

uniform sampler2D rayTraceTexture;

void main()
{
	color = texture(rayTraceTexture, TexCoords);
	color = pow(color, vec4(1.0/2.2));;
	color.a = 1.0;
}