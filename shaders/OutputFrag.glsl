#version 460

in vec2 TexCoords;
out vec4 FragColor;

layout(binding = 0) uniform sampler2D rayTraceTexture;
uniform float invSampleCounter;

const float gamma = 2.2;

vec4 ToneMap(in vec4 c, float limit)
{
	float luminance = 0.3 * c.x + 0.6 * c.y + 0.1 * c.z;

	return c * 1.0 / (1.0 + luminance / limit);
}

void main()
{
	vec4 result = texture(rayTraceTexture, TexCoords);
	result = ToneMap(result, 1.5);
	result = pow(result, vec4(1.0 / gamma));
	FragColor = vec4(result.xyz, 1.0);
}