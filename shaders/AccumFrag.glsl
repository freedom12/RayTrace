#version 460

in vec2 TexCoords;
out vec4 color;

layout(binding = 0) uniform sampler2D rayTraceTexture;

void main()
{
	color = texture(rayTraceTexture, TexCoords);
}