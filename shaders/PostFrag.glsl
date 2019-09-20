#version 460

in vec2 TexCoords;
out vec4 color;


layout(binding = 0) uniform sampler2D outputTexture;
layout(binding = 1) uniform sampler2D bloomTexture;

float weight[5] = float[] (0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);
const float gamma = 2.2;

vec3 ToneMap(vec3 c, float limit)
{
	float luminance = dot(c, vec3(0.2126, 0.7152, 0.0722));
	return c * 1.0/(1.0 + luminance/limit);
}

void main()
{
	
	vec2 tex_offset = 1.0 / textureSize(bloomTexture, 0); // gets size of single texel
    vec3 result = texture(bloomTexture, TexCoords).rgb * weight[0]; // current fragment's contribution
    for(int i = 1; i < 5; ++i)
    {
        result += texture(bloomTexture, TexCoords + vec2(tex_offset.x * i, 0.0)).rgb * weight[i];
        result += texture(bloomTexture, TexCoords - vec2(tex_offset.x * i, 0.0)).rgb * weight[i];
    }
   for(int i = 1; i < 5; ++i)
    {
        result += texture(bloomTexture, TexCoords + vec2(0.0, tex_offset.y * i)).rgb * weight[i];
        result += texture(bloomTexture, TexCoords - vec2(0.0, tex_offset.y * i)).rgb * weight[i];
    }
	
	
    vec3 hdrColor = texture(outputTexture, TexCoords).rgb;      
    result += hdrColor; // additive blending
    result = ToneMap(result, 1.5);
    result = pow(result, vec3(1.0 / gamma));

    color = vec4(result, 1.0f);
}