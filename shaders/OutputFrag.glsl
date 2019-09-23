#version 460

in vec2 TexCoords;
layout (location = 0) out vec4 FragColor;
layout (location = 1) out vec4 BloomColor;
layout(binding = 0) uniform sampler2D rayTraceTexture;

const float gamma = 2.2;

vec4 ToneMap(in vec4 c, float limit)
{
	float luminance = 0.3 * c.x + 0.6 * c.y + 0.1 * c.z;

	return c * 1.0 / (1.0 + luminance / limit);
}

void main()
{
	vec4 result = texture(rayTraceTexture, TexCoords);
	float luminance = 0.3 * result.x + 0.6 * result.y + 0.1 * result.z;
	if(luminance > 10)
	{
		BloomColor = result;
	}
	else 
	{
		BloomColor = vec4(0, 0, 0, 1);
	}

	
	//result = ToneMap(result, 1.5);
	//result = pow(result, vec4(1.0 / gamma));
	FragColor = vec4(result.xyz, 1.0);
}